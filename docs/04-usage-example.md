# 4. Usage example

A complete, runnable example lives in [`examples/basic`](../examples/basic). This
page reproduces and explains it.

## 4.1 The example

```hcl
# examples/basic/main.tf
module "hcloud_kubernetes_cluster" {
  source = "../../"

  # Cluster size
  worker_nodes_number = 2
  master_nodes_number = 1

  # Node hardware / image
  node_image    = "ubuntu-24.04"
  node_type     = "cax11"        # ARM64, shared vCPU
  node_location = "fsn1"         # Falkenstein

  node_enable_ipv4 = true
  node_enable_ipv6 = true

  # SSH: Hetzner-managed key names + cloud-init key material
  ssh_keys = ["your_ssh_key"]

  master_nodes_ssh_pub_key  = "master_ssh_pub_key"
  worker_nodes_ssh_priv_key = "worker_ssh_priv_key"
  worker_nodes_ssh_pub_key  = "worker_ssh_pub_key"

  # Networking
  private_network_ip_range        = "10.0.0.0/16"
  private_network_zone            = "eu-central"
  private_network_type            = "cloud"
  private_network_subnet_ip_range = "10.0.1.0/24"
  master_node_ip                  = "10.0.1.1"
}
```

```hcl
# examples/basic/outputs.tf
output "master_node_ip" {
  description = "Master Node IP Address"
  value       = module.hcloud_kubernetes_cluster.master_node_ip
}
```

```hcl
# examples/basic/versions.tf
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.52.0"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}
```

## 4.2 A more realistic root module

Rather than hardcoding secrets, load real key material from files and the token
from the environment:

```hcl
module "hcloud_kubernetes_cluster" {
  source = "github.com/pawel-polski/hcloud-k8s-cluster"

  master_nodes_number = 1
  worker_nodes_number = 3

  node_type     = "cax21"       # bump size for real workloads
  node_location = "nbg1"        # Nuremberg

  ssh_keys = ["ops-laptop"]     # a key name that exists in your hcloud project

  master_nodes_ssh_pub_key  = trimspace(file("~/.ssh/master.pub"))
  worker_nodes_ssh_pub_key  = trimspace(file("~/.ssh/worker.pub"))
  worker_nodes_ssh_priv_key = file("~/.ssh/worker")
}

output "master_ip" {
  value = module.hcloud_kubernetes_cluster.master_node_ip
}

output "network_cidr" {
  value = module.hcloud_kubernetes_cluster.kubernetes_network_ip_range
}
```

## 4.3 Run it

```bash
cd examples/basic

export HCLOUD_TOKEN="…"
export TF_VAR_hcloud_token="$HCLOUD_TOKEN"

terraform init
terraform apply

# after cloud-init finishes on the master:
terraform output master_node_ip
```

## 4.4 Choosing values

| Setting | Common choices | Notes |
| --- | --- | --- |
| `node_type` | `cax11`, `cax21`, `cx22`, `cpx31` | `cax*` are ARM64; `cx*`/`cpx*` are x86 |
| `node_location` | `fsn1`, `nbg1`, `hel1`, `ash`, `hil` | Keep nodes in one location for low-latency private networking |
| `node_image` | `ubuntu-24.04`, `debian-12` | cloud-init assumes an `apt`-based image |
| `worker_nodes_number` | `1`–`N` | Scale by changing this and re-applying |
| `master_nodes_number` | `1` | Single control plane; `master_node_ip` pins the master, so keep this at `1` |

Continue to [Inputs & outputs »](05-inputs-and-outputs.md)
