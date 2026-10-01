resource "aws_eks_cluster" "this" {
  name     = "${var.project_name}-${var.environment}-eks"
  role_arn = var.cluster_role_arn
  version  = "1.35"

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-eks"
  }

}

resource "aws_security_group_rule" "monitoring_to_cluster" {
  type                     = "ingress"
  security_group_id        = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  source_security_group_id = var.monitoring_sg_id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Monitoring VM to Kubernetes API"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_access_entry" "monitoring" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.monitoring_role_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "monitoring_admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.monitoring_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-${var.environment}-eks-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.node_instance_type]
  ami_type       = "AL2023_x86_64_STANDARD"
  disk_size      = 40
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.desired_nodes
    min_size     = var.min_nodes
    max_size     = var.max_nodes
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-nodes"
  }

  depends_on = [
    aws_eks_access_entry.monitoring,
    aws_eks_access_policy_association.monitoring_admin
  ]
}
