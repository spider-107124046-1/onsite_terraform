resource "google_compute_instance" "vms" {
  for_each = var.instances

  name         = each.value.name
  machine_type = each.value.machine_type
  zone         = each.value.zone
  project      = var.project_id

  tags     = each.value.tags
  metadata = each.value.metadata

  boot_disk {
    initialize_params {
      image = each.value.boot_disk.initialize_params.image
      size  = each.value.boot_disk.initialize_params.size
      type  = each.value.boot_disk.initialize_params.type
    }
  }

  network_interface {
    subnetwork = var.subnet_self_links[each.value.subnetwork] 
    access_config {}
  }
}
