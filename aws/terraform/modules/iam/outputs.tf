output "jenkins_instance_profile_name" {
  value = aws_iam_instance_profile.jenkins.name
}

output "monitoring_instance_profile_name" {
  value = aws_iam_instance_profile.monitoring.name
}

output "eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  value = aws_iam_role.eks_nodes.arn
}

output "monitoring_role_arn" {
  value = aws_iam_role.monitoring.arn
}
