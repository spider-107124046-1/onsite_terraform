variable "project_id" {}
variable "bucket_name" {}
variable "location" {
  default = "ASIA-SOUTH1"
}
variable "public_access" {
  description = "Whether the bucket should be publicly readable"
  default     = false
}
variable "enable_versioning" {
  default = false
}
