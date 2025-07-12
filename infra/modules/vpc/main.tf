resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnets" {
  for_each          = { for subnet in var.subnets : subnet.name => subnet }
  name              = each.value.name
  ip_cidr_range     = each.value.ip_cidr_range
  region            = var.region
  network           = google_compute_network.vpc_network.id
  project           = var.project_id
}

# Allow internal traffic
resource "google_compute_firewall" "allow-internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "all"
    ports    = []
  }

  source_ranges = ["10.0.0.0/8"]
  direction     = "INGRESS"
  priority      = 65534
}

# TODO: Restrict SSH access
resource "google_compute_firewall" "allow-ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.ssh_allowed_ip_cidr]
  target_tags   = ["allow-ssh"]

  direction = "INGRESS"
  priority  = 1000
}