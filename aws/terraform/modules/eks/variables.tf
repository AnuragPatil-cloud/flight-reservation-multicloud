variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "monitoring_sg_id" {
  type = string
}

variable "monitoring_role_arn" {
  type = string
}

variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "node_instance_type" {
  type = string
}

variable "desired_nodes" {
  type = number
}

variable "min_nodes" {
  type = number
}

variable "max_nodes" {
  type = number
}
