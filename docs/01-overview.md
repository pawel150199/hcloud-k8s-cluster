# 1. Overview

## What this module does

`hcloud-k8s-cluster` is a Terraform module that stands up a **self-managed
Kubernetes cluster on Hetzner Cloud** using [k3s](https://k3s.io/) as the
Kubernetes distribution.

On `terraform apply` it creates:

- a **private Hetzner network** and a subnet that every node attaches to;
- one or more **master (server) nodes** that bootstrap a k3s control plane;
- a configurable number of **worker (agent) nodes** that automatically join the
  control plane over the private network;
- **firewalls** for both roles, and **placement groups** that spread the nodes
  over separate physical machines;
- an **API load balancer**, when the control plane is HA
  (`master_nodes_number` > 1);
- the **SSH key pair** the masters use to reach the workers, generated on the
  fly — the only key you hand the module is the public key of your own machine.

Nodes are provisioned entirely through **cloud-init** (`user_data`): k3s is
installed and configured on first boot, so no separate configuration-management
step or manual SSH is required for the cluster to come up.

## Design goals

1. **Infrastructure as code** — the whole cluster is described in Terraform.
2. **Automated Kubernetes setup** — the cluster bootstraps itself with no manual
   steps after `apply`.
3. **At least one master and one worker** — a minimal but real multi-node
   topology.
4. **GitOps-ready** — workloads are intended to be delivered to the cluster via
   GitOps (e.g. Argo CD / Flux) rather than `kubectl apply` by hand.
5. **Observability** — the cluster is intended to host a full monitoring stack.
6. **Scalable** — the number of worker (and master) nodes is parameterised.

## Why k3s

k3s is a lightweight, CNCF-certified Kubernetes distribution that installs from a
single script and runs well on small Hetzner instances (the default node type is
`cx23`, a shared-vCPU x86 machine; `cax*` ARM types work just as well). The
module deliberately disables components that don't fit this environment:

| Disabled | Why |
|----------|-----|
| `traefik` | Leave ingress choice to the user / GitOps stack |
| *(nothing else)* | The built-in cloud controller stays **enabled**. It is what populates `node.status.addresses`; without it, and without an external replacement, nodes come up with no `InternalIP` and k3s' network policy controller shuts the server down on every start |

Nodes deliberately run **without** `--kubelet-arg cloud-provider=external`. Add
that flag together with an external cloud-controller-manager, never on its own —
see [operations](06-operations.md#65-what-to-deploy-next).

> The module is a **starting point**. The project README notes it may later be
> extended to bootstrap Kubernetes with other tools (e.g. `kubeadm`).

## Scope

**In scope (what the module provisions):**

- Hetzner private network + subnet
- Master node(s) with a bootstrapped k3s server
- Worker node(s) that join the control plane automatically
- Per-role firewalls, placement groups, and the API load balancer of an HA
  control plane

**In scope, generated for you:**

- The SSH key pair the masters use to reach the workers, and the k3s join token
  every node shares — created by the module (`tls`, `random`), never passed in

**Out of scope (you provide these):**

- The Hetzner Cloud project, API token, and your own public SSH key
- Terraform remote state storage (the project uses **AWS S3** — Hetzner has no
  native state backend)
- An external cloud-controller-manager (needed for Hetzner load balancers and
  provider IDs), CNI extras, ingress, storage classes
- GitOps controllers and the monitoring stack (deployed *into* the cluster after
  it exists)

## Repository layout

```text
hcloud-k8s-cluster/
├── main.tf             # hcloud_network + subnet, placement groups, join token
├── ssh.tf              # generated node key pair + uploaded admin key
├── firewall.tf         # per-role firewall rules
├── load-balancer.tf    # API load balancer (HA control plane only)
├── master-node.tf      # hcloud_server master node(s)
├── worker-node.tf      # hcloud_server worker node(s)
├── variables.tf        # input variables
├── outputs.tf          # module outputs
├── versions.tf         # required Terraform + provider versions
├── templates/          # cloud-init document and the bootstrap scripts it ships
│   ├── cloud-config.yaml.tftpl    # shared by both roles
│   ├── k3s-common.sh              # shell helpers both bootstraps source
│   ├── bootstrap-master.sh.tftpl  # k3s server bootstrap
│   └── bootstrap-worker.sh.tftpl  # k3s agent bootstrap
├── examples/
│   └── basic/          # runnable usage example
└── docs/               # this documentation
```

Continue to [Architecture »](02-architecture.md)
