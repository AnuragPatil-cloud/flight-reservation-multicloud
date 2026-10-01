variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "network_self_link" {
  type = string
}

variable "database_version" {
  type = string
}

variable "tier" {
  type = string
}

variable "disk_size" {
  type = number
}

variable "disk_autoresize_limit" {
  type = number
}

variable "backup_retention_days" {
  type = number
}

variable "deletion_protection" {
  type = bool
}

variable "database_names" {
  type = list(string)
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "labels" {
  type = map(string)
}
