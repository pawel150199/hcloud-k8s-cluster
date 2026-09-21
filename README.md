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

## Module reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.15.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | ~> 1.69 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | ~> 1.69 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [hcloud_network.private_network](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network) | resource |
| [hcloud_network_subnet.private_network_subnet](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_server.master_nodes](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [hcloud_server.worker_nodes](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_default_labels"></a> [default\_labels](#input\_default\_labels) | Default labels for resources | `map(string)` | <pre>{<br/>  "Confidentiality": "C3",<br/>  "Project": "Hetzner Kubernetes"<br/>}</pre> | no |
| <a name="input_master_node_ip"></a> [master\_node\_ip](#input\_master\_node\_ip) | Kubernetes cluster master node ip | `string` | `"10.0.1.1"` | no |
| <a name="input_master_nodes_number"></a> [master\_nodes\_number](#input\_master\_nodes\_number) | Number of master nodes in Cluster | `number` | `1` | no |
| <a name="input_master_nodes_ssh_pub_key"></a> [master\_nodes\_ssh\_pub\_key](#input\_master\_nodes\_ssh\_pub\_key) | Public SSH key deployed to master nodes | `string` | `null` | no |
| <a name="input_node_enable_ipv4"></a> [node\_enable\_ipv4](#input\_node\_enable\_ipv4) | Kubernetes cluster use IPv4 networking | `bool` | `true` | no |
| <a name="input_node_enable_ipv6"></a> [node\_enable\_ipv6](#input\_node\_enable\_ipv6) | Kubernetes cluster use IPv6 networking | `bool` | `true` | no |
| <a name="input_node_image"></a> [node\_image](#input\_node\_image) | Kubernetes cluster node image | `string` | `"ubuntu-24.04"` | no |
| <a name="input_node_location"></a> [node\_location](#input\_node\_location) | Kubernetes cluster node location | `string` | `"fsn1"` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Kubernetes cluster node type | `string` | `"cax11"` | no |
| <a name="input_private_network_ip_range"></a> [private\_network\_ip\_range](#input\_private\_network\_ip\_range) | Private network IP range | `string` | `"10.0.0.0/16"` | no |
| <a name="input_private_network_subnet_ip_range"></a> [private\_network\_subnet\_ip\_range](#input\_private\_network\_subnet\_ip\_range) | Private network subnet IP range | `string` | `"10.0.1.0/24"` | no |
| <a name="input_private_network_type"></a> [private\_network\_type](#input\_private\_network\_type) | Private network type | `string` | `"cloud"` | no |
| <a name="input_private_network_zone"></a> [private\_network\_zone](#input\_private\_network\_zone) | Private network zone | `string` | `"eu-central"` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | SSH keys | `list(string)` | `null` | no |
| <a name="input_worker_nodes_number"></a> [worker\_nodes\_number](#input\_worker\_nodes\_number) | Number of worker nodes in Cluster | `number` | `2` | no |
| <a name="input_worker_nodes_ssh_priv_key"></a> [worker\_nodes\_ssh\_priv\_key](#input\_worker\_nodes\_ssh\_priv\_key) | Private SSH key used by master to reach worker nodes | `string` | `null` | no |
| <a name="input_worker_nodes_ssh_pub_key"></a> [worker\_nodes\_ssh\_pub\_key](#input\_worker\_nodes\_ssh\_pub\_key) | Public SSH key deployed to worker nodes | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_kubernetes_network_ip_range"></a> [kubernetes\_network\_ip\_range](#output\_kubernetes\_network\_ip\_range) | Kubernetes network IP range |
| <a name="output_master_node_ip"></a> [master\_node\_ip](#output\_master\_node\_ip) | Master Node IP Address |
<!-- END_TF_DOCS -->
