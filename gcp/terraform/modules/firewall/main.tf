# Jenkins VM: SSH, Jenkins UI and SonarQube - administrator IP only
resource "google_compute_firewall" "jenkins_admin" {
  name          = "${var.project_name}-${var.environment}-allow-jenkins-admin"
  network       = var.network_name
  direction     = "INGRESS"
  priority      = 1000
  description   = "SSH, Jenkins (8080) and SonarQube (9000) from the administrator"
  source_ranges = [var.admin_cidr]
  target_tags   = ["jenkins"]

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "9000"]
  }
}

# Monitoring/admin VM: SSH from the administrator IP only
resource "google_compute_firewall" "monitoring_admin" {
  name          = "${var.project_name}-${var.environment}-allow-monitoring-admin"
  network       = var.network_name
  direction     = "INGRESS"
  priority      = 1000
  description   = "SSH from the administrator"
  source_ranges = [var.admin_cidr]
  target_tags   = ["monitoring"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Optional: SSH through Identity-Aware Proxy (no public exposure of port 22 needed)
resource "google_compute_firewall" "iap_ssh" {
  count = var.enable_iap_ssh ? 1 : 0

  name          = "${var.project_name}-${var.environment}-allow-iap-ssh"
  network       = var.network_name
  direction     = "INGRESS"
  priority      = 1000
  description   = "SSH from Google IAP TCP forwarding"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["jenkins", "monitoring"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Custom-mode VPCs have no default "allow internal" rule
resource "google_compute_firewall" "internal" {
  name          = "${var.project_name}-${var.environment}-allow-internal"
  network       = var.network_name
  direction     = "INGRESS"
  priority      = 1000
  description   = "All traffic between the VM subnet, GKE nodes, Pods and Services"
  source_ranges = var.internal_cidrs

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

# Private GKE: the control plane must reach admission webhooks running on the nodes
# (prometheus-operator uses 8443; other controllers commonly use 9443).
resource "google_compute_firewall" "gke_master_webhooks" {
  name          = "${var.project_name}-${var.environment}-allow-gke-master-webhooks"
  network       = var.network_name
  direction     = "INGRESS"
  priority      = 1000
  description   = "GKE control plane to node webhooks"
  source_ranges = [var.gke_master_cidr]
  target_tags   = [var.gke_node_tag]

  allow {
    protocol = "tcp"
    ports    = ["8443", "9443", "15017"]
  }
}
