variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "database_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "database_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "backup_retention_days" {
  type = number
}
