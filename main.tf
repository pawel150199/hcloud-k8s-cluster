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
