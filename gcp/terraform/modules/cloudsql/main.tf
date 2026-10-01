resource "google_sql_database_instance" "this" {
  name                = "${var.project_name}-${var.environment}-mysql"
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier                  = var.tier
    edition               = "ENTERPRISE"
    availability_type     = "ZONAL"
    disk_type             = "PD_SSD"
    disk_size             = var.disk_size
    disk_autoresize       = true
    disk_autoresize_limit = var.disk_autoresize_limit
    user_labels           = var.labels

    # Private IP only - no public address. Reached through Private Service Access.
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_self_link
    }

    backup_configuration {
      enabled    = true
      start_time = "21:00"

      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }
  }
}

# Both logical databases are created here, so no manual "create checkin_db" step is needed.
resource "google_sql_database" "this" {
  for_each = toset(var.database_names)

  name      = each.value
  instance  = google_sql_database_instance.this.name
  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
}

resource "google_sql_user" "app" {
  name     = var.username
  instance = google_sql_database_instance.this.name
  password = var.password
  host     = "%"
}
