terraform {
  source = "../modules/environment"

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
      name = "infra-dev"
    }
  }
}
EOF
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  env                 = "dev"
  public_subnet_cidr  = "10.10.40.0/26"
  private_subnet_cidr = "10.10.50.0/26"
  control_plane_cidr  = "10.10.60.0/28"
}
