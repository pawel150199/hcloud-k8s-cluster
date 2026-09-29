resource "hcloud_server" "worker_nodes" {
  count = var.worker_nodes_number

  name               = "worker-node-${count.index}"
  image              = var.node_image
  server_type        = var.worker_node_type
  location           = var.node_location
  ssh_keys           = local.node_ssh_keys
  placement_group_id = var.use_placement_group ? hcloud_placement_group.kubernetes_placement_group[floor((var.master_nodes_number + count.index) / local.placement_group_capacity)].id : null
  firewall_ids       = [hcloud_firewall.worker_kubernetes_firewall.id]

  public_net {
    ipv4_enabled = var.use_public_ipv4
    ipv6_enabled = var.use_public_ipv6
  }

  network {
    network_id = hcloud_network.private_network.id
    ip         = local.worker_node_private_ips[count.index]
  }

  user_data = templatefile("${path.module}/templates/cloud-config.yaml.tftpl", {
    hostname                = "worker-node-${count.index}"
    authorized_keys         = local.worker_authorized_keys
    install_worker_node_key = false
    worker_node_private_key = ""
    k3s_token               = random_password.k3s_token.result
    use_tailscale           = var.use_tailscale
    tailscale_auth_key      = var.tailscale_auth_key
    common_script           = local.k3s_common_script

    bootstrap_script = templatefile("${path.module}/templates/bootstrap-worker.sh.tftpl", {
      node_index             = count.index
      private_ip             = local.worker_node_private_ips[count.index]
      control_plane_endpoint = local.control_plane_endpoint
      join_delay             = (count.index % 20) * 3
      k3s_version            = var.k3s_version
    })
  })

  labels = local.worker_labels

  depends_on = [
    hcloud_network_subnet.private_network_subnet,
    hcloud_server.master_nodes,
    hcloud_load_balancer_target.control_plane_masters,
  ]
}
