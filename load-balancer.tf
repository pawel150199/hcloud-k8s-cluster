# Load balancer in front of the Kubernetes API, created only for an HA control
# plane. Without it every agent points at one hardcoded master, so that master
# is a single point of failure however many servers the control plane has.
resource "hcloud_load_balancer" "control_plane" {
  count = local.ha_control_plane ? 1 : 0

  name               = "kubernetes-control-plane"
  load_balancer_type = var.control_plane_load_balancer_type
  location           = var.node_location
  labels             = var.default_labels
}

resource "hcloud_load_balancer" "control_plane" {
  count = local.ha_control_plane ? 1 : 0

  name = "kubernetes-control-plane"
  load_balancer_type = var.control_plane_load_balancer_type
  location = var.node_location
  labels = var.default_labels
}
resource "hcloud_load_balancer_network" "control_plane" {
  count = local.ha_control_plane ? 1 : 0

  load_balancer_id        = hcloud_load_balancer.control_plane[0].id
  network_id              = hcloud_network.private_network.id
  ip                      = local.control_plane_lb_private_ip
  enable_public_interface = var.control_plane_load_balancer_public

  depends_on = [hcloud_network_subnet.private_network_subnet]
}

resource "hcloud_load_balancer_service" "control_plane_api" {
  count = local.ha_control_plane ? 1 : 0

  load_balancer_id = hcloud_load_balancer.control_plane[0].id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

# Targets are selected by label rather than by server ID on purpose. The masters
# read the load balancer's addresses for their TLS SANs, so pointing the target
# at hcloud_server.master_nodes would close a dependency cycle. A label selector
# is resolved by the API instead, and keeps up with masters added later.
resource "hcloud_load_balancer_target" "control_plane_masters" {
  count = local.ha_control_plane ? 1 : 0

  type             = "label_selector"
  load_balancer_id = hcloud_load_balancer.control_plane[0].id
  label_selector   = local.master_label_selector
  use_private_ip   = true

  depends_on = [hcloud_load_balancer_network.control_plane]
}
