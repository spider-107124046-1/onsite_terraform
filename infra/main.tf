module "vpc" {
  source                  = "./modules/vpc"
  project_id              = var.project_id
  region                  = var.region
  network_name            = var.network_name
  subnets                 = var.subnets

  ssh_allowed_ip_cidr     = var.ssh_allowed_ip_cidr
}

module "gke" {
  source             = "./modules/gke_cluster"
  project_id         = var.project_id
  region             = var.region
  cluster_name       = var.cluster_name
  node_count         = var.node_count
  node_machine_type  = var.node_machine_type

  network            = module.vpc.network
  subnetwork         = module.vpc.subnets[0]
}

module "db" {
  source        = "./modules/cloud_sql"
  project_id    = var.project_id
  region        = var.region

  instance_name = var.db_instance_name
  db_name       = var.db_name
  db_user       = local.db_user
  db_password   = local.db_password
}

module "buckets" {
  for_each = var.buckets

  source            = "./modules/cloud_storage"
  project_id        = var.project_id
  bucket_name       = each.key
  public_access     = each.value.public_access
  enable_versioning = each.value.enable_versioning
  location          = var.region
}