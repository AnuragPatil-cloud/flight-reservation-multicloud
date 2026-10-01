variable "project_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "zone" {
  type = string
}

variable "network_self_link" {
  type = string
}

variable "subnetwork_self_link" {
  type = string
}

variable "pods_range_name" {
  type = string
}

variable "services_range_name" {
  type = string
}

variable "master_cidr" {
  type = string
}

variable "authorized_networks" {
  type = list(object({
    name = string
    cidr = string
  }))
  description = "Ranges allowed to reach the private control plane endpoint"
}

variable "node_machine_type" {
  type = string
}

variable "node_count" {
  type = number
}

variable "node_disk_size" {
  type = number
}

variable "node_service_account_email" {
  type = string
}

variable "node_tag" {
  type = string
}

variable "release_channel" {
  type = string
}

variable "deletion_protection" {
  type = bool
}

variable "labels" {
  type = map(string)
}
