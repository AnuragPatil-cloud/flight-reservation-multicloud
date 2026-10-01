output "alert_policy_names" {
  value = {
    jenkins_cpu    = google_monitoring_alert_policy.jenkins_cpu.display_name
    monitoring_cpu = google_monitoring_alert_policy.monitoring_cpu.display_name
    sql_cpu        = google_monitoring_alert_policy.sql_cpu.display_name
    sql_disk       = google_monitoring_alert_policy.sql_disk.display_name
  }
}
