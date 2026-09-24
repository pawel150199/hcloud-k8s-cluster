locals {
  default_source_ips = [
    "0.0.0.0/0",
    "::/0"
  ]

  # Intra-cluster traffic. Nodes reach each other over the private network, so
  # these rules are scoped to it instead of the whole internet.
  cluster_source_ips = [var.private_network_ip_range]

  # Every element carries the full attribute set, including the ones it does not
  # use. A list whose objects differ in shape becomes a tuple, and reading an
  # attribute that is merely absent on one element fails at plan time.

  # Ports every k3s node needs from the other nodes, whatever its role.
  # 8472/UDP is the Flannel VXLAN backend k3s uses by default; without it nodes
  # come up Ready but pods on different nodes cannot reach each other.
  common_k3s_cluster_rules = [
    {
      direction       = "in"
      protocol        = "udp"
      port            = "8472"
      source_ips      = local.cluster_source_ips
      destination_ips = null
      description     = "Flannel VXLAN overlay"
    },
    {
      direction       = "in"
      protocol        = "tcp"
      port            = "10250"
      source_ips      = local.cluster_source_ips
      destination_ips = null
      description     = "kubelet API (logs, exec, metrics)"
    },
    {
      direction       = "in"
      protocol        = "tcp"
      port            = "5001"
      source_ips      = local.cluster_source_ips
      destination_ips = null
      description     = "k3s embedded registry mirror (Spegel)"
    },
    {
      direction       = "in"
      protocol        = "icmp"
      port            = null
      source_ips      = local.cluster_source_ips
      destination_ips = null
      description     = "ICMP within the cluster"
    }
  ]

  # Hetzner drops every outbound protocol that is not explicitly allowed as soon
  # as a single outbound rule exists. UDP has to be listed or DNS and NTP break.
  common_egress_rules = [
    {
      direction       = "out"
      protocol        = "tcp"
      port            = "any"
      source_ips      = null
      destination_ips = local.default_source_ips
      description     = "Allow all outbound TCP"
    },
    {
      direction       = "out"
      protocol        = "udp"
      port            = "any"
      source_ips      = null
      destination_ips = local.default_source_ips
      description     = "Allow all outbound UDP (DNS, NTP, VXLAN)"
    },
    {
      direction       = "out"
      protocol        = "icmp"
      port            = null
      source_ips      = null
      destination_ips = local.default_source_ips
      description     = "Allow outbound ICMP"
    }
  ]

  # Master Node
  default_master_kubernetes_firewall_rules = concat(
    [
      {
        direction       = "in"
        protocol        = "tcp"
        port            = "22"
        source_ips      = var.ssh_source_ips
        destination_ips = null
        description     = "SSH"
      },
      {
        direction       = "in"
        protocol        = "tcp"
        port            = "6443"
        source_ips      = var.kube_api_source_ips
        destination_ips = null
        description     = "Kubernetes API server"
      },
      {
        direction       = "in"
        protocol        = "tcp"
        port            = "443"
        source_ips      = local.default_source_ips
        destination_ips = null
        description     = "HTTPS ingress"
      },
      # Only used when several servers form an HA control plane with embedded
      # etcd. Harmless on a single-server cluster, which runs on SQLite.
      {
        direction       = "in"
        protocol        = "tcp"
        port            = "2379-2380"
        source_ips      = local.cluster_source_ips
        destination_ips = null
        description     = "k3s embedded etcd (HA control plane)"
      }
    ],
    local.common_k3s_cluster_rules,
    local.common_egress_rules
  )

  # Worker Node
  default_worker_kubernetes_firewall_rules = concat(
    [
      {
        direction       = "in"
        protocol        = "tcp"
        port            = "22"
        source_ips      = var.ssh_source_ips
        destination_ips = null
        description     = "SSH"
      },
      {
        direction       = "in"
        protocol        = "tcp"
        port            = "443"
        source_ips      = local.default_source_ips
        destination_ips = null
        description     = "HTTPS ingress"
      }
    ],
    local.common_k3s_cluster_rules,
    local.common_egress_rules
  )
}

resource "hcloud_firewall" "master_kubernetes_firewall" {
  name   = "master-node-kubernetes-firewall"
  labels = var.default_labels

  dynamic "rule" {
    for_each = concat(var.custom_master_firewall_rules, local.default_master_kubernetes_firewall_rules)

    content {
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = rule.value.port
      source_ips      = rule.value.source_ips
      destination_ips = rule.value.destination_ips
      description     = rule.value.description
    }
  }
}

resource "hcloud_firewall" "worker_kubernetes_firewall" {
  name   = "worker-node-kubernetes-firewall"
  labels = var.default_labels

  dynamic "rule" {
    for_each = concat(var.custom_worker_firewall_rules, local.default_worker_kubernetes_firewall_rules)

    content {
      direction       = rule.value.direction
      protocol        = rule.value.protocol
      port            = rule.value.port
      source_ips      = rule.value.source_ips
      destination_ips = rule.value.destination_ips
      description     = rule.value.description
    }
  }
}
