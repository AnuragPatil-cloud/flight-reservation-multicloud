resource "aws_cloudwatch_metric_alarm" "jenkins_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-jenkins-high-cpu"
  alarm_description   = "Jenkins EC2 CPU is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.ec2_cpu_threshold
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    InstanceId = var.jenkins_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "monitoring_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-monitoring-high-cpu"
  alarm_description   = "Monitoring EC2 CPU is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.ec2_cpu_threshold
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    InstanceId = var.monitoring_instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-high-cpu"
  alarm_description   = "RDS CPU is high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-low-storage"
  alarm_description   = "RDS free storage is low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_free_storage_threshold_bytes
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }
}
