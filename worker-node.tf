resource "hcloud_server" "worker_nodes" {
  count = var.worker_nodes_number

  name        = "worker-node-${count.index}"
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
  }

  user_data = <<EOF
# worker cloud-config
packages:
  - curl
users:
  - name: cluster
    ssh-authorized-keys:
      - ${trimspace(var.ssh_public_key)}
      - ${trimspace(tls_private_key.worker_node.public_key_openssh)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

write_files:
  # Private key of the master key pair, used to read the k3s node-token.
  - path: /root/.ssh/master_node_key
    owner: "root:root"
    permissions: "0600"
    content: |
      ${indent(6, trimspace(tls_private_key.master_node.private_key_openssh))}

runcmd:
  - apt-get update -y
  # wait for the master node to be ready by trying to connect to it
  - until curl -k https://${var.master_node_ip}:6443; do sleep 5; done
  # copy the token from the master node
  - REMOTE_TOKEN=$(ssh -i /root/.ssh/master_node_key -o StrictHostKeyChecking=accept-new cluster@${var.master_node_ip} sudo cat /var/lib/rancher/k3s/server/node-token)
  # Install k3s worker
  - curl -sfL https://get.k3s.io | K3S_URL=https://${var.master_node_ip}:6443 K3S_TOKEN=$REMOTE_TOKEN INSTALL_K3S_EXEC="--kubelet-arg cloud-provider=external" sh -
EOF
  labels    = var.default_labels

  depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_server.master_nodes]
}
