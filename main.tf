# Network
resource "hcloud_network" "private_network" {
  name     = "kubernetes-cluster"
  ip_range = var.private_network_ip_range
  labels   = var.default_labels
}

resource "hcloud_network_subnet" "private_network_subnet" {
  type         = var.private_network_type
  network_id   = hcloud_network.private_network.id
  network_zone = var.private_network_zone
  ip_range     = var.private_network_subnet_ip_range
}

# Placement Groups
# A Hetzner placement group holds at most ten servers, so anything larger is
# spread over as many groups as it needs. One group for the whole cluster fails
# at apply time with "placement_group_full" on the eleventh node.
resource "hcloud_placement_group" "kubernetes_placement_group" {
  count  = local.placement_group_count
  name   = "kubernetes-placement-group-${count.index}"
  type   = "spread"
  labels = var.default_labels
}

# Join token shared by every node. k3s otherwise generates a random token per
# server, which leaves the servers of an HA control plane unable to join each
# other. Handing the same token to the agents also removes the need for them to
# SSH into a master and read the node-token off disk.
resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

locals {
  total_nodes      = var.master_nodes_number + var.worker_nodes_number
  ha_control_plane = var.master_nodes_number > 1

  # Hard limit of the Hetzner API, not a tunable.
  placement_group_capacity = 10
  placement_group_count    = var.use_placement_group ? ceil(local.total_nodes / local.placement_group_capacity) : 0

  subnet_host_count = pow(2, 32 - tonumber(split("/", var.private_network_subnet_ip_range)[1]))

  # Private addresses are assigned explicitly instead of being read back off the
  # servers. The master's own cloud-init needs the address the master resource
  # produces, and reading it from the resource itself is a dependency cycle.
  # Host 1 of the subnet is the first master; workers continue after the masters.
  master_node_private_ips = [
    for i in range(var.master_nodes_number) :
    cidrhost(var.private_network_subnet_ip_range, i + 1)
  ]

  worker_node_private_ips = [
    for i in range(var.worker_nodes_number) :
    cidrhost(var.private_network_subnet_ip_range, var.master_nodes_number + i + 1)
  ]

  # Taken from the far end of the subnet, well clear of the node addresses which
  # are handed out from the start of the range.
  control_plane_lb_private_ip = cidrhost(var.private_network_subnet_ip_range, floor(local.subnet_host_count) - 2)

  use_control_plane_lb = local.ha_control_plane && var.use_control_plane_load_balancer

  # What the agents join through. With several masters that is the load
  # balancer, so losing one master does not strand the workers; with a single
  # master there is nothing to balance.
  control_plane_endpoint = local.use_control_plane_lb ? local.control_plane_lb_private_ip : local.master_node_private_ips[0]

  # Roles are labelled so the load balancer can select its targets by label
  # instead of by server ID. See the comment on hcloud_load_balancer_target.
  master_labels = merge(var.default_labels, { role = "master" })
  worker_labels = merge(var.default_labels, { role = "worker" })

  master_label_selector = join(",", [
    for k, v in local.master_labels : "${k}=${v}" if v != ""
  ])

  # Splat rather than an index, so the expression stays valid when the load
  # balancer is not created at all.
  control_plane_lb_public_ips = var.control_plane_load_balancer_public ? hcloud_load_balancer.control_plane[*].ipv4 : []

  master_tls_sans = concat(
    local.use_control_plane_lb ? [local.control_plane_lb_private_ip] : [],
    local.control_plane_lb_public_ips,
  )
}

# Both limits below depend on several variables at once, which a variable
# validation cannot express. They are warnings rather than errors: the server
# limit is a quota that Hetzner raises on request.
check "cluster_fits_in_subnet" {
  assert {
    condition = local.total_nodes + 1 <= floor(local.subnet_host_count) - 3
    error_message = format(
      "%d nodes plus the control plane load balancer do not fit in %s. Widen private_network_subnet_ip_range.",
      local.total_nodes,
      var.private_network_subnet_ip_range,
    )
  }
}

check "servers_per_network_limit" {
  assert {
    condition = local.total_nodes <= 100
    error_message = format(
      "This cluster is %d servers. Hetzner attaches at most 100 servers to a single network, and a project's server quota starts far below that, so check both with support before applying.",
      local.total_nodes,
    )
  }
}
