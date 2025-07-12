variable "project_id" {}
variable "region" {
  default = "asia-south1"
}
variable "cluster_name" {
  default = "spider-web-107124046"
}
variable "node_count" {
  default = 1
}
variable "node_machine_type" {
  default = "e2-micro"
}

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
variable "db_user" {
  default = "CR_auth"
}
variable "db_password" {
  sensitive = true
}

variable "buckets" {
  type = map(object({
    public_access     = bool
    enable_versioning = bool
  }))
}

variable "ssh_allowed_ip_cidr" {
  description = "Your IP address or CIDR block allowed to SSH"
}
