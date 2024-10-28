variable "dns_zone_name" {
  type    = string
  default = "a-bridge-app"
}

variable "project_id" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "redis_version" {
  type    = string
  default = "REDIS_7_2"
}

variable "associate_dns_record" {
  type    = bool
  default = false
}
