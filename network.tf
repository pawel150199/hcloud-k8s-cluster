resource "hcloud_network" "private_network" {
  name     = "kuberrnetes-cluster"
  ip_range = var.private_network_ip_range
}

resource "hcloud_network_subnet" "private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private_network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}
