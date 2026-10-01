locals {
  labels = {
    project     = var.project_name
    environment = var.environment
    managed-by  = "terraform"
  }

  gke_node_tag = "${var.project_name}-${var.environment}-gke-node"

  required_services = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "artifactregistry.googleapis.com",
    "containerscanning.googleapis.com",
    "storage.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "oslogin.googleapis.com",
    "iap.googleapis.com",
  ]
}

module "apis" {
  source = "./modules/apis"

  project_id = var.project_id
  services   = local.required_services
}

module "network" {
  source = "./modules/network"

  project_name      = var.project_name
  environment       = var.environment
  region            = var.region
  vm_subnet_cidr    = var.vm_subnet_cidr
  gke_subnet_cidr   = var.gke_subnet_cidr
  gke_pods_cidr     = var.gke_pods_cidr
  gke_services_cidr = var.gke_services_cidr
  psa_prefix_length = var.psa_prefix_length

  depends_on = [module.apis]
}

module "firewall" {
  source = "./modules/firewall"

  project_name    = var.project_name
  environment     = var.environment
  network_name    = module.network.network_name
  admin_cidr      = var.admin_cidr
  enable_iap_ssh  = var.enable_iap_ssh
  gke_master_cidr = var.gke_master_cidr
  gke_node_tag    = local.gke_node_tag
  internal_cidrs = [
    var.vm_subnet_cidr,
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.gke_services_cidr,
  ]
}

module "iam" {
  source = "./modules/iam"

  project_id  = var.project_id
  sa_prefix   = var.sa_prefix
  environment = var.environment

  depends_on = [module.apis]
}

module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_name  = var.project_name
  environment   = var.environment
  region        = var.region
  labels        = local.labels
  writer_member = "serviceAccount:${module.iam.jenkins_service_account_email}"
  reader_member = "serviceAccount:${module.iam.gke_nodes_service_account_email}"

  depends_on = [module.apis]
}

module "jenkins" {
  source = "./modules/compute-vm"

  project_name          = var.project_name
  environment           = var.environment
  role                  = "jenkins"
  region                = var.region
  zone                  = var.zone
  machine_type          = var.vm_machine_type
  subnetwork            = module.network.vm_subnet_self_link
  service_account_email = module.iam.jenkins_service_account_email
  boot_disk_size        = var.jenkins_volume_size
  startup_script        = file("${path.root}/scripts/jenkins-startup.sh")
  labels                = local.labels
}

module "monitoring" {
  source = "./modules/compute-vm"

  project_name          = var.project_name
  environment           = var.environment
  role                  = "monitoring"
  region                = var.region
  zone                  = var.zone
  machine_type          = var.vm_machine_type
  subnetwork            = module.network.vm_subnet_self_link
  service_account_email = module.iam.monitoring_service_account_email
  boot_disk_size        = var.monitoring_volume_size
  startup_script        = file("${path.root}/scripts/monitoring-startup.sh")
  labels                = local.labels
}

module "gke" {
  source = "./modules/gke"

  project_id                 = var.project_id
  project_name               = var.project_name
  environment                = var.environment
  zone                       = var.zone
  network_self_link          = module.network.network_self_link
  subnetwork_self_link       = module.network.gke_subnet_self_link
  pods_range_name            = module.network.pods_range_name
  services_range_name        = module.network.services_range_name
  master_cidr                = var.gke_master_cidr
  node_machine_type          = var.gke_node_machine_type
  node_count                 = var.gke_node_count
  node_disk_size             = var.gke_node_disk_size
  node_service_account_email = module.iam.gke_nodes_service_account_email
  node_tag                   = local.gke_node_tag
  release_channel            = var.gke_release_channel
  deletion_protection        = var.deletion_protection
  labels                     = local.labels

  # The private control plane endpoint is reachable from these ranges only.
  authorized_networks = [
    { name = "vm-subnet", cidr = var.vm_subnet_cidr },
    { name = "gke-subnet", cidr = var.gke_subnet_cidr },
    { name = "gke-pods", cidr = var.gke_pods_cidr },
  ]

  depends_on = [module.network, module.iam]
}

module "cloudsql" {
  source = "./modules/cloudsql"

  project_name          = var.project_name
  environment           = var.environment
  region                = var.region
  network_self_link     = module.network.network_self_link
  database_version      = var.sql_database_version
  tier                  = var.sql_tier
  disk_size             = var.sql_disk_size
  disk_autoresize_limit = var.sql_disk_autoresize_limit
  backup_retention_days = var.sql_backup_retention_days
  deletion_protection   = var.deletion_protection
  database_names        = [var.sql_reservation_database, var.sql_checkin_database]
  username              = var.sql_username
  password              = var.sql_password
  labels                = local.labels

  # Waits for the Private Service Access peering created in the network module.
  depends_on = [module.network]
}

module "gcs" {
  source = "./modules/gcs"

  project_id   = var.project_id
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  labels       = local.labels

  depends_on = [module.apis]
}

module "notifications" {
  source = "./modules/notifications"

  project_name = var.project_name
  environment  = var.environment
  alert_email  = var.alert_email

  depends_on = [module.apis]
}

module "cloud_monitoring" {
  source = "./modules/cloud-monitoring"

  project_id                     = var.project_id
  project_name                   = var.project_name
  environment                    = var.environment
  jenkins_instance_id            = module.jenkins.instance_id
  monitoring_instance_id         = module.monitoring.instance_id
  sql_instance_name              = module.cloudsql.instance_name
  notification_channel_id        = module.notifications.email_channel_id
  vm_cpu_threshold               = var.vm_cpu_threshold
  sql_cpu_threshold              = var.sql_cpu_threshold
  sql_disk_utilization_threshold = var.sql_disk_utilization_threshold
}
