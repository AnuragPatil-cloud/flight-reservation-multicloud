variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "labels" {
  type = map(string)
}

variable "writer_member" {
  type        = string
  description = "IAM member that may push images, e.g. serviceAccount:..."
}

variable "reader_member" {
  type        = string
  description = "IAM member that may pull images, e.g. serviceAccount:..."
}
