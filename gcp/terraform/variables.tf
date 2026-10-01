# ---------------------------------------------------------------------------
# Project / location
# ---------------------------------------------------------------------------
variable "project_id" {
  type        = string
  description = "GCP project ID (not the project name or number)"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "asia-south1" # Mumbai
}

variable "zone" {
  type        = string
  description = "GCP zone for the VMs and the (zonal) GKE cluster"
  default     = "asia-south1-a"
}

variable "project_name" {
  type        = string
  description = "Project name, used as a prefix for resource names"
  default     = "flight-reservation"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "sa_prefix" {
  type        = string
  description = "Short prefix for service account IDs (they are limited to 30 characters)"
  default     = "fra"
}

variable "deletion_protection" {
  type        = bool
  description = "Protect the GKE cluster and Cloud SQL instance from deletion. Leave false for a dev/demo stack you tear down with terraform destroy."
  default     = false
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "vm_subnet_cidr" {
  type        = string
  description = "Subnet for the Jenkins and monitoring/admin VMs"
  default     = "10.0.1.0/24"
}

variable "gke_subnet_cidr" {
  type        = string
  description = "Primary range of the GKE subnet (nodes)"
  default     = "10.0.11.0/24"
}

variable "gke_pods_cidr" {
  type        = string
  description = "Secondary range for GKE Pods"
  default     = "10.1.0.0/16"
}

variable "gke_services_cidr" {
  type        = string
  description = "Secondary range for GKE Services"
  default     = "10.2.0.0/20"
}

variable "gke_master_cidr" {
  type        = string
  description = "/28 range for the GKE control plane (private endpoint). Must not overlap any other range."
  default     = "172.16.0.0/28"
}

variable "psa_prefix_length" {
  type        = number
  description = "Prefix length of the range reserved for Private Service Access (Cloud SQL private IP)"
  default     = 20
}

variable "admin_cidr" {
  type        = string
  description = "Your public IP in CIDR notation, for example 49.37.123.45/32 (SSH, Jenkins, SonarQube)"
}

variable "enable_iap_ssh" {
  type        = bool
  description = "Also allow SSH through Identity-Aware Proxy (gcloud compute ssh --tunnel-through-iap)"
  default     = true
}

# ---------------------------------------------------------------------------
# VMs
# ---------------------------------------------------------------------------
variable "vm_machine_type" {
  type        = string
  description = "Machine type for the Jenkins and monitoring/admin VMs"
  default     = "e2-standard-2" # 2 vCPU / 8 GiB
}

variable "jenkins_volume_size" {
  type        = number
  description = "Jenkins boot disk size in GiB"
  default     = 40
}

variable "monitoring_volume_size" {
  type        = number
  description = "Monitoring/admin VM boot disk size in GiB"
  default     = 40
}

# ---------------------------------------------------------------------------
# GKE
# ---------------------------------------------------------------------------
variable "gke_node_machine_type" {
  type        = string
  description = "GKE node machine type"
  default     = "e2-standard-2" # 2 vCPU / 8 GiB
}

variable "gke_node_count" {
  type        = number
  description = "Number of GKE worker nodes (zonal cluster, fixed size)"
  default     = 2
}

variable "gke_node_disk_size" {
  type        = number
  description = "GKE node boot disk size in GiB"
  default     = 40
}

variable "gke_release_channel" {
  type        = string
  description = "GKE release channel (RAPID, REGULAR or STABLE). The Kubernetes version follows the channel."
  default     = "REGULAR"
}

# ---------------------------------------------------------------------------
# Cloud SQL for MySQL
# ---------------------------------------------------------------------------
variable "sql_database_version" {
  type        = string
  description = "Cloud SQL engine version. Cloud SQL has no MariaDB; MySQL 8.4 (LTS) is the closest supported engine."
  default     = "MYSQL_8_4"
}

variable "sql_tier" {
  type        = string
  description = "Cloud SQL machine tier. db-f1-micro is cheaper but only 0.6 GB RAM; use db-custom-1-3840 if db-g1-small is rejected."
  default     = "db-g1-small"
}

variable "sql_disk_size" {
  type        = number
  description = "Initial Cloud SQL disk size in GB"
  default     = 20
}

variable "sql_disk_autoresize_limit" {
  type        = number
  description = "Maximum Cloud SQL disk size in GB when autoresize kicks in"
  default     = 100
}

variable "sql_reservation_database" {
  type        = string
  description = "Database used by the reservation service"
  default     = "flightdb"
}

variable "sql_checkin_database" {
  type        = string
  description = "Database used by the check-in service"
  default     = "checkin_db"
}

variable "sql_username" {
  type        = string
  description = "Application database user"
  default     = "flightadmin"
}

variable "sql_password" {
  type        = string
  description = "Application database password"
  sensitive   = true
}

variable "sql_backup_retention_days" {
  type        = number
  description = "Number of automated backups to keep"
  default     = 3
}

# ---------------------------------------------------------------------------
# Alerting
# ---------------------------------------------------------------------------
variable "alert_email" {
  type        = string
  description = "Email address that receives Cloud Monitoring alerts"
}

variable "vm_cpu_threshold" {
  type        = number
  description = "VM CPU utilization alert threshold, as a fraction (0.8 = 80 %)"
  default     = 0.8
}

variable "sql_cpu_threshold" {
  type        = number
  description = "Cloud SQL CPU utilization alert threshold, as a fraction"
  default     = 0.8
}

variable "sql_disk_utilization_threshold" {
  type        = number
  description = "Cloud SQL disk utilization alert threshold, as a fraction"
  default     = 0.85
}
