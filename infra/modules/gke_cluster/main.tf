resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  # Enable Kubernetes API features
  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  ip_allocation_policy {}
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "default-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  project    = var.project_id

  node_count = var.node_count

  node_config {
    machine_type = var.node_machine_type
    disk_type    = "pd-standard"
    disk_size_gb = 30
    tags         = ["allow-ssh"]

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
