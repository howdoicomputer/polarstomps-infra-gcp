# This module covers ancillary infrastructure for the Polarstomps webapp.
#
# Currently doesn't have a hard dependency on core infrastructure (k8s, vpc)
# as it consumes precreated resources (DNS records).
#
# The k8s manifest for the app itself will create some cloud resources:
# (ssl cert, load balancer, etc)
#
locals {
  redis_name      = "infra-${var.env}-polarstomps-redis"
  addr_name       = "infra-${var.env}-polarstomps-addr"
  redis_full_name = "projects/${var.project_id}/locations/${var.region}/clusters/${local.redis_name}"
}

# This address will be the external address that is grabbed by
# Kubernetes and associated with an external load balancer.
#
resource "google_compute_global_address" "external" {
  project = var.project_id
  name    = local.addr_name
}

# The DNS zone was created based off of a manual purchase process so we
# query it out here.
#
data "google_dns_managed_zone" "dns_zone" {
  count   = var.associate_dns_record ? 1 : 0
  name    = var.dns_zone_name
  project = var.project_id
}

# There is a manually created static IP address that the Polarstomps app
# assumes during k8s deployment. This takes that address and creates an
# A record for our site.
#
resource "google_dns_record_set" "frontend" {
  count   = var.associate_dns_record ? 1 : 0
  project = var.project_id
  name    = data.google_dns_managed_zone.dns_zone[0].dns_name
  type    = "A"
  ttl     = 300

  managed_zone = data.google_dns_managed_zone.dns_zone[0].name
  rrdatas      = [google_compute_global_address.external.address]
}

# Let's query out the remote state for the environment we're deploying into
#
data "terraform_remote_state" "vpc" {
  backend = "remote"

  config = {
    organization = "polarstomps"

    workspaces = {
      name = "infra-${var.env}"
    }
  }
}

module "redis" {
  source  = "terraform-google-modules/memorystore/google"
  version = "~> 11.0"

  name = local.redis_name

  project                 = var.project_id
  region                  = var.region
  enable_apis             = true
  auth_enabled            = true
  transit_encryption_mode = "DISABLED"
  authorized_network      = data.terraform_remote_state.vpc.outputs.vpc_network_id
  memory_size_gb          = 1
  redis_version           = var.redis_version
}

# Create a namespace for polarstomps resources
#
resource "kubernetes_namespace" "polarstomps" {
  metadata {
    name = "polarstomps"
  }
}

# Create a ConfigMap to store Redis conn details
#
resource "kubernetes_config_map" "redis" {
  metadata {
    name      = "redis"
    namespace = "polarstomps"
  }

  data = {
    redis_host = module.redis.host
    redis_port = module.redis.port
  }

  depends_on = [
    kubernetes_namespace.polarstomps
  ]
}

# Create a secret for connecting to Redis
#
resource "kubernetes_secret" "redis_auth" {
  metadata {
    name      = "redis-auth"
    namespace = "polarstomps"
  }

  data = {
    auth = module.redis.auth_string
  }

  depends_on = [
    kubernetes_namespace.polarstomps
  ]
}

# NOTE: The below IAM serviceaccount and role binding are NOT used
# this is because setting up IAM auth for Redis is a pain and will be
# done later. This is just to demo a role binding.
#
# Create a service account for Polarstomps.
#
resource "google_service_account" "polarstomps" {
  project      = var.project_id
  account_id   = "infra-${var.env}-polarstomps"
  display_name = "infra-${var.env}-polarstomps"
}

# Then subsequently bind a dbConnectionUser role to it so that
# it can connect to the redis instance.
#
module "projects_iam_bindings" {
  source  = "terraform-google-modules/iam/google//modules/projects_iam"
  version = "~> 8.0"

  projects = [var.project_id]

  # The authoritative mode will overwrite any existing bindings.
  #
  mode = "authoritative"

  conditional_bindings = [
    {
      role        = "roles/redis.dbConnectionUser"
      title       = "${local.redis_name}-conn"
      description = "Connection accesss to Polarstomps ${var.env} redis instance."
      expression  = "resource.name == '${local.redis_full_name}'"
      members     = ["serviceAccount:${google_service_account.polarstomps.email}"]
    }
  ]
}
