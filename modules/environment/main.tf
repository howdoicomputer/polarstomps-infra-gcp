locals {
  vpc_name            = "${var.env}-vpc"
  gke_cluster_name    = "${var.env}-gke-cluster"
  public_subnet_name  = "${var.env}-public-01"
  private_subnet_name = "${var.env}-private-01"
  pods_range_name     = "${var.env}-private-gke-pods"
  svc_range_name      = "${var.env}-private-gke-svc"
}

module "vpc" {
  source  = "terraform-google-modules/network/google//modules/vpc"
  version = "~> 9.0.0"

  project_id   = var.project_id
  network_name = local.vpc_name

  auto_create_subnetworks = false
  shared_vpc_host         = false
  description             = "${var.env} VPC"
  routing_mode            = "GLOBAL"
}

module "subnets" {
  source  = "terraform-google-modules/network/google//modules/subnets"
  version = "~> 9.0.0"

  project_id   = var.project_id
  network_name = module.vpc.network_self_link

  subnets = [
    {
      subnet_name   = local.public_subnet_name
      subnet_ip     = var.public_subnet_cidr
      subnet_region = var.region
      description   = "Public services"
    },
    {
      subnet_name           = local.private_subnet_name
      subnet_ip             = var.private_subnet_cidr
      subnet_region         = var.region
      description           = "Private services"
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    (local.private_subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = var.pods_range_cidr
      },
      {
        range_name    = local.svc_range_name
        ip_cidr_range = var.svc_range_cidr
      }
    ]
  }
}

module "routes" {
  source  = "terraform-google-modules/network/google//modules/routes"
  version = "~> 9.0.0"

  project_id   = var.project_id
  network_name = module.vpc.network_self_link

  routes = [
    # This route opens up egress to the internet for all addresses
    #
    {
      name              = "egress-internet"
      description       = "route to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    }
  ]
}

module "firewall_rules" {
  source  = "terraform-google-modules/network/google//modules/firewall-rules"
  version = "~> 9.0.0"

  project_id   = var.project_id
  network_name = module.vpc.network_self_link

  rules = [{
    name               = "allow-ssh-ingress"
    description        = "let me innnnnnnnnnnn"
    direction          = "INGRESS"
    priority           = 0

    # TODO: This lets me talk to things in the public subnet but, really, it should
    # be locked down a to a bastion host.
    #
    # Also, I could probably use Tailscale as a VPN instead of relying on my home
    # address.
    #
    destination_ranges = [var.public_subnet_cidr]
    source_ranges      = [var.my_ip_address]

    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
  }]
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.env}-router"
  network = local.vpc_name
  region  = var.region

  depends_on = [
    module.vpc
  ]
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.env}-router-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke_cluster.ca_certificate)
}

module "gke_cluster" {
  # The standard k8s module does not support autopilot but autopilot is very cool so we're
  # going to use the beta.
  #
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  version = "~> 33.0"

  project_id = var.project_id

  name                            = local.gke_cluster_name
  region                          = var.region
  regional                        = true
  network                         = module.vpc.network_name

  # Ideally, I should be taking the output of the subnet module and feeding into
  # this one but this works for now.
  #
  subnetwork                      = local.private_subnet_name

  master_ipv4_cidr_block          = var.control_plane_cidr
  ip_range_services               = local.svc_range_name
  ip_range_pods                   = local.pods_range_name
  release_channel                 = "REGULAR"
  enable_vertical_pod_autoscaling = true

  # I'm making the control plane endpoint public so that I can manage it from my
  # couch without needing a bastion host.
  #
  enable_private_endpoint         = false
  enable_private_nodes            = true
  deletion_protection             = false

  network_tags = ["${var.env}-gke"]

  # I don't want the Internet to deploy bitcoin miners onto my cluster.
  #
  master_authorized_networks = [
    {
      cidr_block   = var.my_ip_address
      display_name = "Literally where I live."
    }
  ]

  # There is a race condition where the GKE cluster starts being created before
  # the subnets have finished. This explicit dependency fixes that.
  #
  depends_on = [
    module.subnets
  ]
}
