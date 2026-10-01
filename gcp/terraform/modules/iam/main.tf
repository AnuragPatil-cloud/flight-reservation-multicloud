resource "google_service_account" "jenkins" {
  account_id   = "${var.sa_prefix}-${var.environment}-jenkins"
  display_name = "Jenkins VM (${var.environment})"
}

resource "google_service_account" "monitoring" {
  account_id   = "${var.sa_prefix}-${var.environment}-monitoring"
  display_name = "Monitoring/admin VM (${var.environment})"
}

resource "google_service_account" "gke_nodes" {
  account_id   = "${var.sa_prefix}-${var.environment}-gke-nodes"
  display_name = "GKE nodes (${var.environment})"
}

locals {
  # Artifact Registry access is granted on the repository itself (see the artifact-registry module).
  jenkins_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]

  monitoring_roles = [
    "roles/container.admin",
    "roles/cloudsql.viewer",
    "roles/monitoring.viewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]

  gke_node_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/autoscaling.metricsWriter",
  ]
}

resource "google_project_iam_member" "jenkins" {
  for_each = toset(local.jenkins_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.jenkins.email}"
}

resource "google_project_iam_member" "monitoring" {
  for_each = toset(local.monitoring_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.monitoring.email}"
}

resource "google_project_iam_member" "gke_nodes" {
  for_each = toset(local.gke_node_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
