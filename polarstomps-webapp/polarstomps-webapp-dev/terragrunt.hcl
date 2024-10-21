terraform {
  source = "../../modules/polarstomps-webapp"

  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
      "-var-file=${abspath(get_repo_root())}/root.tfvars"
    ]
  }
}

generate "remote_state" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "google" {
  region  = "us-west-1"
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "polarstomps"

    workspaces {
      name = "polarstomps-webapp-dev"
    }
  }
}
EOF
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  public_static_ip = "35.244.144.246"
  dns_zone_name    = "a-bridge-app"
}
