output "instance_connection_name" {
  value = google_sql_database_instance.default.connection_name
}

output "public_ip" {
  value = google_sql_database_instance.default.ip_address[0].ip_address
}