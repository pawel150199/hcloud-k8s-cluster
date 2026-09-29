resource "hcloud_server" "master_nodes" {
  count = var.master_nodes_number

  name        = "master-node-${count.index}"
  image       = var.node_image
  server_type = var.master_node_type
  location    = var.node_location
  ssh_keys    = local.node_ssh_keys

  placement_group_id = var.use_placement_group ? hcloud_placement_group.kubernetes_placement_group[floor(count.index / local.placement_group_capacity)].id : null
  firewall_ids       = [hcloud_firewall.master_kubernetes_firewall.id]

  public_net {
    ipv4_enabled = var.use_public_ipv4
    ipv6_enabled = var.use_public_ipv6
  }

  network {
    network_id = hcloud_network.private_network.id
    ip         = local.master_node_private_ips[count.index]
  }

  user_data = templatefile("${path.module}/templates/cloud-config.yaml.tftpl", {
    hostname                = "master-node-${count.index}"
    authorized_keys         = local.admin_authorized_keys
    install_worker_node_key = true
    worker_node_private_key = tls_private_key.worker_node.private_key_openssh
    k3s_token               = random_password.k3s_token.result
    use_tailscale           = var.use_tailscale
    tailscale_auth_key      = var.tailscale_auth_key
    common_script           = local.k3s_common_script

    bootstrap_script = templatefile("${path.module}/templates/bootstrap-master.sh.tftpl", {
      node_index       = count.index
      private_ip       = local.master_node_private_ips[count.index]
      first_master_ip  = local.master_node_private_ips[0]
      ha_control_plane = local.ha_control_plane
      tls_sans         = local.master_tls_sans
      k3s_version      = var.k3s_version
    })
  })

  labels = local.master_labels

  depends_on = [hcloud_network_subnet.private_network_subnet]
}
