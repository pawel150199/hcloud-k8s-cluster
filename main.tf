# Network
resource "hcloud_network" "private_network" {
  name     = "kubernetes-cluster"
  ip_range = var.private_network_ip_range
  labels   = var.default_labels
}

resource "hcloud_network_subnet" "private_network_subnet" {
  type         = var.private_network_type
  network_id   = hcloud_network.private_network.id
  network_zone = var.private_network_zone
  ip_range     = var.private_network_subnet_ip_range
}

# Placement Group
resource "hcloud_placement_group" "kubernetes_placement_group" {
  count  = var.use_placement_group ? 1 : 0
  name   = "kubernetes-placement-group"
  type   = "spread"
  labels = var.default_labels
}

locals {
  # Private addresses are assigned explicitly instead of being read back off the
  # servers. The master's own cloud-init needs the address the master resource
  # produces, and reading it from the resource itself is a dependency cycle.
  # Host 1 of the subnet is the first master; workers continue after the masters.
  master_node_private_ips = [
    for i in range(var.master_nodes_number) :
    cidrhost(var.private_network_subnet_ip_range, i + 1)
  ]

  worker_node_private_ips = [
    for i in range(var.worker_nodes_number) :
    cidrhost(var.private_network_subnet_ip_range, var.master_nodes_number + i + 1)
  ]
}
