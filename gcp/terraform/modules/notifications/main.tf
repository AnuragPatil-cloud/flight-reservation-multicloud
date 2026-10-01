# Email notification channel used by the alert policies.
# Google sends a verification email to this address when the channel is created.
resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.project_name}-${var.environment}-alerts-email"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}
