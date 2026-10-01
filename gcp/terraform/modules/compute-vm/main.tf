# Static external IP so the address survives stop/start
resource "google_compute_address" "this" {
  name         = "${var.project_name}-${var.environment}-${var.role}-ip"
  region       = var.region
  address_type = "EXTERNAL"
}

resource "google_compute_instance" "this" {
  name         = "${var.project_name}-${var.environment}-${var.role}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.role] # matched by the firewall rules
  labels       = merge(var.labels, { role = var.role })

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.boot_disk_size
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    access_config {
      nat_ip = google_compute_address.this.address
    }
  }

  # No service account keys anywhere: the VM authenticates as this service account.
  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = var.startup_script
  }
}
