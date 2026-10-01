locals {
  pods_range_name     = "pods"
  services_range_name = "services"
}

resource "google_compute_network" "this" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Jenkins and monitoring/admin VMs (they get external IPs, so this is the "public" subnet)
resource "google_compute_subnetwork" "vm" {
  name                     = "${var.project_name}-${var.environment}-vm-subnet"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.vm_subnet_cidr
  private_ip_google_access = true
}

# Private GKE nodes; Pods and Services use secondary ranges (VPC-native cluster)
resource "google_compute_subnetwork" "gke" {
  name                     = "${var.project_name}-${var.environment}-gke-subnet"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.gke_subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = local.pods_range_name
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = local.services_range_name
    ip_cidr_range = var.gke_services_cidr
  }
}

# Outbound internet for private GKE nodes (image pulls from GitHub/Quay/Docker Hub, Argo CD -> GitHub)
resource "google_compute_router" "this" {
  name    = "${var.project_name}-${var.environment}-router"
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  name                               = "${var.project_name}-${var.environment}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Private Service Access: lets Cloud SQL get a private IP inside this VPC
# (keeps the database off the public internet, reachable only from inside the VPC)
resource "google_compute_global_address" "psa" {
  name          = "${var.project_name}-${var.environment}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.psa_prefix_length
  network       = google_compute_network.this.id
}

resource "google_service_networking_connection" "psa" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.psa.name]

  # Avoids the well-known "producer services are still using this connection"
  # error on terraform destroy; the peering is removed with the VPC.
  deletion_policy = "ABANDON"
}
