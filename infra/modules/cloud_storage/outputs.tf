output "bucket_name" {
  value = google_storage_bucket.bucket.name
}

output "bucket_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.bucket.name}"
}
