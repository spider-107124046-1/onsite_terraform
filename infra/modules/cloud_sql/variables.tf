variable "project_id" {}
variable "region" {}
variable "instance_name" {}
variable "database_version" {
  default = "POSTGRES_16"
}
variable "tier" {
  default = "db-f1-micro" # cheapest tier (shared core)
}
variable "edition" {
  default = "ENTERPRISE"
}
variable "db_name" {}
variable "db_user" {}
variable "db_password" {}
