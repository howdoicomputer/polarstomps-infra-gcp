output "vpc_network_name" {
  value = module.vpc.network_name
}

output "vpc_network_id" {
  value = module.vpc.network_id
}

output "vpc_network_subnets" {
  value = module.subnets.subnets
}

output "gke_cluster_name" {
  value     = module.gke_cluster.name
  sensitive = true
}

output "gke_cluster_endpoint" {
  value     = module.gke_cluster.endpoint
  sensitive = true
}
