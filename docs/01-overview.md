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
- the **SSH key pairs** used between the nodes, generated on the fly — the only
  key you hand the module is the public key of your own machine.

Nodes are provisioned entirely through **cloud-init** (`user_data`): k3s is
installed and configured on first boot, so no separate configuration-management
step or manual SSH is required for the cluster to come up.

## Design goals

These goals come from the project's top-level `README.md`:

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
single script and runs well on small ARM/x86 Hetzner instances (the default node
type is `cax11`, a shared-vCPU ARM64 machine). The module deliberately disables
components that don't fit this environment:

| Disabled | Why |
|----------|-----|
| `traefik` | Leave ingress choice to the user / GitOps stack |
| `cloud-controller` (built-in) | Replaced by an external cloud controller; nodes run with `--kubelet-arg cloud-provider=external` |

> The module is a **starting point**. The project README notes it may later be
> extended to bootstrap Kubernetes with other tools (e.g. `kubeadm`).

## Scope

**In scope (what the module provisions):**

- Hetzner private network + subnet
- Master node(s) with a bootstrapped k3s server
- Worker node(s) that join the server automatically

**In scope, generated for you:**

- The SSH key pairs the master and worker nodes use to talk to each other —
  created by the module with the `tls` provider, never passed in as variables

**Out of scope (you provide these):**

- The Hetzner Cloud project, API token, and your own public SSH key
- Terraform remote state storage (the project uses **AWS S3** — Hetzner has no
  native state backend)
- An external cloud-controller-manager, CNI extras, ingress, storage classes
- GitOps controllers and the monitoring stack (deployed *into* the cluster after
  it exists)

## Repository layout

```text
hcloud-k8s-cluster/
├── main.tf             # hcloud_network + subnet
├── ssh.tf              # generated node key pairs + uploaded admin key
├── master-node.tf      # hcloud_server master node(s) + k3s server cloud-init
├── worker-node.tf      # hcloud_server worker node(s) + k3s agent cloud-init
├── variables.tf        # input variables
├── outputs.tf          # module outputs
├── versions.tf         # required Terraform + provider versions
├── examples/
│   └── basic/          # runnable usage example
└── docs/               # this documentation
```

Continue to [Architecture »](02-architecture.md)
