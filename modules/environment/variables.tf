variable "project_id" {
  type = string
}

variable "my_ip_address" {
  type = string
}

variable "env" {
  type = string
}

variable "public_static_ip" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.10.20.0/26"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.10.10.0/26"
}

variable "region" {
  type    = string
  default = "us-west1"
}

variable "control_plane_cidr" {
  type    = string
  default = "10.10.30.0/28"
}

variable "pods_range_cidr" {
  type    = string
  default = "192.168.0.0/18"
}

variable "svc_range_cidr" {
  type    = string
  default = "192.168.64.0/18"
}
