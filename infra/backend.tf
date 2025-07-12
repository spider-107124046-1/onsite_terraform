terraform {
  backend "gcs" {
    bucket  = "spider-107124046-terraform-state"
    prefix  = "gke-cluster/${terraform.workspace}"
  }
}
