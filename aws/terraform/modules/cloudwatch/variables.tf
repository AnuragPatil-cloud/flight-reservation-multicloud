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

variable "rds_instance_identifier" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "ec2_cpu_threshold" {
  type = number
}

variable "rds_cpu_threshold" {
  type = number
}

variable "rds_free_storage_threshold_bytes" {
  type = number
}
