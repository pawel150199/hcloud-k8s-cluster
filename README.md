# Hcloud K8S Cluster

The ideae behind this project is to create module for provisioning a Kubernetes cluster in Hetzner Cloud Provider.

Cluster is self managed and is created using `k3s`.

In Hetzner community I found similar topic: https://community.hetzner.com/tutorials/setup-your-own-scalable-kubernetes-cluster

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.15.0 |
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | ~> 1.69 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | ~> 1.69 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [hcloud_network.private_network](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network) | resource |
| [hcloud_network_subnet.private_network_subnet](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_server.master_nodes](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [hcloud_server.worker_nodes](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [hcloud_ssh_key.admin](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key) | resource |
| [tls_private_key.master_node](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.worker_node](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [hcloud_ssh_keys.project](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/ssh_keys) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_default_labels"></a> [default\_labels](#input\_default\_labels) | Default labels for resources. Hetzner label keys and values must start and end with an alphanumeric character and may only contain letters, digits, `-`, `_` and `.` (max 63 characters). Values may also be empty. | `map(string)` | <pre>{<br/>  "Confidentiality": "C3",<br/>  "Project": "hetzner-kubernetes"<br/>}</pre> | no |
| <a name="input_master_nodes_number"></a> [master\_nodes\_number](#input\_master\_nodes\_number) | Number of master nodes in Cluster | `number` | `1` | no |
| <a name="input_node_enable_ipv4"></a> [node\_enable\_ipv4](#input\_node\_enable\_ipv4) | Kubernetes cluster use IPv4 networking | `bool` | `true` | no |
| <a name="input_node_enable_ipv6"></a> [node\_enable\_ipv6](#input\_node\_enable\_ipv6) | Kubernetes cluster use IPv6 networking | `bool` | `true` | no |
| <a name="input_node_image"></a> [node\_image](#input\_node\_image) | Kubernetes cluster node image | `string` | `"ubuntu-24.04"` | no |
| <a name="input_node_location"></a> [node\_location](#input\_node\_location) | Kubernetes cluster node location | `string` | `"fsn1"` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | Kubernetes cluster node type | `string` | `"cax11"` | no |
| <a name="input_private_network_ip_range"></a> [private\_network\_ip\_range](#input\_private\_network\_ip\_range) | Private network IP range | `string` | `"10.0.0.0/16"` | no |
| <a name="input_private_network_subnet_ip_range"></a> [private\_network\_subnet\_ip\_range](#input\_private\_network\_subnet\_ip\_range) | Private network subnet IP range | `string` | `"10.0.1.0/24"` | no |
| <a name="input_private_network_type"></a> [private\_network\_type](#input\_private\_network\_type) | Private network type | `string` | `"cloud"` | no |
| <a name="input_private_network_zone"></a> [private\_network\_zone](#input\_private\_network\_zone) | Private network zone | `string` | `"eu-central"` | no |
| <a name="input_ssh_key_algorithm"></a> [ssh\_key\_algorithm](#input\_ssh\_key\_algorithm) | Algorithm used for the SSH key pairs generated for the master and worker nodes. One of RSA, ECDSA, ED25519. | `string` | `"ED25519"` | no |
| <a name="input_ssh_key_ecdsa_curve"></a> [ssh\_key\_ecdsa\_curve](#input\_ssh\_key\_ecdsa\_curve) | Curve of the generated SSH key pairs. Only used when ssh\_key\_algorithm is ECDSA. | `string` | `"P384"` | no |
| <a name="input_ssh_key_rsa_bits"></a> [ssh\_key\_rsa\_bits](#input\_ssh\_key\_rsa\_bits) | Key size of the generated SSH key pairs. Only used when ssh\_key\_algorithm is RSA. | `number` | `4096` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | Optional names, IDs or fingerprints of SSH keys that already exist in the Hetzner project. They are installed on the nodes' root user and authorised for the `cluster` user, in addition to `ssh_public_key`. | `list(string)` | `[]` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Public SSH key of your own machine. It is uploaded to the Hetzner project and installed on the root and cluster users of every node. Leave unset to rely on `ssh_keys` instead. | `string` | `null` | no |
| <a name="input_worker_nodes_number"></a> [worker\_nodes\_number](#input\_worker\_nodes\_number) | Number of worker nodes in Cluster | `number` | `2` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_kubernetes_network_ip_range"></a> [kubernetes\_network\_ip\_range](#output\_kubernetes\_network\_ip\_range) | Kubernetes network IP range |
| <a name="output_master_node_ip"></a> [master\_node\_ip](#output\_master\_node\_ip) | Master Node IP Address |
| <a name="output_master_node_ssh_private_key"></a> [master\_node\_ssh\_private\_key](#output\_master\_node\_ssh\_private\_key) | Private key matching master\_node\_ssh\_public\_key. Use it to SSH into the master as the cluster user. |
| <a name="output_master_node_ssh_public_key"></a> [master\_node\_ssh\_public\_key](#output\_master\_node\_ssh\_public\_key) | Public key of the SSH key pair generated for the master node's cluster user |
| <a name="output_worker_node_ssh_private_key"></a> [worker\_node\_ssh\_private\_key](#output\_worker\_node\_ssh\_private\_key) | Private key matching worker\_node\_ssh\_public\_key. Use it to SSH into the workers as the cluster user. |
| <a name="output_worker_node_ssh_public_key"></a> [worker\_node\_ssh\_public\_key](#output\_worker\_node\_ssh\_public\_key) | Public key of the SSH key pair generated for the worker nodes' cluster user |
<!-- END_TF_DOCS -->
