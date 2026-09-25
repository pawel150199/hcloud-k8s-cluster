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
    ipv4_enabled = var.node_enable_ipv4
    ipv6_enabled = var.node_enable_ipv6
  }

  network {
    network_id = hcloud_network.private_network.id
    ip         = local.worker_node_private_ips[count.index]
  }

  user_data = <<EOF
#cloud-config
packages:
  - curl
users:
  # 'default' keeps the distro user that carries the Hetzner-provided keys.
  - default
  - name: cluster
    ssh_authorized_keys:
      ${indent(6, trimspace(yamlencode(local.worker_authorized_keys)))}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

write_files:
  # The Hetzner image only renders netplan config for eth0, so the private NIC
  # would stay DOWN. eth0 keeps its own name, so "enp*" matches only private NICs.
  - path: /etc/netplan/60-hcloud-private.yaml
    owner: "root:root"
    permissions: "0600"
    content: |
      network:
        version: 2
        ethernets:
          hcloud-private:
            match:
              name: "enp*"
            dhcp4: true

runcmd:
  - netplan apply
  - apt-get update -y
  - for i in $(seq 1 60); do PRIVATE_IFACE=$(ip -4 -o addr show | grep " ${local.worker_node_private_ips[count.index]}/" | awk '{ print $2 }'); [ -n "$PRIVATE_IFACE" ] && break; sleep 2; done
  - if [ -z "$PRIVATE_IFACE" ]; then echo "private address ${local.worker_node_private_ips[count.index]} never came up, aborting k3s install" >&2; exit 1; fi
  # Spread the joins of a large worker pool.
  - sleep ${(count.index % 20) * 3}
  - for i in $(seq 1 240); do curl -skf --max-time 5 https://${local.control_plane_endpoint}:6443/ping > /dev/null && break; sleep 5; done
  # Download before running: a pipe into sh succeeds even when the download failed.
  - for i in $(seq 1 10); do curl -sfL https://get.k3s.io -o /tmp/k3s-install.sh && INSTALL_K3S_VERSION=${var.k3s_version} K3S_URL=https://${local.control_plane_endpoint}:6443 K3S_TOKEN=${random_password.k3s_token.result} INSTALL_K3S_EXEC="--node-ip ${local.worker_node_private_ips[count.index]} --flannel-iface $PRIVATE_IFACE" sh /tmp/k3s-install.sh && break; sleep 15; done
EOF

  labels = local.worker_labels

  depends_on = [
    hcloud_network_subnet.private_network_subnet,
    hcloud_server.master_nodes,
    hcloud_load_balancer_target.control_plane_masters,
  ]
}
