locals {
    project_name = "hcloud-k8s"

    # Automatically load configuration from env.yaml file
    env_vars = yamldecode(file("${get_terragrunt_dir()}/env.yaml"))

    terraform_version = ">= 1.5.5"
    hcloud_provider_version = ">= 1.45"
}

generate"terraform" {
    path      = "terraform.tf"
    if_exists = "overwrite"
    contents  = <<EOF
terraform {
    required_version = "${local.terraform_version}"

    required_providers {
        hcloud = {
            source  = "hetznercloud/hcloud"
            version = "${local.hcloud_provider_version}"
        }
    }
}
EOF
}

generate "locals" {
    path        = "configuration.tf"
    if_exists   = "overwrite_terragrunt"
    contents = <<EOF
locals {
    env_vars = yamldecode(file("${get_terragrunt_dir()}/env.yaml"))
}
EOF
}

generate "provider" {
    path       = "provider.tf"
    if_exists  = "overwrite_terragrunt"
    contents   = <<EOF
provider "hcloud" {
    token = local.env_vars.hcloud_token
}
EOF
}

remote_state {
    backend = "s3"
    config = {
        encrypt        = true
        bucket         = "hetzner-k8s-remote-state"
        key            = "${path_relative_to_include()}/terraform.tfstate"
        region         = "eu-central-1"
        dynamodb_table = "terraform-locks"
    }

    generate = {
        path = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }
}
