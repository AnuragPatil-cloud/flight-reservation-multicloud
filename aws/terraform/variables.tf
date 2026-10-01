variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "flight-reservation"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Two availability zones"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private EKS subnet CIDRs"
}

variable "database_subnet_cidrs" {
  type        = list(string)
  description = "Private RDS subnet CIDRs"
}

variable "admin_cidr" {
  type        = string
  description = "Your public IP in CIDR notation, for example 49.37.123.45/32"
}

variable "key_name" {
  type        = string
  description = "Existing AWS EC2 key pair name"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type for Jenkins and monitoring"
  default     = "c7i-flex.large"
}

variable "jenkins_volume_size" {
  type        = number
  description = "Jenkins root volume size in GiB"
  default     = 40
}

variable "monitoring_volume_size" {
  type        = number
  description = "Monitoring VM root volume size in GiB"
  default     = 40
}

variable "eks_node_instance_type" {
  type        = string
  description = "EKS managed node instance type"
  default     = "c7i-flex.large"
}

variable "eks_desired_nodes" {
  type        = number
  default     = 2
}

variable "eks_min_nodes" {
  type        = number
  default     = 2
}

variable "eks_max_nodes" {
  type        = number
  default     = 2
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "rds_engine_version" {
  type        = string
  default     = "10.11"
}

variable "rds_database_name" {
  type        = string
  default     = "flightdb"
}

variable "rds_username" {
  type        = string
  default     = "flightadmin"
}

variable "rds_password" {
  type        = string
  sensitive   = true
}

variable "rds_backup_retention_days" {
  type        = number
  default     = 1
}

variable "s3_bucket_prefix" {
  type        = string
  default     = "flight-reservation-dev-files-"
}

variable "ecr_repositories" {
  type = list(string)
}

variable "sns_topic_name" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "ec2_cpu_threshold" {
  type    = number
  default = 80
}

variable "rds_cpu_threshold" {
  type    = number
  default = 80
}

variable "rds_free_storage_threshold_bytes" {
  type    = number
  default = 5368709120
}
