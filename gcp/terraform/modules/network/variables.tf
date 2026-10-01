variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "vm_subnet_cidr" {
  type = string
}

variable "gke_subnet_cidr" {
  type = string
}

variable "gke_pods_cidr" {
  type = string
}

variable "gke_services_cidr" {
  type = string
}

variable "psa_prefix_length" {
  type = number
}
