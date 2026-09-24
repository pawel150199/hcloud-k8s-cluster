output "master_nodes_ips" {
  description = "Master Nodes IP Addresses"
  value       = module.hcloud_kubernetes_cluster.master_nodes_ips
}

output "worker_nodes_ips" {
  description = "Worker Nodes IP Addresses"
  value       = module.hcloud_kubernetes_cluster.worker_nodes_ips
}
