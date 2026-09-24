locals {
  # Private IP of the first master, the address every worker joins through.
  master_node_private_ip = local.master_node_private_ips[0]
}

resource "hcloud_server" "worker_nodes" {
  count = var.worker_nodes_number

  name               = "worker-node-${count.index}"
  image              = var.node_image
  server_type        = var.worker_node_type
  location           = var.node_location
  ssh_keys           = local.node_ssh_keys
  placement_group_id = var.use_placement_group ? hcloud_placement_group.kubernetes_placement_group[0].id : null
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
# worker bootstrap. The '#cloud-config' header above must stay on the very
# first line, otherwise cloud-init discards this whole document.
packages:
  - curl
users:
  # Keep the distro default user, otherwise cloud-init drops it and has no
  # default user to install the Hetzner-provided keys on.
  - default
  - name: cluster
    ssh_authorized_keys:
      ${indent(6, trimspace(yamlencode(local.worker_authorized_keys)))}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

write_files:
  # The Hetzner image only renders netplan config for eth0, so the private NIC
  # (enp7s0) stays DOWN with no address and nothing joins over the private
  # network. eth0 keeps its own name, and its altname is enx<mac>, so "enp*"
  # matches only the private interfaces.
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
  # Private key of the master key pair, used to read the k3s node-token.
  - path: /root/.ssh/master_node_key
    owner: "root:root"
    permissions: "0600"
    content: |
      ${indent(6, trimspace(tls_private_key.master_node.private_key_openssh))}

runcmd:
  - netplan apply
  - apt-get update -y
  - for i in $(seq 1 60); do PRIVATE_IFACE=$(ip -4 -o addr show | grep " ${local.worker_node_private_ips[count.index]}/" | awk '{ print $2 }'); [ -n "$PRIVATE_IFACE" ] && break; sleep 2; done
  - if [ -z "$PRIVATE_IFACE" ]; then echo "private address ${local.worker_node_private_ips[count.index]} never came up, aborting k3s install" >&2; exit 1; fi
  # wait for the master node to be ready by trying to connect to it
  - for i in $(seq 1 120); do curl -sk https://${local.master_node_private_ip}:6443/ping > /dev/null && break; sleep 5; done
  # copy the token from the master node
  - REMOTE_TOKEN=$(ssh -i /root/.ssh/master_node_key -o StrictHostKeyChecking=accept-new cluster@${local.master_node_private_ip} sudo cat /var/lib/rancher/k3s/server/node-token)
  # Install k3s worker
  - curl -sfL https://get.k3s.io | K3S_URL=https://${local.master_node_private_ip}:6443 K3S_TOKEN=$REMOTE_TOKEN INSTALL_K3S_EXEC="--node-ip ${local.worker_node_private_ips[count.index]} --flannel-iface $PRIVATE_IFACE" sh -
EOF
  labels    = var.default_labels

  depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_server.master_nodes]
}
