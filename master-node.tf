resource "hcloud_server" "master_nodes" {
  count = var.master_nodes_number

  name        = "master-node-${count.index}"
  image       = var.node_image
  server_type = var.node_type
  location    = var.node_location
  ssh_keys    = local.node_ssh_keys

  public_net {
    ipv4_enabled = var.node_enable_ipv4
    ipv6_enabled = var.node_enable_ipv6
  }

  network {
    network_id = hcloud_network.private_network.id
    ip         = var.master_node_ip
  }

  user_data = <<EOF
# master node cloud-config
packages:
  - curl
users:
  - name: cluster
    ssh-authorized-keys:
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
  - curl https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable-cloud-controller --kubelet-arg cloud-provider=external" sh -
  - chown cluster:cluster /etc/rancher/k3s/k3s.yaml
  - chown cluster:cluster /var/lib/rancher/k3s/server/node-token
EOF

  labels = var.default_labels

  depends_on = [hcloud_network_subnet.private_network_subnet]
}
