# Private K8S cluster

The ideae behind this project is to create own private Kubernetes cluster.

Cluster will be self managed and for the first creation it will be done by `k3s`.
In the future it can be extended to create the fully managed Kubernetes cluster using other tools like kubeadm or different tool for bootstrapping Kubernetes.

In hetzner community I found similar topic: https://community.hetzner.com/tutorials/setup-your-own-scalable-kubernetes-cluster

## Documentation

Full module documentation lives in [`docs/`](docs/README.md), with Mermaid
diagrams (architecture, network topology, bootstrap sequence) and a usage
example. It can also be exported to PDF:

```bash
cd docs && make        # renders docs/pdf/*.pdf (requires md-to-pdf + internet)
```

| Page | Contents |
| --- | --- |
| [Overview](docs/01-overview.md) | What the module does, goals, scope |
| [Architecture](docs/02-architecture.md) | Diagrams: components, network, bootstrap |
| [Getting started](docs/03-getting-started.md) | Prerequisites, providers, state, first apply |
| [Usage example](docs/04-usage-example.md) | Complete example configuration |
| [Inputs & outputs](docs/05-inputs-and-outputs.md) | Variable and output reference |
| [Operations](docs/06-operations.md) | kubeconfig, scaling, teardown |

## Usefull links
1. https://github.com/solidnerd/terraform-k8s-hcloud -> setup cluster using terraform and kubeadm
2. https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner -> module for terraform to set up a scalable k8s in hcloud
3. https://alexslubsky.medium.com/setup-highly-available-kubernetus-cluster-with-hetzner-cloud-and-terraform-941a9e25ddf6 -> nice article about setting up k8s in hcloud.
4. https://registry.terraform.io/providers/hetznercloud/hcloud/latest -> terraform provider for hetzner cloud
5. https://community.hetzner.com/tutorials/setup-your-own-scalable-kubernetes-cluster -> tutorial how to setup your own scalable kubernetes cluster

## Requirements
1. Infrastructure have to be written in code - terraform.
2. Kubernetes cluster have to be set up automatically.
3. Kubernetes cluster will have one master node and at least one worker node
5. Deployments to the cluster will be done using GitOps.
6. In K8S cluster will be deployed the full monitoring.
7. Potentially scaling of the number of the nodes can be added.


## Thoughts
1. In Hetzner cloud there is no native solution for storing terraform state file so I am storing it in AWS S3 service.

## Command for copying the kubeconfig from master node
```bash
scp -i <your_private_ssh_key> cluster@<master_node_public_ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```
