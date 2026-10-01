module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
}

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  admin_cidr   = var.admin_cidr
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

module "jenkins" {
  source = "./modules/ec2-jenkins"

  project_name          = var.project_name
  environment           = var.environment
  subnet_id             = module.vpc.public_subnet_ids[0]
  security_group_id     = module.security_groups.jenkins_sg_id
  iam_instance_profile  = module.iam.jenkins_instance_profile_name
  key_name              = var.key_name
  instance_type         = var.ec2_instance_type
  root_volume_size      = var.jenkins_volume_size

  depends_on = [module.iam]
}

module "monitoring" {
  source = "./modules/ec2-monitoring"

  project_name          = var.project_name
  environment           = var.environment
  subnet_id             = module.vpc.public_subnet_ids[1]
  security_group_id     = module.security_groups.monitoring_sg_id
  iam_instance_profile  = module.iam.monitoring_instance_profile_name
  key_name              = var.key_name
  instance_type         = var.ec2_instance_type
  root_volume_size      = var.monitoring_volume_size

  depends_on = [module.iam]
}

module "eks" {
  source = "./modules/eks"

  project_name             = var.project_name
  environment              = var.environment
  private_subnet_ids       = module.vpc.private_subnet_ids
  monitoring_sg_id         = module.security_groups.monitoring_sg_id
  monitoring_role_arn      = module.iam.monitoring_role_arn
  cluster_role_arn         = module.iam.eks_cluster_role_arn
  node_role_arn            = module.iam.eks_node_role_arn
  node_instance_type       = var.eks_node_instance_type
  desired_nodes            = var.eks_desired_nodes
  min_nodes                = var.eks_min_nodes
  max_nodes                = var.eks_max_nodes

  depends_on = [module.iam]
}

module "rds" {
  source = "./modules/rds"

  project_name             = var.project_name
  environment              = var.environment
  database_subnet_ids      = module.vpc.database_subnet_ids
  security_group_id        = module.security_groups.rds_sg_id
  instance_class           = var.rds_instance_class
  engine_version           = var.rds_engine_version
  database_name            = var.rds_database_name
  username                 = var.rds_username
  password                 = var.rds_password
  backup_retention_days    = var.rds_backup_retention_days
}

module "s3" {
  source = "./modules/s3"

  project_name     = var.project_name
  environment      = var.environment
  bucket_prefix    = var.s3_bucket_prefix
}

module "ecr" {
  source = "./modules/ecr"

  repositories = var.ecr_repositories
  project_name = var.project_name
  environment  = var.environment
}

module "sns" {
  source = "./modules/sns"

  project_name = var.project_name
  environment  = var.environment
  topic_name   = var.sns_topic_name
  alert_email  = var.alert_email
}

module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name                    = var.project_name
  environment                     = var.environment
  jenkins_instance_id             = module.jenkins.instance_id
  monitoring_instance_id           = module.monitoring.instance_id
  rds_instance_identifier          = module.rds.instance_identifier
  sns_topic_arn                    = module.sns.topic_arn
  ec2_cpu_threshold                = var.ec2_cpu_threshold
  rds_cpu_threshold                = var.rds_cpu_threshold
  rds_free_storage_threshold_bytes = var.rds_free_storage_threshold_bytes
}
