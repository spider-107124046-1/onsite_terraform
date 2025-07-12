variable "project_id" {}
variable "network_name" {
  default = "spider-web-107124046-vpc"
}
variable "region" {
  default = "asia-south1"
}
variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name          = string
    ip_cidr_range = string
  }))
}
variable "ssh_allowed_ip_cidr" {
  description = "Your IP address or CIDR block allowed to SSH"
  default     = "0.0.0.0/0"
}