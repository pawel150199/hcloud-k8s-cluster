# 2. Architecture

This page describes the architecture of the cluster the module builds, using
[Mermaid](https://mermaid.js.org/) diagrams. They render natively on GitHub and
are exported as vector graphics in the PDF build.

## 2.1 Component overview

At a high level the module creates a private network, a subnet, and a set of
servers. Terraform state is kept in AWS S3 (Hetzner has no native state backend).

```mermaid
flowchart TB
  subgraph AWS["AWS"]
    S3[("S3 bucket<br/>Terraform state")]
  end

  Dev["Operator<br/>terraform apply"] -->|reads/writes state| S3
  Dev -->|hcloud API| HET

  subgraph HET["Hetzner Cloud project"]
    direction TB
    NET["hcloud_network<br/>10.0.0.0/16"]
    SUB["hcloud_network_subnet<br/>10.0.1.0/24 · eu-central"]
    NET --- SUB

    subgraph CP["Control plane"]
      M0["master-node-0<br/>k3s server<br/>10.0.1.1"]
    end

    subgraph WK["Workers"]
      W0["worker-node-0<br/>k3s agent"]
      W1["worker-node-1<br/>k3s agent"]
    end

    SUB --- M0
    SUB --- W0
    SUB --- W1
    W0 -.join :6443.-> M0
    W1 -.join :6443.-> M0
  end

  classDef master fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20;
  classDef worker fill:#e3f2fd,stroke:#1565c0,color:#0d47a1;
  class M0 master;
  class W0,W1 worker;
```

**Key points**

- Every node has an interface on the **private subnet** (`10.0.1.0/24`). The
  master pins itself to `10.0.1.1` (`master_node_ip`); workers get automatic
  private IPs.
- Nodes may also have **public IPv4/IPv6** (toggled by `node_enable_ipv4` /
  `node_enable_ipv6`) — used for outbound package downloads and, on the master,
  for fetching the kubeconfig.
- Workers reach the control plane at **`https://10.0.1.1:6443`** over the private
  network.

## 2.2 Network topology

```mermaid
flowchart LR
  subgraph PUB["Public internet"]
    INET(("Internet"))
  end

  subgraph HNET["hcloud_network 10.0.0.0/16"]
    subgraph SUBNET["subnet 10.0.1.0/24"]
      M["master-node-0<br/>priv 10.0.1.1<br/>pub IPv4/IPv6"]
      W0["worker-node-0<br/>priv 10.0.1.x"]
      W1["worker-node-1<br/>priv 10.0.1.x"]
    end
  end

  INET <-->|apt, get.k3s.io| M
  INET <-->|apt, get.k3s.io| W0
  INET <-->|apt, get.k3s.io| W1
  M <===>|k8s API 6443 / SSH 22<br/>private| W0
  M <===>|k8s API 6443 / SSH 22<br/>private| W1
```

| Segment | CIDR | Notes |
| --- | --- | --- |
| Network | `10.0.0.0/16` | `private_network_ip_range` |
| Subnet | `10.0.1.0/24` | `eu-central`, type `cloud` |
| Master private IP | `10.0.1.1` | `master_node_ip` (fixed) |
| Worker private IPs | `10.0.1.0/24` pool | Assigned by Hetzner |

## 2.3 Terraform resource graph

What Terraform actually manages, and the dependencies between resources:

```mermaid
flowchart TD
  V["input variables<br/>incl. ssh_public_key"] --> NET["hcloud_network<br/>private_network"]
  V --> AK["hcloud_ssh_key<br/>admin"]
  NET --> SUB["hcloud_network_subnet<br/>private_network_subnet"]
  TM["tls_private_key<br/>master_node"] --> M
  TW["tls_private_key<br/>worker_node"] --> M
  TM --> W
  TW --> W
  AK --> M
  AK --> W
  SUB --> M["hcloud_server<br/>master_nodes[count]"]
  SUB --> W["hcloud_server<br/>worker_nodes[count]"]
  M --> W
  NET --> O1["output:<br/>kubernetes_network_ip_range"]
  M --> O2["output:<br/>master_node_ip"]
  TM --> O3["outputs:<br/>master_node_ssh_*_key"]
  TW --> O4["outputs:<br/>worker_node_ssh_*_key"]

  classDef res fill:#fff3e0,stroke:#e65100,color:#bf360c;
  classDef out fill:#f3e5f5,stroke:#6a1b9a,color:#4a148c;
  class NET,SUB,M,W,AK,TM,TW res;
  class O1,O2,O3,O4 out;
```

`depends_on` wires the subnet before the servers, and the workers after the
master, so the control plane exists before any agent tries to join. The two
`tls_private_key` resources are created first — their material is rendered into
the servers' `user_data`.

## 2.4 Bootstrap sequence

The most important flow: how the cluster assembles itself from `apply` to a
Ready worker, driven entirely by cloud-init.

```mermaid
sequenceDiagram
  autonumber
  participant TF as Terraform
  participant HC as Hetzner API
  participant M as master-node-0
  participant W as worker-node-N

  TF->>HC: create network and subnet
  TF->>HC: create master server with user_data
  TF->>HC: create worker servers with user_data

  Note over M: first boot (cloud-init)
  M->>M: apt-get update and install curl
  M->>M: install k3s server<br/>disable traefik and cloud-controller
  M->>M: make kubeconfig and node-token<br/>readable by the cluster user
  Note over M: control plane Ready at port 6443

  Note over W: first boot (cloud-init)
  W->>M: poll https 10.0.1.1:6443 until ready
  M-->>W: API server responds
  W->>M: ssh with generated master key<br/>and read node-token
  M-->>W: k3s join token
  W->>W: install k3s agent<br/>joined to 10.0.1.1:6443
  W->>M: register node over private network
  Note over M,W: worker joins and node becomes Ready
```

### What each role runs

**Master (`master-node.tf`):**

```bash
curl https://get.k3s.io | \
  INSTALL_K3S_EXEC="--disable traefik --disable-cloud-controller \
    --kubelet-arg cloud-provider=external" sh -
# then make kubeconfig + node-token readable by the "cluster" user
```

**Worker (`worker-node.tf`):**

```bash
# 1. wait for the API server
until curl -k https://10.0.1.1:6443; do sleep 5; done
# 2. pull the join token from the master over SSH, using the module-generated
#    private key that cloud-init wrote to /root/.ssh/master_node_key
REMOTE_TOKEN=$(ssh -i /root/.ssh/master_node_key -o StrictHostKeyChecking=accept-new \
  cluster@10.0.1.1 sudo cat /var/lib/rancher/k3s/server/node-token)
# 3. install and join
curl -sfL https://get.k3s.io | \
  K3S_URL=https://10.0.1.1:6443 K3S_TOKEN=$REMOTE_TOKEN \
  INSTALL_K3S_EXEC="--kubelet-arg cloud-provider=external" sh -
```

> **Trust model.** Workers authenticate to the master over SSH to read the k3s
> node-token, then use that token to join the API server. The key pair that
> makes this possible is generated by the module — see below.

## 2.5 SSH key model

The module generates **two key pairs** with the `tls` provider and distributes
them through cloud-init. Nothing but your own public key comes from a variable,
and that one is optional: skip `ssh_public_key` and pass `ssh_keys` instead to
reuse keys that already exist in your Hetzner project. Those are looked up with
the `hcloud_ssh_keys` data source so their public key material can be authorised
for the `cluster` user too — `hcloud_server.ssh_keys` alone would install them on
`root` only. When neither input is set, `hcloud_ssh_key.admin` is not created and
the `cluster` user is reachable only with the module-generated key.

```mermaid
flowchart LR
  subgraph TF["Terraform (ssh.tf)"]
    PUB["var.ssh_public_key<br/>your machine"]
    KM["tls_private_key.master_node"]
    KW["tls_private_key.worker_node"]
    AK["hcloud_ssh_key.admin"]
  end

  subgraph M["master-node-N"]
    MR["root: authorized_keys"]
    MC["cluster: authorized_keys<br/>= you + master pub"]
    MF["/root/.ssh/worker_node_key<br/>= worker priv"]
  end

  subgraph W["worker-node-N"]
    WR["root: authorized_keys"]
    WC["cluster: authorized_keys<br/>= you + worker pub"]
    WF["/root/.ssh/master_node_key<br/>= master priv"]
  end

  PUB --> AK
  AK --> MR
  AK --> WR
  PUB --> MC
  PUB --> WC
  KM -->|public| MC
  KM -->|private| WF
  KW -->|public| WC
  KW -->|private| MF

  WF -.->|ssh cluster@10.0.1.1<br/>read node-token| MC
  MF -.->|ssh cluster@worker| WC
```

| Key | Generated by | Public key lands on | Private key lands on |
| --- | --- | --- | --- |
| Admin key | you (`ssh_public_key`, optional) | `root` + `cluster` on every node | your machine only |
| Master key | `tls_private_key.master_node` | `cluster` on the master | every worker, `/root/.ssh/master_node_key` |
| Worker key | `tls_private_key.worker_node` | `cluster` on the workers | the master, `/root/.ssh/worker_node_key` |

The master key pair is what closes the bootstrap loop: a worker uses it to SSH
into the master and read `/var/lib/rancher/k3s/server/node-token`. The worker
key pair is the reverse direction, so the master (and you, via the
`worker_node_ssh_private_key` output) can reach the workers.

> **Both private keys are stored in Terraform state.** Treat the state as a
> secret: keep it in an encrypted remote backend and restrict access. Rotating
> is a matter of tainting the key resource and re-applying, which replaces the
> servers.

Continue to [Getting started »](03-getting-started.md)
