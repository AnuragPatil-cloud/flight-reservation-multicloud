# Jenkins VM CPU
resource "google_monitoring_alert_policy" "jenkins_cpu" {
  display_name = "${var.project_name}-${var.environment}-jenkins-high-cpu"
  combiner     = "OR"

  conditions {
    display_name = "Jenkins VM CPU utilization above threshold"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND resource.labels.instance_id = \"${var.jenkins_instance_id}\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.vm_cpu_threshold
      duration        = "600s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [var.notification_channel_id]

  documentation {
    mime_type = "text/markdown"
    content   = "Jenkins VM CPU has been above the threshold for 10 minutes. Check running builds and the SonarQube container."
  }
}

# Monitoring/admin VM CPU
resource "google_monitoring_alert_policy" "monitoring_cpu" {
  display_name = "${var.project_name}-${var.environment}-monitoring-high-cpu"
  combiner     = "OR"

  conditions {
    display_name = "Monitoring VM CPU utilization above threshold"

    condition_threshold {
      filter          = "resource.type = \"gce_instance\" AND resource.labels.instance_id = \"${var.monitoring_instance_id}\" AND metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.vm_cpu_threshold
      duration        = "600s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [var.notification_channel_id]

  documentation {
    mime_type = "text/markdown"
    content   = "Monitoring/admin VM CPU has been above the threshold for 10 minutes."
  }
}

# Cloud SQL CPU
resource "google_monitoring_alert_policy" "sql_cpu" {
  display_name = "${var.project_name}-${var.environment}-cloudsql-high-cpu"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL CPU utilization above threshold"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${var.project_id}:${var.sql_instance_name}\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.sql_cpu_threshold
      duration        = "600s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [var.notification_channel_id]

  documentation {
    mime_type = "text/markdown"
    content   = "Cloud SQL CPU has been above the threshold for 10 minutes. Check slow queries and connection counts."
  }
}

# Cloud SQL disk (GCP exposes disk utilization as a fraction of capacity)
resource "google_monitoring_alert_policy" "sql_disk" {
  display_name = "${var.project_name}-${var.environment}-cloudsql-high-disk"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL disk utilization above threshold"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${var.project_id}:${var.sql_instance_name}\" AND metric.type = \"cloudsql.googleapis.com/database/disk/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.sql_disk_utilization_threshold
      duration        = "300s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [var.notification_channel_id]

  documentation {
    mime_type = "text/markdown"
    content   = "Cloud SQL disk utilization is above the threshold. Storage autoresize is on up to the configured limit; consider raising it."
  }
}
