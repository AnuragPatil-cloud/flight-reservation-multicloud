output "email_channel_id" {
  description = "Full resource name of the channel (projects/<id>/notificationChannels/<n>)"
  value       = google_monitoring_notification_channel.email.name
}
