output "jenkins_service_account_email" {
  value = google_service_account.jenkins.email
}

output "monitoring_service_account_email" {
  value = google_service_account.monitoring.email
}

output "gke_nodes_service_account_email" {
  value = google_service_account.gke_nodes.email
}
