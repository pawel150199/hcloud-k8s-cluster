# 3. Getting started

This page walks through everything needed to go from an empty Hetzner project to
a running cluster.

## 3.1 Prerequisites

| Tool / resource | Purpose |
| --- | --- |
| [Terraform](https://developer.hashicorp.com/terraform) ≥ 1.3 | Runs the module |
| [Hetzner Cloud](https://console.hetzner.cloud/) project + **API token** | Target infrastructure |
| An SSH key uploaded to Hetzner | Placed on the nodes at creation (`ssh_keys`) |
| A key pair for the `cluster` user | Injected via cloud-init for the k3s join flow |
| AWS S3 bucket (recommended) | Remote Terraform state — Hetzner has no native backend |

### Create the Hetzner API token

In the Hetzner Cloud Console: **Security → API Tokens → Generate API Token**
(Read & Write). Export it so the provider can read it:

```bash
export HCLOUD_TOKEN="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### SSH keys

Two distinct concerns:

1. **`ssh_keys`** — the *names* of SSH keys already uploaded to your Hetzner
   project. Hetzner installs these on the nodes' default `root` user.
2. **`master_nodes_ssh_pub_key` / `worker_nodes_ssh_pub_key` /
   `worker_nodes_ssh_priv_key`** — key material injected via cloud-init for the
   `cluster` user. The worker's **private** key lets it SSH into the master to
   read the k3s join token during bootstrap (see
   [Architecture §2.4](02-architecture.md#24-bootstrap-sequence)).

```bash
ssh-keygen -t rsa -b 4096 -f ./master -N ""   # master.pub
ssh-keygen -t rsa -b 4096 -f ./worker -N ""   # worker.pub / worker
```

## 3.2 Provider and backend

The module itself declares only resources — you configure the provider and
backend in your **root** module. A minimal root setup:

```hcl
terraform {
  required_version = ">= 1.3"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.52"
    }
  }

  # Remote state in AWS S3 (Hetzner has no native state backend).
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "hcloud-k8s-cluster/terraform.tfstate"
    region = "eu-central-1"
  }
}

variable "hcloud_token" {
  type      = string
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token   # or omit and rely on HCLOUD_TOKEN
}
```

> The `examples/basic` directory ships a `versions.tf` you can use as a template.

## 3.3 First apply

```bash
# 1. Initialise providers and backend
terraform init

# 2. Review the plan
terraform plan

# 3. Create the cluster
terraform apply
```

`apply` returns once the servers exist. **The k3s bootstrap continues in the
background** via cloud-init — allow a few minutes before the API server and
workers are Ready. Track progress by SSHing into the master:

```bash
ssh cluster@<master_public_ip>
sudo journalctl -u k3s -f          # control-plane logs
sudo kubectl get nodes -o wide     # watch workers join
```

## 3.4 Fetch the kubeconfig

Copy the kubeconfig off the master and point `kubectl` at it:

```bash
scp -i ./master cluster@<master_public_ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config

# The kubeconfig points at 127.0.0.1 — repoint it at the master's IP:
sed -i '' "s/127.0.0.1/<master_public_ip>/" ~/.kube/config

kubectl get nodes
```

More day-2 operations are covered in [Operations »](06-operations.md).
