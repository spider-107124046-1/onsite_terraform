provider "google" {
  credentials = file("terraform-serviceacc-key.json")
  project     = "spider-107124046-onsite"
  region      = "asia-south1"
  zone        = "asia-south1-b"
}