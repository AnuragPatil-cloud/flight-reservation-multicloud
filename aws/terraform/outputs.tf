output "vpc_id" {
  value = module.vpc.vpc_id
}

output "jenkins_instance_id" {
  value = module.jenkins.instance_id
}

output "jenkins_public_ip" {
  value = module.jenkins.public_ip
}

output "monitoring_instance_id" {
  value = module.monitoring.instance_id
}

output "monitoring_public_ip" {
  value = module.monitoring.public_ip
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "rds_port" {
  value = module.rds.port
}

output "rds_database_name" {
  value = module.rds.database_name
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "sns_topic_arn" {
  value = module.sns.topic_arn
}
