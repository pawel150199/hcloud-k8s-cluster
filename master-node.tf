resource "hcloud_server" "master_nodes" {
  count = var.master_nodes_number

  name        = "master-node-${count.index}"
  image       = var.node_image
  server_type = var.master_node_type
  location    = var.node_location
  ssh_keys    = local.node_ssh_keys

  placement_group_id = var.use_placement_group ? hcloud_placement_group.kubernetes_placement_group[0].id : null
  firewall_ids       = [hcloud_firewall.master_kubernetes_firewall.id]

  public_net {
    ipv4_enabled = var.node_enable_ipv4
    ipv6_enabled = var.node_enable_ipv6
  }

  network {
    network_id = hcloud_network.private_network.id
    ip         = local.master_node_private_ips[count.index]
  }

  user_data = <<EOF
#cloud-config
# master node bootstrap. The '#cloud-config' header above must stay on the very
# first line, otherwise cloud-init discards this whole document.
packages:
  - curl
users:
  # Keep the distro default user, otherwise cloud-init drops it and has no
  # default user to install the Hetzner-provided keys on.
  - default
  - name: cluster
    ssh_authorized_keys:
      ${indent(6, trimspace(yamlencode(local.master_authorized_keys)))}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

write_files:
  # Private key of the worker key pair, so the master can reach the workers.
  - path: /root/.ssh/worker_node_key
    owner: "root:root"
    permissions: "0600"
    content: |
      ${indent(6, trimspace(tls_private_key.worker_node.private_key_openssh))}

runcmd:
  - apt-get update -y
  - until ip -4 -o addr show | grep -q " ${local.master_node_private_ips[count.index]}/"; do sleep 2; done
  - PRIVATE_IFACE=$(ip -4 -o addr show | grep " ${local.master_node_private_ips[count.index]}/" | awk '{ print $2 }')
  - PUBLIC_IP=$(curl -sf http://169.254.169.254/hetzner/v1/metadata/public-ipv4 || true)
  - K3S_ARGS="server --disable traefik --node-ip ${local.master_node_private_ips[count.index]} --advertise-address ${local.master_node_private_ips[count.index]} --flannel-iface $PRIVATE_IFACE --tls-san ${local.master_node_private_ips[count.index]}"
  - if [ -n "$PUBLIC_IP" ]; then K3S_ARGS="$K3S_ARGS --tls-san $PUBLIC_IP"; fi
  - curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$K3S_ARGS" sh -
  - chown cluster:cluster /etc/rancher/k3s/k3s.yaml
  - chown cluster:cluster /var/lib/rancher/k3s/server/node-token
EOF

  labels = var.default_labels

  depends_on = [hcloud_network_subnet.private_network_subnet]
}
