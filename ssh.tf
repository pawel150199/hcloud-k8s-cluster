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

# hcloud_server installs the keys named in `var.ssh_keys` on the root user only,
# and a name or ID carries no key material. Look the project's keys up so the
# selected ones can also be authorised for the "cluster" user via cloud-init.
data "hcloud_ssh_keys" "project" {
  count = length(var.ssh_keys) == 0 ? 0 : 1
}

locals {
  # Empty when no key was supplied, so every use below can be made conditional.
  admin_public_key = var.ssh_public_key == null ? "" : trimspace(var.ssh_public_key)

  # Hetzner-managed keys installed on the "root" user of every node.
  node_ssh_keys = concat(hcloud_ssh_key.admin[*].id, var.ssh_keys)

  # Public key material of the pre-existing keys selected by `var.ssh_keys`.
  # Entries may be names, IDs or fingerprints, so all three are matched.
  existing_public_keys = [
    for key in try(data.hcloud_ssh_keys.project[0].ssh_keys, []) :
    trimspace(key.public_key)
    if(
      contains(var.ssh_keys, key.name) ||
      contains(var.ssh_keys, tostring(key.id)) ||
      contains(var.ssh_keys, key.fingerprint)
    )
  ]

  # Every key the operator may hold: their own public key plus the project keys
  # they asked for. Empty entries are dropped so cloud-init stays well-formed.
  admin_authorized_keys = compact(concat([local.admin_public_key], local.existing_public_keys))

  # Keys authorised for the "cluster" user, rendered into cloud-init.
  master_authorized_keys = concat(
    local.admin_authorized_keys,
    [trimspace(tls_private_key.master_node.public_key_openssh)],
  )

  worker_authorized_keys = concat(
    local.admin_authorized_keys,
    [trimspace(tls_private_key.worker_node.public_key_openssh)],
  )
}
