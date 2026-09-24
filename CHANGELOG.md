# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.7] - 2026-09-24

### Added
 - `hcloud_firewall.master_kubernetes_firewall` and
   `hcloud_firewall.worker_kubernetes_firewall`, attached to the nodes through
   `firewall_ids`. Previously no firewall resource was attached to any server.
 - Full set of k3s ports, scoped to `var.private_network_ip_range` rather than
   the whole internet: `8472/UDP` (Flannel VXLAN), `10250/TCP` (kubelet API),
   `5001/TCP` (embedded registry mirror) and ICMP on both roles, plus
   `2379-2380/TCP` (embedded etcd, HA control plane) on the masters.
 - `custom_master_firewall_rules` and `custom_worker_firewall_rules` to append
   rules on top of the defaults. Only `direction` and `protocol` are required;
   `port`, `source_ips`, `destination_ips` and `description` are optional, so an
   ICMP rule no longer has to invent a port value.
 - `ssh_source_ips` and `kube_api_source_ips` to narrow who may reach SSH and
   the Kubernetes API. Both default to the whole internet, which keeps the
   previous behaviour, but are worth restricting.
 - `placement_group_strategy` — the placement group referenced this variable
   without it ever being declared.

### Changed
 - **Breaking:** the placement group is now created only when
   `use_placement_group` is `true` (`count = var.use_placement_group ? 1 : 0`).
   Its address moves to `hcloud_placement_group.kubernetes_placement_group[0]`,
   so existing state needs:
   `terraform state mv 'hcloud_placement_group.kubernetes_placement_group' 'hcloud_placement_group.kubernetes_placement_group[0]'`
   Without it Terraform plans a destroy/create of the group, which forces an
   update on every server attached to it.
 - **Breaking:** nodes now have a firewall attached. Traffic that used to reach
   them on any port is filtered from this release on; anything beyond SSH,
   HTTPS, the Kubernetes API and the intra-cluster ports has to be added through
   `custom_*_firewall_rules`.

### Fixed
 - All outbound UDP was blocked. The defaults allowed only `out tcp any`, and
   Hetzner drops every protocol that is not explicitly allowed as soon as one
   outbound rule exists — so DNS (`53/UDP`) and NTP (`123/UDP`) never left the
   node, which breaks image pulls and the k3s install itself. Outbound UDP and
   ICMP are now allowed.
 - `custom_master_firewall_rules` was declared twice in `variables.tf`; the
   second declaration was meant to be `custom_worker_firewall_rules`. The
   duplicate made the whole module fail to validate.
 - Reading `source_ips` off the default rule list failed at plan time with
   *"This object does not have an attribute named source_ips"*. The list mixed
   objects of different shapes, which makes it a tuple, and the outbound rule
   simply had no such attribute — a `!= null` guard cannot catch an attribute
   that is absent rather than null. Every rule now carries the full attribute
   set. Note that `terraform validate` passes on this; only `plan` catches it.
 - Outbound rules never set `destination_ips`, which Hetzner requires for
   `direction = "out"`.
 - `labels` on the placement group referenced a bare `default_labels` instead of
   `var.default_labels`.
 - `examples/basic` passed `node_type`, which no longer exists after the split
   into `master_node_type` and `worker_node_type`, so the example failed to
   validate.

## [0.1.6] - 2026-09-23

### Removed
 - `master_node_ip` and the hardcoded worker private IPs. Hetzner now assigns
   every private address; the workers' cloud-init reads the master's private IP
   off `hcloud_server.master_nodes[0]`, so nothing has to restate it.

### Changed
 - `ssh_public_key` is now **optional** (defaults to `null`). Supplying only
   `ssh_keys` — names or IDs of SSH keys that already exist in the Hetzner
   project — is a valid configuration and no longer raises a validation error.
 - `hcloud_ssh_key.admin` is only created when `ssh_public_key` is set, so no
   empty key is ever uploaded to the Hetzner project.
 - The `cluster` user's `authorized_keys` list in cloud-init is now rendered
   from a list (`yamlencode`), so it holds just the module-generated key when no
   admin key was supplied, instead of an empty entry.

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
