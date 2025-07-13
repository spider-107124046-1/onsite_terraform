variable "project_id" {}

variable "subnet_self_links" {
  description = "Map of subnet name to subnet self-link"
  type        = map(string)
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
