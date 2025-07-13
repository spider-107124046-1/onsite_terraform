output "bucket_urls" {
  description = "URLs of each Bucket which can be referenced by name"
  value = {
    for name, res in google_storage_bucket.bucket :
    name => "gs://${res.name}"
  }
}
