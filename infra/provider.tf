provider "google" {
  credentials = file("terraform-serviceacc-key.json")
  project     = "spider-107124046-onsite"
  region      = var.region
  zone        = var.zone
}