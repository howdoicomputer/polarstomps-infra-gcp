# This module covers ancillary infrastructure for the Polarstomps webapp.
#
# Currently doesn't have a hard dependency on core infrastructure (k8s, vpc)
# as it consumes precreated resources (DNS records).
#
# The k8s manifest for the app itself will create some cloud resources:
# (ssl cert, load balancer, etc)
#

# The DNS zone was created based off of a manual purchase process so we
# query it out here.
#
data "google_dns_managed_zone" "dns_zone" {
  name    = var.dns_zone_name
  project = var.project_id
}

# There is a manually created static IP address that the Polarstomps app
# assumes during k8s deployment. This takes that address and creates an
# A record for our site.
#
resource "google_dns_record_set" "frontend" {
  project = var.project_id
  name    = data.google_dns_managed_zone.dns_zone.dns_name
  type    = "A"
  ttl     = 300

  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas      = [var.public_static_ip]
}
