output "kubernetes_network_ip_range" {
  description = "Kubernetes network IP range"
  value       = hcloud_network.private_network.ip_range
}

output "master_node_ip" {
  description = "Master Node IP Address"
  value       = hcloud_server.master_nodes[0].ipv4_address
}

output "master_node_ssh_public_key" {
  description = "Public key of the SSH key pair generated for the master node's cluster user"
  value       = tls_private_key.master_node.public_key_openssh
}

output "master_node_ssh_private_key" {
  description = "Private key matching master_node_ssh_public_key. Use it to SSH into the master as the cluster user."
  value       = tls_private_key.master_node.private_key_openssh
  sensitive   = true
}

output "worker_node_ssh_public_key" {
  description = "Public key of the SSH key pair generated for the worker nodes' cluster user"
  value       = tls_private_key.worker_node.public_key_openssh
}

output "worker_node_ssh_private_key" {
  description = "Private key matching worker_node_ssh_public_key. Use it to SSH into the workers as the cluster user."
  value       = tls_private_key.worker_node.private_key_openssh
  sensitive   = true
}
