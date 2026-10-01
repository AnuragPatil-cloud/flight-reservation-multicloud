variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "network_name" {
  type = string
}

variable "admin_cidr" {
  type = string
}

variable "enable_iap_ssh" {
  type = bool
}

variable "gke_master_cidr" {
  type = string
}

variable "gke_node_tag" {
  type = string
}

variable "internal_cidrs" {
  type = list(string)
}
