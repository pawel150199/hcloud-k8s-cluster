output "master_nodes_ips" {
  description = "Master Nodes public IPv4 addresses"
  value       = hcloud_server.master_nodes[*].ipv4_address
}

output "worker_nodes_ips" {
  description = "Worker Nodes public IPv4 addresses"
  value       = hcloud_server.worker_nodes[*].ipv4_address
}

output "master_nodes_private_ips" {
  description = "Master Nodes private addresses, as assigned in the cluster subnet"
  value       = local.master_node_private_ips
}

output "worker_nodes_private_ips" {
  description = "Worker Nodes private addresses, as assigned in the cluster subnet"
  value       = local.worker_node_private_ips
}

output "control_plane_endpoint" {
  description = "Address the agents join through: the API load balancer when the control plane is HA, otherwise the first master"
  value       = local.control_plane_endpoint
}

output "control_plane_load_balancer_ipv4" {
  description = "Public IPv4 address of the Kubernetes API load balancer, or null when no load balancer is created"
  value       = one(hcloud_load_balancer.control_plane[*].ipv4)
}

output "cluster_token" {
  description = "k3s join token shared by every node. Needed to add a node by hand outside Terraform."
  value       = random_password.k3s_token.result
  sensitive   = true
}
