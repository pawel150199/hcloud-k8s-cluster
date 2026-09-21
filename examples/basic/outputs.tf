output "master_node_ip" {
  description = "Master Node IP Address"
  value       = module.hcloud_kubernetes_cluster.master_node_ip
}

output "master_node_ssh_private_key" {
  description = "Private key for SSH access to the master node as the cluster user"
  value       = module.hcloud_kubernetes_cluster.master_node_ssh_private_key
  sensitive   = true
}

output "worker_node_ssh_private_key" {
  description = "Private key for SSH access to the worker nodes as the cluster user"
  value       = module.hcloud_kubernetes_cluster.worker_node_ssh_private_key
  sensitive   = true
}
