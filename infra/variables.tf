variable "project_id" {}
variable "region" {}
variable "zone" {}

variable "network_name" {
  default = "spider-web-107124046-vpc"
}
variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name          = string
    ip_cidr_range = string
  }))
}

variable "db_instance_name" {
  default = "spider-107124046-onsite-db"
}
variable "db_name" {
  default = "classroom"
}

variable "buckets" {
  type = map(object({
    public_access     = bool
    enable_versioning = bool
    location          = string
  }))
}

variable "instances" {
  description = "Map of instance configurations"
  type = map(object({
    name         = string
    machine_type = string
    zone         = string
    subnetwork   = string
    tags         = list(string)
    metadata     = map(string)
    boot_disk = object({
      initialize_params = object({
        image = string
        size  = number
        type  = string
      })
    })
  }))
}

variable "ssh_allowed_ip_cidr" {
  description = "Your IP address or CIDR block allowed to SSH"
}
