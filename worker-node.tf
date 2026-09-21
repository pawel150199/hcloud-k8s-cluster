resource "hcloud_server" "worker_nodes" {
  count = var.worker_nodes_number

  name        = "worker-node-${count.index}"
  image       = var.node_image
  server_type = var.node_type
  location    = var.node_location

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
      - ssh-rsa ${var.worker_nodes_ssh_pub_key}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

write_files:
  - path: /root/.ssh/id_rsa
    content: |
      ${var.worker_nodes_ssh_priv_key}
    permissions: "0600"

runcmd:
  - apt-get update -y
  - # wait for the master node to be ready by trying to connect to it
  - until curl -k https://10.0.1.1:6443; do sleep 5; done
  - # copy the token from the master node
  - REMOTE_TOKEN=$(ssh -o StrictHostKeyChecking=accept-new cluster@10.0.1.1 sudo cat /var/lib/rancher/k3s/server/node-token)
  - # Install k3s worker
  - curl -sfL https://get.k3s.io | K3S_URL=https://10.0.1.1:6443 K3S_TOKEN=$REMOTE_TOKEN INSTALL_K3S_EXEC="--kubelet-arg cloud-provider=external" sh -
EOF
  labels    = var.default_labels

  depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_server.master_nodes]
}
