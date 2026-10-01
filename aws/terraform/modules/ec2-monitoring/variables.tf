variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "iam_instance_profile" {
  type = string
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "root_volume_size" {
  type = number
}
