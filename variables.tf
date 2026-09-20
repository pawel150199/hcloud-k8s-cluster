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
variable "node_image" {
  type        = string
  description = "Kubernetes cluster node image"
  default     = "ubuntu-24.04"
}

variable "node_type" {
  type        = string
  description = "Kubernetes cluster node type"
  default     = "cax11"
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

variable "master_node_ip" {
  type        = string
  description = "Kubernetes cluster master node ip"
  default     = "10.0.1.1"
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH keys"
  default     = null
}

variable "worker_nodes_number" {
  type        = number
  description = "Number of worker nodes in Cluster"
  default     = 2
}

variable "master_nodes_number" {
  type        = number
  description = "Number of master nodes in Cluster"
  default     = 1
}

# SSH keys configuration
variable "worker_nodes_ssh_pub_key" {
  type        = string
  description = "Public SSH key deployed to worker nodes"
  default     = null
}

variable "worker_nodes_ssh_priv_key" {
  type        = string
  description = "Private SSH key used by master to reach worker nodes"
  default     = null
}

variable "master_nodes_ssh_pub_key" {
  type        = string
  description = "Public SSH key deployed to master nodes"
  default     = null
}
