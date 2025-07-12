locals {
  db_user     = data.google_secret_manager_secret_version.db_user.secret_data
  db_password = data.google_secret_manager_secret_version.db_password.secret_data
}