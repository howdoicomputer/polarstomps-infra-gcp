output "redis_id" {
  value = module.redis.id
}

output "redis_host" {
  value = module.redis.host
}

output "redis_region" {
  value = module.redis.region
}

output "redis_current_location_id" {
  value = module.redis.current_location_id
}

output "redis_auth_string" {
  value     = module.redis.auth_string
  sensitive = true
}

output "redis_env_vars" {
  value = module.redis.env_vars
}

output "external_address" {
  value = google_compute_global_address.external.address
}
