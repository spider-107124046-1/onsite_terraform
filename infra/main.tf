module "vpc" {
  source                  = "./modules/vpc"
  project_id              = var.project_id
  region                  = var.region
  network_name            = var.network_name
  subnets                 = var.subnets

  ssh_allowed_ip_cidr     = var.ssh_allowed_ip_cidr
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
  source     = "./modules/cloud_storage"
  project_id = var.project_id
  buckets    = var.buckets
}

module "compute_vms" {
  source     = "./modules/compute_vms"
  project_id = var.project_id
  subnet_self_links = module.vpc.subnet_self_links

  instances = var.instances
}
