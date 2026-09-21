# Key pair used by the master node's "cluster" user.
# Workers receive the matching private key so they can SSH into the master
# and read the k3s node-token during bootstrap.
resource "tls_private_key" "master_node" {
  algorithm   = var.ssh_key_algorithm
  rsa_bits    = var.ssh_key_rsa_bits
  ecdsa_curve = var.ssh_key_ecdsa_curve
}

# Key pair used by the worker nodes' "cluster" user.
# The master receives the matching private key so it can reach the workers.
resource "tls_private_key" "worker_node" {
  algorithm   = var.ssh_key_algorithm
  rsa_bits    = var.ssh_key_rsa_bits
  ecdsa_curve = var.ssh_key_ecdsa_curve
}

# The operator's own public key, uploaded to the Hetzner project and installed
# on every node's "root" user. This is the only key material taken from input.
resource "hcloud_ssh_key" "admin" {
  name       = "kubernetes-cluster-admin"
  public_key = var.ssh_public_key
  labels     = var.default_labels
}

locals {
  # Hetzner-managed keys installed on the "root" user of every node.
  node_ssh_keys = concat([hcloud_ssh_key.admin.id], var.ssh_keys)
}
