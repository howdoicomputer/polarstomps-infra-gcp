terraform {
  source = "../modules/polarstomps-webapp"

  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()

    arguments = [
      "-var-file=${abspath(get_repo_root())}/root.tfvars"
    ]
  }
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  public_static_ip = "CHANGE_ME"
  dns_zone_name    = "CHANGE_ME"
}
