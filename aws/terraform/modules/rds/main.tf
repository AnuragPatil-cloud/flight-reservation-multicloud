resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-rds-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.project_name}-${var.environment}-rds"
  engine                 = "mariadb"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = var.database_name
  username               = var.username
  password               = var.password
  port                   = 3306
  publicly_accessible    = false
  multi_az               = false
  backup_retention_period = var.backup_retention_days
  deletion_protection    = false
  skip_final_snapshot    = true
  apply_immediately      = false
  copy_tags_to_snapshot  = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "${var.project_name}-${var.environment}-rds"
  }
}
