variable "project_id" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "jenkins_instance_id" {
  type = string
}

variable "monitoring_instance_id" {
  type = string
}

variable "sql_instance_name" {
  type = string
}

variable "notification_channel_id" {
  type = string
}

variable "vm_cpu_threshold" {
  type = number
}

variable "sql_cpu_threshold" {
  type = number
}

variable "sql_disk_utilization_threshold" {
  type = number
}
