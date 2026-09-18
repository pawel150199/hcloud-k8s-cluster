# 5. Inputs & outputs

Full reference for the module's variables (`variables.tf`) and outputs
(`outputs.tf`).

## 5.1 Inputs

### Cluster sizing

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `master_nodes_number` | `number` | `1` | Number of master (k3s server) nodes |
| `worker_nodes_number` | `number` | `2` | Number of worker (k3s agent) nodes |

### Node configuration

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `node_image` | `string` | `"ubuntu-24.04"` | OS image for every node (must be `apt`-based for cloud-init) |
| `node_type` | `string` | `"cax11"` | Hetzner server type (e.g. `cax11`, `cx22`) |
| `node_location` | `string` | `"fsn1"` | Hetzner location (`fsn1`, `nbg1`, `hel1`, …) |
| `node_enable_ipv4` | `bool` | `true` | Attach a public IPv4 to nodes |
| `node_enable_ipv6` | `bool` | `true` | Attach a public IPv6 to nodes |
| `master_node_ip` | `string` | `"10.0.1.1"` | Fixed private IP assigned to the master node |

### Networking

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `private_network_ip_range` | `string` | `"10.0.0.0/16"` | CIDR of the private `hcloud_network` |
| `private_network_subnet_ip_range` | `string` | `"10.0.1.0/24"` | CIDR of the subnet¹ |
| `private_network_zone` | `string` | `"eu-central"` | Network zone of the subnet¹ |
| `private_network_type` | `string` | `"cloud"` | Subnet type¹ |

### SSH keys

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `ssh_keys` | `list(string)` | `null` | Names of SSH keys already present in the Hetzner project, installed on nodes' `root` user |
| `master_nodes_ssh_pub_key` | `string` | `null` | Public key added to the master's `cluster` user via cloud-init² |
| `worker_nodes_ssh_pub_key` | `string` | `null` | Public key added to the worker's `cluster` user via cloud-init² |
| `worker_nodes_ssh_priv_key` | `string` | `null` | Private key written to workers so they can SSH into the master to read the k3s join token |

> ¹ **Currently informational.** `network.tf` hardcodes the subnet's `type`,
> `network_zone`, and `ip_range`, so these three variables are not yet wired into
> the subnet resource. Set them for forward-compatibility, but changing them
> won't move the subnet until the module is updated.
>
> ² The cloud-init templates in `master-node.tf` / `worker-node.tf` reference
> these keys via `user_data`. Make sure the `user_data` references match the
> declared variable names before applying.

## 5.2 Outputs

| Name | Type | Description |
| --- | --- | --- |
| `kubernetes_network_ip_range` | `string` | CIDR of the created private network (`private_network_ip_range`) |
| `master_node_ip` | `string` / `list` | Public IPv4 address of the master node(s) |

Example consumption from a root module:

```hcl
output "master_ip" {
  value = module.hcloud_kubernetes_cluster.master_node_ip
}

output "network_cidr" {
  value = module.hcloud_kubernetes_cluster.kubernetes_network_ip_range
}
```

## 5.3 Resources created

| Resource | Terraform address | Count |
| --- | --- | --- |
| Private network | `hcloud_network.private_network` | 1 |
| Subnet | `hcloud_network_subnet.private_network_subnet` | 1 |
| Master server(s) | `hcloud_server.master_nodes` | `master_nodes_number` |
| Worker server(s) | `hcloud_server.worker_nodes` | `worker_nodes_number` |

Continue to [Operations »](06-operations.md)
