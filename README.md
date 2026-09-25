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

> **Applying a large cluster:** past roughly 30 nodes, pass `-parallelism=5` to
> `terraform apply` and `terraform destroy`. A Hetzner project allows 3600 API
> requests per hour and each server costs several, so the default concurrency of
> ten can exhaust the budget mid-apply and leave servers half-created. See
> [Applying a large cluster](docs/06-operations.md#applying-a-large-cluster).

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
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | ~> 1.69 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [hcloud_firewall.master_kubernetes_firewall](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall) | resource |
| [hcloud_firewall.worker_kubernetes_firewall](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall) | resource |
| [hcloud_load_balancer.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer) | resource |
| [hcloud_load_balancer_network.control_plane](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_network) | resource |
| [hcloud_load_balancer_service.control_plane_api](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_service) | resource |
| [hcloud_load_balancer_target.control_plane_masters](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/load_balancer_target) | resource |
| [hcloud_network.private_network](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network) | resource |
| [hcloud_network_subnet.private_network_subnet](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/network_subnet) | resource |
| [hcloud_placement_group.kubernetes_placement_group](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/placement_group) | resource |
| [hcloud_server.master_nodes](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [hcloud_server.worker_nodes](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server) | resource |
| [hcloud_ssh_key.admin](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/ssh_key) | resource |
| [random_password.k3s_token](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [tls_private_key.worker_node](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [hcloud_ssh_keys.project](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/data-sources/ssh_keys) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_control_plane_load_balancer_public"></a> [control\_plane\_load\_balancer\_public](#input\_control\_plane\_load\_balancer\_public) | Expose the Kubernetes API load balancer on a public address. Off by default: Hetzner firewalls do not apply to load balancers, so a public listener would bypass `kube_api_source_ips`. With it off the load balancer serves the private network only and `kubectl` from outside goes to a master's own public address. | `bool` | `false` | no |
| <a name="input_control_plane_load_balancer_type"></a> [control\_plane\_load\_balancer\_type](#input\_control\_plane\_load\_balancer\_type) | Hetzner load balancer type used for the Kubernetes API. | `string` | `"lb11"` | no |
| <a name="input_custom_master_firewall_rules"></a> [custom\_master\_firewall\_rules](#input\_custom\_master\_firewall\_rules) | Additional firewall rules for the master nodes, applied on top of the defaults (inbound 22, 443, 6443 and outbound TCP to anywhere). | <pre>list(object({<br/>    direction       = string<br/>    protocol        = string<br/>    port            = optional(string)<br/>    source_ips      = optional(list(string))<br/>    destination_ips = optional(list(string))<br/>    description     = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_custom_worker_firewall_rules"></a> [custom\_worker\_firewall\_rules](#input\_custom\_worker\_firewall\_rules) | Additional firewall rules for the worker nodes, applied on top of the defaults (inbound 22, 443 and outbound TCP to anywhere). | <pre>list(object({<br/>    direction       = string<br/>    protocol        = string<br/>    port            = optional(string)<br/>    source_ips      = optional(list(string))<br/>    destination_ips = optional(list(string))<br/>    description     = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_default_labels"></a> [default\_labels](#input\_default\_labels) | Default labels for resources. Hetzner label keys and values must start and end with an alphanumeric character and may only contain letters, digits, `-`, `_` and `.` (max 63 characters). Values may also be empty. | `map(string)` | <pre>{<br/>  "Confidentiality": "C3",<br/>  "Project": "hetzner-kubernetes"<br/>}</pre> | no |
| <a name="input_k3s_version"></a> [k3s\_version](#input\_k3s\_version) | Version of k3s which is pinned with kubernetes version | `string` | `"v1.36.4+k3s1"` | no |
| <a name="input_kube_api_source_ips"></a> [kube\_api\_source\_ips](#input\_kube\_api\_source\_ips) | Networks allowed to reach the Kubernetes API on port 6443 from outside the cluster. Nodes themselves join over the private network and are always allowed. | `list(string)` | <pre>[<br/>  "0.0.0.0/0",<br/>  "::/0"<br/>]</pre> | no |
| <a name="input_master_node_type"></a> [master\_node\_type](#input\_master\_node\_type) | Master node type. The default suits a small cluster. A control plane serving many workers, or running embedded etcd for an HA setup, wants dedicated vCPUs (`ccx*`) rather than a shared-vCPU type. | `string` | `"cx23"` | no |
| <a name="input_master_nodes_number"></a> [master\_nodes\_number](#input\_master\_nodes\_number) | Number of master nodes in Cluster. Values above 1 build an HA control plane on embedded etcd, which needs a quorum and therefore an odd number of servers. | `number` | `1` | no |
| <a name="input_node_enable_ipv4"></a> [node\_enable\_ipv4](#input\_node\_enable\_ipv4) | Kubernetes cluster use IPv4 networking | `bool` | `true` | no |
| <a name="input_node_enable_ipv6"></a> [node\_enable\_ipv6](#input\_node\_enable\_ipv6) | Kubernetes cluster use IPv6 networking | `bool` | `true` | no |
| <a name="input_node_image"></a> [node\_image](#input\_node\_image) | Kubernetes cluster node image | `string` | `"ubuntu-26.04"` | no |
| <a name="input_node_location"></a> [node\_location](#input\_node\_location) | Kubernetes cluster node location | `string` | `"fsn1"` | no |
| <a name="input_private_network_ip_range"></a> [private\_network\_ip\_range](#input\_private\_network\_ip\_range) | Private network IP range | `string` | `"10.0.0.0/16"` | no |
| <a name="input_private_network_subnet_ip_range"></a> [private\_network\_subnet\_ip\_range](#input\_private\_network\_subnet\_ip\_range) | Private network subnet IP range | `string` | `"10.0.1.0/24"` | no |
| <a name="input_private_network_type"></a> [private\_network\_type](#input\_private\_network\_type) | Private network type | `string` | `"cloud"` | no |
| <a name="input_private_network_zone"></a> [private\_network\_zone](#input\_private\_network\_zone) | Private network zone | `string` | `"eu-central"` | no |
| <a name="input_ssh_key_algorithm"></a> [ssh\_key\_algorithm](#input\_ssh\_key\_algorithm) | Algorithm used for the SSH key pair the module generates so the masters can reach the workers. One of RSA, ECDSA, ED25519. | `string` | `"ED25519"` | no |
| <a name="input_ssh_key_ecdsa_curve"></a> [ssh\_key\_ecdsa\_curve](#input\_ssh\_key\_ecdsa\_curve) | Curve of the generated SSH key pair. Only used when ssh\_key\_algorithm is ECDSA. | `string` | `"P384"` | no |
| <a name="input_ssh_key_rsa_bits"></a> [ssh\_key\_rsa\_bits](#input\_ssh\_key\_rsa\_bits) | Key size of the generated SSH key pair. Only used when ssh\_key\_algorithm is RSA. | `number` | `4096` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | Optional names, IDs or fingerprints of SSH keys that already exist in the Hetzner project. They are installed on the nodes' root user and authorised for the `cluster` user, in addition to `ssh_public_key`. | `list(string)` | `[]` | no |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Public SSH key of your own machine. It is uploaded to the Hetzner project and installed on the root and cluster users of every node. Leave unset to rely on `ssh_keys` instead. | `string` | `null` | no |
| <a name="input_ssh_source_ips"></a> [ssh\_source\_ips](#input\_ssh\_source\_ips) | Networks allowed to reach SSH on the nodes. Defaults to the whole internet; narrow it to your own address where you can. | `list(string)` | <pre>[<br/>  "0.0.0.0/0",<br/>  "::/0"<br/>]</pre> | no |
| <a name="input_use_control_plane_load_balancer"></a> [use\_control\_plane\_load\_balancer](#input\_use\_control\_plane\_load\_balancer) | Put a load balancer in front of the Kubernetes API and have the workers join through it. Only takes effect when `master_nodes_number` is greater than 1; a single master has nothing to balance. | `bool` | `true` | no |
| <a name="input_use_placement_group"></a> [use\_placement\_group](#input\_use\_placement\_group) | If true it uses Placement Groups, which spread nodes over different physical machines so that they are less likely to fail together. A group holds at most ten servers, so a larger cluster is spread over as many groups as it needs. | `bool` | `true` | no |
| <a name="input_worker_node_type"></a> [worker\_node\_type](#input\_worker\_node\_type) | Worker node type | `string` | `"cx23"` | no |
| <a name="input_worker_nodes_number"></a> [worker\_nodes\_number](#input\_worker\_nodes\_number) | Number of worker nodes in Cluster | `number` | `2` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_token"></a> [cluster\_token](#output\_cluster\_token) | k3s join token shared by every node. Needed to add a node by hand outside Terraform. |
| <a name="output_control_plane_endpoint"></a> [control\_plane\_endpoint](#output\_control\_plane\_endpoint) | Address the agents join through: the API load balancer when the control plane is HA, otherwise the first master |
| <a name="output_control_plane_load_balancer_ipv4"></a> [control\_plane\_load\_balancer\_ipv4](#output\_control\_plane\_load\_balancer\_ipv4) | Public IPv4 address of the Kubernetes API load balancer, or null when no load balancer is created |
| <a name="output_master_nodes_ips"></a> [master\_nodes\_ips](#output\_master\_nodes\_ips) | Master Nodes public IPv4 addresses |
| <a name="output_master_nodes_private_ips"></a> [master\_nodes\_private\_ips](#output\_master\_nodes\_private\_ips) | Master Nodes private addresses, as assigned in the cluster subnet |
| <a name="output_worker_nodes_ips"></a> [worker\_nodes\_ips](#output\_worker\_nodes\_ips) | Worker Nodes public IPv4 addresses |
| <a name="output_worker_nodes_private_ips"></a> [worker\_nodes\_private\_ips](#output\_worker\_nodes\_private\_ips) | Worker Nodes private addresses, as assigned in the cluster subnet |
<!-- END_TF_DOCS -->
