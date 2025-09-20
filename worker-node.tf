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
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8ZO/QXW/fKdFoMxFzg8/04DbXLVTcnYOklAAccDVVxo68O77F8eLoYnLq7cZlBTns3f/G8W/sR5ocCvRR8vsNnN503EIU+IJPpEcK4hRk3Q7M0ANl4fSCFd0SyspIQysPEhQutvecf7tWjD1ok7JKcJ7XkXPrV8B8svTootwQVpSh28+YlsO8I+JUN4MvoQPxOdsi7G2zOYpeCsSrn3ohSdUh6XdJltga9fvHHlvA4UCA1NfH+bY85wOIA9BBVAtUPLNsIwrQB0WQ7eXXjfu03Bh/sUowKk/onBoEbkT+pqTADPdcdTl2i1bD2bubmtyL4KjV5I4hJU2EqqFm75/b9FsoALXPmEihU+1q/pYJfHpGaHt+XvW1UJX0rUzFn/BCWQgxTBrCNVnsRB1Ofn2JE/xqjXJkoXHrZhRt75qxzrbnLhhyiLuoDnZRVX4aWWeenertVBrDU/s2+sYxthqfCaWQ3+eluI0Q/cU39G2M19ywbGLo+JHXZv4wFDjX164GsB8IYUSLKM9qJ7t7tE4u158qXrlshyYeCYzVfILsS9MulDdF64ILL21OojwQ+uYMFoFMtRHROtg/OV6F6s2/+cUVDTE3n/V0WeIkG4K/D98keeqBnz7e/bFJTeLO7vn/UFEgr7izX1kktTWWcB/RxPrgZWutLMhE5tyslDooMw==
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

write_files:
  - path: /root/.ssh/id_rsa
    content: |
      -----BEGIN OPENSSH PRIVATE KEY-----
      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
      -----END OPENSSH PRIVATE KEY-----
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

    depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_server.master_node]
}