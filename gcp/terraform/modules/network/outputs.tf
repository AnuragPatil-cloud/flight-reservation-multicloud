output "network_name" {
  value = google_compute_network.this.name
}

output "network_self_link" {
  value = google_compute_network.this.self_link
}

output "vm_subnet_self_link" {
  value = google_compute_subnetwork.vm.self_link
}

output "gke_subnet_self_link" {
  value = google_compute_subnetwork.gke.self_link
}

output "pods_range_name" {
  value = local.pods_range_name
}

output "services_range_name" {
  value = local.services_range_name
}

output "private_vpc_connection_id" {
  value = google_service_networking_connection.psa.id
}
