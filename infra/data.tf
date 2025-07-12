data "google_secret_manager_secret_version" "db_user" {
  secret  = "db-user"
  project = var.project_id
  version = "latest"
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = "db-password"
  project = var.project_id
  version = "latest"
}
