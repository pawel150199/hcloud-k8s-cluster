resource "hcloud_server" "master_nodes" {
  count = var.master_nodes_number

  name        = "master-node-${count.index}"
  image       = var.node_image
  server_type = var.node_type
  location    = var.node_location
  ssh_keys    = var.ssh_keys

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
      - ssh-rsa ${var.master_nodes_ssh_key}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
runcmd:
  - apt-get update -y
  - curl https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable-cloud-controller --kubelet-arg cloud-provider=external" sh -
  - chown cluster:cluster /etc/rancher/k3s/k3s.yaml
  - chown cluster:cluster /var/lib/rancher/k3s/server/node-token
EOF


  depends_on = [hcloud_network_subnet.private_network_subnet]
}
