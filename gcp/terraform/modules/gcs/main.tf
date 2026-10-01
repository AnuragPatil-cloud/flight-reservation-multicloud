resource "google_storage_bucket" "this" {
  # Bucket names are global; the project ID keeps this one unique.
  name          = "${var.project_id}-${var.project_name}-${var.environment}-files"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = false
  labels        = var.labels

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  # Keep the last few versions of each object rather than every version forever
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }
}
