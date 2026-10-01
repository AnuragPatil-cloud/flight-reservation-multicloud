output "instance_id" {
  description = "Numeric instance ID (used by Cloud Monitoring alert filters)"
  value       = google_compute_instance.this.instance_id
}

output "instance_name" {
  value = google_compute_instance.this.name
}

output "public_ip" {
  value = google_compute_address.this.address
}

output "private_ip" {
  value = google_compute_instance.this.network_interface[0].network_ip
}
