output "network_name" {
  value = module.network.network_name
}

output "jenkins_instance_name" {
  value = module.jenkins.instance_name
}

output "jenkins_public_ip" {
  value = module.jenkins.public_ip
}

output "monitoring_instance_name" {
  value = module.monitoring.instance_name
}

output "monitoring_public_ip" {
  value = module.monitoring.public_ip
}

output "gke_cluster_name" {
  value = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "Private control plane endpoint - reachable from the monitoring/admin VM only"
  value       = module.gke.cluster_endpoint
}

output "cloudsql_instance_name" {
  value = module.cloudsql.instance_name
}

output "cloudsql_connection_name" {
  value = module.cloudsql.connection_name
}

output "cloudsql_private_ip" {
  description = "Put this in gitops/configmap.yaml (CLOUD_SQL_PRIVATE_IP)"
  value       = module.cloudsql.private_ip_address
}

output "cloudsql_databases" {
  value = module.cloudsql.database_names
}

output "gcs_bucket_name" {
  value = module.gcs.bucket_name
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository ID (AR_REPO in the Jenkinsfile)"
  value       = module.artifact_registry.repository_id
}

output "artifact_registry_url" {
  description = "Image path prefix: <this>/reservation:<tag>, /checkin:<tag>, /frontend:<tag>"
  value       = module.artifact_registry.repository_url
}

output "jenkins_service_account" {
  value = module.iam.jenkins_service_account_email
}

output "monitoring_service_account" {
  value = module.iam.monitoring_service_account_email
}

output "ssh_jenkins" {
  value = "gcloud compute ssh ${module.jenkins.instance_name} --zone ${var.zone} --project ${var.project_id}"
}

output "ssh_monitoring" {
  value = "gcloud compute ssh ${module.monitoring.instance_name} --zone ${var.zone} --project ${var.project_id}"
}

output "gke_get_credentials_command" {
  description = "Run this ON the monitoring/admin VM (the API endpoint is private)"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone ${var.zone} --project ${var.project_id} --internal-ip"
}
