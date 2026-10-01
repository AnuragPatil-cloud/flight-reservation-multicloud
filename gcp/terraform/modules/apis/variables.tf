variable "project_id" {
  type = string
}

variable "services" {
  type        = list(string)
  description = "Google APIs to enable"
}
