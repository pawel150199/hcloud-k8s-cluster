variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  description = "Public SSH key of your own machine, e.g. file(\"~/.ssh/id_ed25519.pub\")"
}
