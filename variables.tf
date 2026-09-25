# Network configuration variables
variable "private_network_ip_range" {
  type        = string
  description = "Private network IP range"
  default     = "10.0.0.0/16"
}

variable "private_network_zone" {
  type        = string
  description = "Private network zone"
  default     = "eu-central"
}

variable "private_network_type" {
  type        = string
  description = "Private network type"
  default     = "cloud"
}

variable "private_network_subnet_ip_range" {
  type        = string
  description = "Private network subnet IP range"
  default     = "10.0.1.0/24"
}

# Kubernetes cluster node configuration variables
variable "k3s_version" {
  type        = string
  description = "Version of k3s which is pinned with kubernetes version"
  default     = "v1.36.4+k3s1"
}

variable "node_image" {
  type        = string
  description = "Kubernetes cluster node image"
  default     = "ubuntu-26.04"
}

# Sized for the default cluster, not for a large one. A master runs the API
# server and, once `master_nodes_number` is above 1, embedded etcd. etcd commits
# every write to disk before acknowledging it, so it is sensitive to the CPU and
# I/O jitter of shared-vCPU instances in a way that most workloads are not: on a
# `cx*` master, raft heartbeats start missing their deadline well before the
# machine looks busy, and leader elections follow. Somewhere around a few dozen
# workers this stops being theoretical. Move the control plane to a dedicated
# vCPU type (`ccx*`) before it gets there; the workers can stay shared.
variable "master_node_type" {
  type        = string
  description = "Master node type. The default suits a small cluster. A control plane serving many workers, or running embedded etcd for an HA setup, wants dedicated vCPUs (`ccx*`) rather than a shared-vCPU type."
  default     = "cx23"
}

variable "worker_node_type" {
  type        = string
  description = "Worker node type"
  default     = "cx23"
}

variable "node_location" {
  type        = string
  description = "Kubernetes cluster node location"
  default     = "fsn1"
}

variable "node_enable_ipv4" {
  type        = bool
  description = "Kubernetes cluster use IPv4 networking"
  default     = true
}

variable "node_enable_ipv6" {
  type        = bool
  description = "Kubernetes cluster use IPv6 networking"
  default     = true
}

variable "ssh_keys" {
  type        = list(string)
  description = "Optional names, IDs or fingerprints of SSH keys that already exist in the Hetzner project. They are installed on the nodes' root user and authorised for the `cluster` user, in addition to `ssh_public_key`."
  default     = []
  nullable    = false
}

variable "worker_nodes_number" {
  type        = number
  description = "Number of worker nodes in Cluster"
  default     = 2

  validation {
    condition     = var.worker_nodes_number >= 0 && floor(var.worker_nodes_number) == var.worker_nodes_number
    error_message = "worker_nodes_number must be a whole number of zero or more."
  }
}

variable "master_nodes_number" {
  type        = number
  description = "Number of master nodes in Cluster. Values above 1 build an HA control plane on embedded etcd, which needs a quorum and therefore an odd number of servers."
  default     = 1

  validation {
    condition     = contains([1, 3, 5, 7], var.master_nodes_number)
    error_message = "master_nodes_number must be 1, 3, 5 or 7. Embedded etcd forms a quorum, so an even number of servers lowers availability instead of raising it, and beyond seven the write latency of the raft log outweighs the redundancy."
  }
}

# Control plane load balancer
variable "control_plane_load_balancer_type" {
  type        = string
  description = "Hetzner load balancer type used for the Kubernetes API."
  default     = "lb11"
}

# Access from outside private network will be configured to specific public worker node address
# when it is configured to false. When this parameter is configured to true the LB Public IP
# can be configured in kubeconfig file
variable "control_plane_load_balancer_public" {
  type        = bool
  description = "Expose the Kubernetes API load balancer on a public address. Off by default: Hetzner firewalls do not apply to load balancers, so a public listener would bypass `kube_api_source_ips`. With it off the load balancer serves the private network only and `kubectl` from outside goes to a master's own public address."
  default     = false
}

# Placement Group
variable "use_placement_group" {
  type        = bool
  description = "If true it uses Placement Groups, which spread nodes over different physical machines so that they are less likely to fail together. A group holds at most ten servers, so a larger cluster is spread over as many groups as it needs."
  default     = true
}

# Firewall configurations
variable "ssh_source_ips" {
  type        = list(string)
  description = "Networks allowed to reach SSH on the nodes. Defaults to the whole internet; narrow it to your own address where you can."
  default     = ["0.0.0.0/0", "::/0"]
}

variable "kube_api_source_ips" {
  type        = list(string)
  description = "Networks allowed to reach the Kubernetes API on port 6443 from outside the cluster. Nodes themselves join over the private network and are always allowed."
  default     = ["0.0.0.0/0", "::/0"]
}

variable "custom_master_firewall_rules" {
  type = list(object({
    direction       = string
    protocol        = string
    port            = optional(string)
    source_ips      = optional(list(string))
    destination_ips = optional(list(string))
    description     = optional(string)
  }))
  description = "Additional firewall rules for the master nodes, applied on top of the defaults (inbound 22, 443, 6443 and outbound TCP to anywhere)."
  default     = []
}

variable "custom_worker_firewall_rules" {
  type = list(object({
    direction       = string
    protocol        = string
    port            = optional(string)
    source_ips      = optional(list(string))
    destination_ips = optional(list(string))
    description     = optional(string)
  }))
  description = "Additional firewall rules for the worker nodes, applied on top of the defaults (inbound 22, 443 and outbound TCP to anywhere)."
  default     = []
}

# SSH keys configuration
# The only key material taken from input is the operator's own public key.
# The key pairs used between the nodes are generated by the module itself.
variable "ssh_public_key" {
  type        = string
  description = "Public SSH key of your own machine. It is uploaded to the Hetzner project and installed on the root and cluster users of every node. Leave unset to rely on `ssh_keys` instead."
  default     = null

  validation {
    condition = (
      var.ssh_public_key == null ||
      trimspace(coalesce(var.ssh_public_key, " ")) == "" ||
      can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp(256|384|521)) ", trimspace(var.ssh_public_key)))
    )
    error_message = "ssh_public_key must be an OpenSSH public key, e.g. the contents of ~/.ssh/id_ed25519.pub, or left unset."
  }
}

variable "ssh_key_algorithm" {
  type        = string
  description = "Algorithm used for the SSH key pair the module generates so the masters can reach the workers. One of RSA, ECDSA, ED25519."
  default     = "ED25519"

  validation {
    condition     = contains(["RSA", "ECDSA", "ED25519"], var.ssh_key_algorithm)
    error_message = "ssh_key_algorithm must be one of RSA, ECDSA, ED25519."
  }
}

variable "ssh_key_rsa_bits" {
  type        = number
  description = "Key size of the generated SSH key pair. Only used when ssh_key_algorithm is RSA."
  default     = 4096
}

variable "ssh_key_ecdsa_curve" {
  type        = string
  description = "Curve of the generated SSH key pair. Only used when ssh_key_algorithm is ECDSA."
  default     = "P384"
}

variable "default_labels" {
  type        = map(string)
  description = "Default labels for resources. Hetzner label keys and values must start and end with an alphanumeric character and may only contain letters, digits, `-`, `_` and `.` (max 63 characters). Values may also be empty."
  default = {
    "Confidentiality" = "C3"
    "Project"         = "hetzner-kubernetes"
  }

  validation {
    condition = alltrue([
      for k in keys(var.default_labels) :
      can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", k))
    ])
    error_message = "Each label key must start and end with an alphanumeric character and may only contain letters, digits, '-', '_' and '.' (max 63 characters)."
  }

  validation {
    condition = alltrue([
      for v in values(var.default_labels) :
      v == "" || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9._-]{0,61}[a-zA-Z0-9])?$", v))
    ])
    error_message = "Each label value must be empty or start and end with an alphanumeric character and may only contain letters, digits, '-', '_' and '.' (max 63 characters). Spaces are not allowed."
  }
}
