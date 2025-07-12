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
variable "network" {}
variable "subnetwork" {}
