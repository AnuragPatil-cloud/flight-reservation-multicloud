resource "google_container_cluster" "this" {
  name     = "${var.project_name}-${var.environment}-gke"
  location = var.zone # zonal cluster: one control plane, nodes in one zone

  network    = var.network_self_link
  subnetwork = var.subnetwork_self_link

  networking_mode     = "VPC_NATIVE"
  deletion_protection = var.deletion_protection
  resource_labels     = var.labels

  # Node pool is managed separately below
  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private nodes AND a private control plane endpoint (no public API endpoint):
  # kubectl / helm run from the monitoring/admin VM.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_cidr
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks

      content {
        display_name = cidr_blocks.value.name
        cidr_block   = cidr_blocks.value.cidr
      }
    }
  }

  # Pods can use Google APIs as Kubernetes service accounts (no node-wide credentials)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Control-plane logs in Cloud Logging
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "APISERVER",
      "SCHEDULER",
      "CONTROLLER_MANAGER",
      "WORKLOADS",
    ]
  }

  # Prometheus/Grafana are installed with Helm (kube-prometheus-stack), so Google Managed Prometheus is off
  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = false
    }
  }
}

resource "google_container_node_pool" "this" {
  name       = "${var.project_name}-${var.environment}-gke-nodes"
  cluster    = google_container_cluster.this.name
  location   = var.zone
  node_count = var.node_count

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type    = var.node_machine_type
    disk_size_gb    = var.node_disk_size
    disk_type       = "pd-balanced"
    image_type      = "COS_CONTAINERD"
    service_account = var.node_service_account_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    tags            = [var.node_tag]
    labels          = var.labels

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
