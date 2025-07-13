output "network" {
  description = "The name of the VPC"
  value = google_compute_network.vpc_network.name
}

output "network_self_link" {
  value = google_compute_network.vpc_network.self_link
}

output "subnets" {
  description = "List of subnet names"
  value = [for subnet in google_compute_subnetwork.subnets : subnet.name]
}

output "subnet_self_links" {
  description = "Map of subnet name to subnet self-links"
  value = {
    for name, subnet in google_compute_subnetwork.subnets :
    name => subnet.self_link
  }
}

