resource "google_sql_database_instance" "default" {
  name             = var.instance_name
  project          = var.project_id
  region           = var.region
  database_version = var.database_version

  settings {
    tier    = var.tier
    edition = var.edition

    ip_configuration {
      ipv4_enabled    = true
      # Enable private IP and authorized networks later
    }
  }
}

resource "google_sql_database" "default" {
  name     = var.db_name
  instance = google_sql_database_instance.default.name
  project  = var.project_id
}

resource "google_sql_user" "default" {
  name     = var.db_user
  instance = google_sql_database_instance.default.name
  password = var.db_password
  project  = var.project_id
}
