output "master_nodes_ips" {
  description = "Master Nodes IP Addresses"
  value       = hcloud_server.master_nodes[*].ipv4_address
}

output "worker_nodes_ips" {
  description = "Worker Nodes IP Addresses"
  value       = hcloud_server.worker_nodes[*].ipv4_address
}
