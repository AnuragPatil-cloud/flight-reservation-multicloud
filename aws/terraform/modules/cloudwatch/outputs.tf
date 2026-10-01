output "jenkins_cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.jenkins_cpu.alarm_name
}

output "monitoring_cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.monitoring_cpu.alarm_name
}

output "rds_cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
}

output "rds_free_storage_alarm_name" {
  value = aws_cloudwatch_metric_alarm.rds_free_storage.alarm_name
}
