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
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8ZO/QXW/fKdFoMxFzg8/04DbXLVTcnYOklAAccDVVxo68O77F8eLoYnLq7cZlBTns3f/G8W/sR5ocCvRR8vsNnN503EIU+IJPpEcK4hRk3Q7M0ANl4fSCFd0SyspIQysPEhQutvecf7tWjD1ok7JKcJ7XkXPrV8B8svTootwQVpSh28+YlsO8I+JUN4MvoQPxOdsi7G2zOYpeCsSrn3ohSdUh6XdJltga9fvHHlvA4UCA1NfH+bY85wOIA9BBVAtUPLNsIwrQB0WQ7eXXjfu03Bh/sUowKk/onBoEbkT+pqTADPdcdTl2i1bD2bubmtyL4KjV5I4hJU2EqqFm75/b9FsoALXPmEihU+1q/pYJfHpGaHt+XvW1UJX0rUzFn/BCWQgxTBrCNVnsRB1Ofn2JE/xqjXJkoXHrZhRt75qxzrbnLhhyiLuoDnZRVX4aWWeenertVBrDU/s2+sYxthqfCaWQ3+eluI0Q/cU39G2M19ywbGLo+JHXZv4wFDjX164GsB8IYUSLKM9qJ7t7tE4u158qXrlshyYeCYzVfILsS9MulDdF64ILL21OojwQ+uYMFoFMtRHROtg/OV6F6s2/+cUVDTE3n/V0WeIkG4K/D98keeqBnz7e/bFJTeLO7vn/UFEgr7izX1kktTWWcB/RxPrgZWutLMhE5tyslDooMw==
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDA6wdwvTnF/BFBbP3t8dAgqF/Z9VURspHG4a5CqBFDOoKwV+ZTwHYFZaAbpPuZa9Ez11Wsa0oPNVpp3EpKBPkx5JhPlGqZ8v9pnZB5/TTp6aXo3WJlnGSBlkq699hX2/G8nKC4xNgWx25g7LfIK47RcRvLesB6Z8wPTIrvTbjQvEmvUHTSR+mmZbCCELhqRh9wDh7kbSCXdnOQQh5ibPEsmT8kxIT1vjq+a3TZKq1PH3Tr5BN9SLxvydQN84uC5yIjVU6+VV4oDwO6egWoZKIDIgNniViA0qtlE3LDNe0SnfHfAGAoWL8KJ+D1kx5idF4l9zr04YAss0ZLyfLxgu4jP+eYMLiFZqzBKV4Zp0cWTaPxvOW3+npn05LQZ7GZnBnYIxAtbJ5bek+ZUV5VpQvWPiQSSZDCR0YcBuc1ST8cAgYtNjyvtaQa1kGMwAaLX2DBCj7PBRf9vyYvuQNpTjVKTQJMpPn8yqTzlc8ShoqCybAA/YiVABqXDHoMcOOT/5wOei0DraAXGm33w+TSmHRnjFpBwDvwqvfjXPCpC4LrCN2YfwveAvGW0hyvAvkf6Mcdt8+n4o576tNrp9+pV7UnK3lWwF2zWKVXaUCmaKsZoVCoO/k5GNttoqlXMtTMaK8GUCOj12OjaJp7ephpXV/7v+yCOLpfx0kyS6CixR5Ndw==
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
runcmd:
  - apt-get update -y
  - curl https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable-cloud-controller --kubelet-arg cloud-provider=external" sh -
  - chown cluster:cluster /etc/rancher/k3s/k3s.yaml
  - chown cluster:cluster /var/lib/rancher/k3s/server/node-token
EOF


  depends_on = [ hcloud_network_subnet.private_network_subnet ]
}