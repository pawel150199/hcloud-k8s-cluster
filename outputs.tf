output "kubernetes_network_ip_range" {
  description = "Kubernetes network IP range"
  value       = hcloud_network.private_network.ip_range
}

output "master_node_ip" {
  description = "Master Node IP Address"
  value       = hcloud_server.master_nodes[0].ipv4_address
}
