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
      ${indent(6, trimspace(yamlencode(local.admin_authorized_keys)))}
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
  # Private key of the worker key pair, so the master can reach the workers.
  - path: /root/.ssh/worker_node_key
    owner: "root:root"
    permissions: "0600"
    content: |
      ${indent(6, trimspace(tls_private_key.worker_node.private_key_openssh))}

runcmd:
  - netplan apply
  - apt-get update -y
  - for i in $(seq 1 60); do PRIVATE_IFACE=$(ip -4 -o addr show | grep " ${local.master_node_private_ips[count.index]}/" | awk '{ print $2 }'); [ -n "$PRIVATE_IFACE" ] && break; sleep 2; done
  - if [ -z "$PRIVATE_IFACE" ]; then echo "private address ${local.master_node_private_ips[count.index]} never came up, aborting k3s install" >&2; exit 1; fi
  - PUBLIC_IP=$(curl -sf http://169.254.169.254/hetzner/v1/metadata/public-ipv4 || true)
  - K3S_ARGS="server --disable traefik --node-ip ${local.master_node_private_ips[count.index]} --advertise-address ${local.master_node_private_ips[count.index]} --flannel-iface $PRIVATE_IFACE --tls-san ${local.master_node_private_ips[count.index]}%{for san in local.master_tls_sans} --tls-san ${san}%{endfor}"
  - if [ -n "$PUBLIC_IP" ]; then K3S_ARGS="$K3S_ARGS --tls-san $PUBLIC_IP"; fi
%{~if local.ha_control_plane}
%{~if count.index == 0}
  # The first server initialises the embedded etcd cluster. Without this flag
  # every server comes up standalone on its own SQLite database, which is one
  # cluster per master rather than one cluster.
  - K3S_ARGS="$K3S_ARGS --cluster-init"
%{~else}
  # etcd admits members one at a time, so the joins are staggered and each one
  # waits for the initialising server to answer before it starts.
  - sleep ${count.index * 20}
  - for i in $(seq 1 180); do curl -skf --max-time 5 https://${local.master_node_private_ips[0]}:6443/ping > /dev/null && break; sleep 5; done
  - K3S_ARGS="$K3S_ARGS --server https://${local.master_node_private_ips[0]}:6443"
%{~endif}
%{~endif}
  # Retried, and the installer is downloaded before it is run: a pipe into sh
  # succeeds even when the download failed, and a large cluster bootstrapping at
  # once does see throttled downloads.
  - for i in $(seq 1 10); do curl -sfL https://get.k3s.io -o /tmp/k3s-install.sh && INSTALL_K3S_VERSION=${var.k3s_version} INSTALL_K3S_EXEC="$K3S_ARGS" K3S_TOKEN=${random_password.k3s_token.result} sh /tmp/k3s-install.sh && break; sleep 15; done
  - chown cluster:cluster /etc/rancher/k3s/k3s.yaml
EOF

  labels = local.master_labels

  depends_on = [hcloud_network_subnet.private_network_subnet]
}
