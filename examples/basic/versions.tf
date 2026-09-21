terraform {
  required_version = ">= 1.15.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.69.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}
