# One Docker repository holding the three images: reservation, checkin, frontend.
resource "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = "${var.project_name}-${var.environment}"
  description   = "Docker images for ${var.project_name} (${var.environment})"
  format        = "DOCKER"
  labels        = var.labels

  docker_config {
    immutable_tags = false
  }
}

# Jenkins pushes images
resource "google_artifact_registry_repository_iam_member" "writer" {
  project    = google_artifact_registry_repository.this.project
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.writer"
  member     = var.writer_member
}

# GKE nodes pull images
resource "google_artifact_registry_repository_iam_member" "reader" {
  project    = google_artifact_registry_repository.this.project
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = var.reader_member
}
