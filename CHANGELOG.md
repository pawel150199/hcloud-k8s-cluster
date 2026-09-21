# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.1] - 2026-09-22

### Added
 - The module now generates the SSH key pairs used between the nodes
   (`tls_private_key.master_node`, `tls_private_key.worker_node`) instead of
   taking them as input.
 - `ssh_public_key` (required): the public key of your own machine. It is
   uploaded as `hcloud_ssh_key.admin` and installed on the `root` and `cluster`
   users of every node, master and worker alike.
 - `ssh_key_algorithm`, `ssh_key_rsa_bits`, `ssh_key_ecdsa_curve` to control the
   generated key pairs (default `ED25519`).
 - Outputs `master_node_ssh_public_key`, `master_node_ssh_private_key`,
   `worker_node_ssh_public_key`, `worker_node_ssh_private_key` (private ones
   marked `sensitive`).

### Changed
 - **Breaking:** removed `master_nodes_ssh_pub_key`, `worker_nodes_ssh_pub_key`
   and `worker_nodes_ssh_priv_key`. Drop them from your configuration and set
   `ssh_public_key` instead.
 - `ssh_keys` now defaults to `[]` (was `null`) and is optional — it only adds
   SSH keys that already exist in the Hetzner project.
 - Worker nodes now get `ssh_keys` assigned as well; previously only master
   nodes did.
 - Workers use the generated key explicitly
   (`ssh -i /root/.ssh/master_node_key`) and address the master via
   `var.master_node_ip` instead of a hardcoded `10.0.1.1`.
 - New provider requirement: `hashicorp/tls ~> 4.0`.

### Fixed
 - The worker's private key no longer mismatches the public key authorised on
   the master: the key a worker presents is now the counterpart of the master's
   `cluster` key, so fetching the k3s node-token actually works.
 - Comment entries in the worker's cloud-init `runcmd` were written as list
   items (`- # comment`), which YAML parses as `null` and cloud-init rejects
   with `Unable to shellify type NoneType`, aborting the whole join. They are
   plain YAML comments now.
 - The injected private key is indented correctly inside the cloud-init
   `write_files` block scalar, so the file on disk is a valid OpenSSH key.

## [0.1.0] - 2026-09-21

Here we would have the update steps for 0.1.0 for people to follow.

### Added
 - Release of initial version 0.1.0

### Changed
None

### Fixed
None
