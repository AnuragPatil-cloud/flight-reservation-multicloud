variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "role" {
  type        = string
  description = "jenkins or monitoring - used in names and as the network tag"
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "service_account_email" {
  type = string
}

variable "boot_disk_size" {
  type = number
}

variable "startup_script" {
  type        = string
  description = "Contents of the bootstrap script"
}

variable "labels" {
  type = map(string)
}
