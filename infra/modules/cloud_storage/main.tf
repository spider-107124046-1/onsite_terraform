resource "google_storage_bucket" "bucket" {
  for_each      = var.buckets

  name          = each.key
  project       = var.project_id
  location      = each.value.location
  force_destroy = false

  versioning {
    enabled = each.value.enable_versioning
  }

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "public" {
  for_each = {
    for k, v in var.buckets : k => v if v.public_access
  }

  bucket = google_storage_bucket.bucket[each.key].name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
