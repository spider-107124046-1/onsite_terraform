variable "project_id" {}

variable "buckets" {
  type = map(object({
    public_access     = bool
    enable_versioning = bool
    location          = string
  }))
}