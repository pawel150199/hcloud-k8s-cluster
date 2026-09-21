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
# on every node's "root" user. This is the only key material taken from input,
# and it is optional: set `ssh_keys` instead to reuse keys that already exist in
# the Hetzner project.
resource "hcloud_ssh_key" "admin" {
  count = local.admin_public_key == "" ? 0 : 1

  name       = "kubernetes-cluster-admin"
  public_key = local.admin_public_key
  labels     = var.default_labels
}

locals {
  # Empty when no key was supplied, so every use below can be made conditional.
  admin_public_key = var.ssh_public_key == null ? "" : trimspace(var.ssh_public_key)

  # Hetzner-managed keys installed on the "root" user of every node.
  node_ssh_keys = concat(hcloud_ssh_key.admin[*].id, var.ssh_keys)

  # Keys authorised for the "cluster" user, rendered into cloud-init.
  # The admin key is dropped from the list when it was not supplied.
  master_authorized_keys = compact([
    local.admin_public_key,
    trimspace(tls_private_key.master_node.public_key_openssh),
  ])

  worker_authorized_keys = compact([
    local.admin_public_key,
    trimspace(tls_private_key.worker_node.public_key_openssh),
  ])
}
