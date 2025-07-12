resource "google_storage_bucket" "bucket" {
  name          = var.bucket_name
  project       = var.project_id
  location      = var.location
  force_destroy = false # if true, allows deletion even if not empty

  versioning {
    enabled = var.enable_versioning
  }

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "public" {
  count  = var.public_access ? 1 : 0
  bucket = google_storage_bucket.bucket.name

  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
