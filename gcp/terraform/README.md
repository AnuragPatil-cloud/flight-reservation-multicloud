# Flight Reservation - GCP Terraform

Terraform for the GCP edition of the project. It follows the same simple, one-module-per-concern layout as
the AWS version, translated to Google Cloud resources.

## Architecture

- **VM1** (`e2-standard-2`): Jenkins, Docker, Maven, Node.js, SonarQube (container)
- **VM2** (`e2-standard-2`): gcloud, kubectl, Helm, Argo CD CLI, MySQL client - administers the private cluster
- **GKE**: zonal, VPC-native, private nodes **and** private control-plane endpoint, 2 x `e2-standard-2` nodes, Workload Identity on
- **Cloud SQL for MySQL 8.4**: private IP only (Private Service Access), automated backups, storage autoresize; both databases created by Terraform
- **Cloud Storage**: application-files bucket (versioned, uniform access, public access prevention enforced)
- **Artifact Registry**: one Docker repository holding `reservation`, `checkin` and `frontend`
- **Cloud Monitoring**: alert policies (Jenkins CPU, monitoring-VM CPU, Cloud SQL CPU, Cloud SQL disk) + email notification channel
- **Cloud NAT**: outbound internet for the private GKE nodes
- **Prometheus / Grafana**: installed into GKE from VM2 with Helm (`scripts/install-monitoring.sh`)

Terraform does not create Kubernetes application manifests. After GKE exists, SSH to VM2, then install Argo CD and
kube-prometheus-stack with the helper scripts.

## Modules

| Module | Provisions |
|---|---|
| `apis` | Enables the required Google APIs |
| `network` | Custom VPC, VM subnet, GKE subnet (+ Pod/Service secondary ranges), Cloud Router + NAT, Private Service Access range and peering |
| `firewall` | Admin-IP-only rules for Jenkins/SonarQube/SSH, optional IAP SSH, internal traffic, GKE control-plane webhook ports |
| `iam` | Service accounts for Jenkins, monitoring VM and GKE nodes, with least-privilege project roles |
| `artifact-registry` | Docker repository + writer (Jenkins) / reader (GKE nodes) bindings on the repository |
| `compute-vm` | Reused for both VMs: static external IP, Ubuntu 24.04, shielded VM, OS Login, startup script |
| `gke` | Private GKE cluster + node pool |
| `cloudsql` | Cloud SQL MySQL instance (private IP), the two databases, the application user |
| `gcs` | Application-files bucket |
| `notifications` | Email notification channel |
| `cloud-monitoring` | Alert policies |

## How this maps to the AWS project

| AWS module | GCP module | Notes |
|---|---|---|
| `vpc` | `network` | Subnets are regional in GCP, so there are no per-AZ subnets. "Database subnets" become Private Service Access |
| `security-groups` | `firewall` | VPC firewall rules matched by network tags instead of security groups |
| `iam` | `iam` | Service accounts instead of roles/instance profiles |
| `ec2-jenkins`, `ec2-monitoring` | `compute-vm` (x2) | |
| `eks` | `gke` | Private endpoint + `master_authorized_networks` replaces the EKS access entry |
| `rds` | `cloudsql` | **MariaDB is not offered by Cloud SQL** - MySQL 8.4 is used instead |
| `s3` | `gcs` | |
| `ecr` (3 repos) | `artifact-registry` (1 repo, 3 images) | |
| `sns` | `notifications` | |
| `cloudwatch` | `cloud-monitoring` | Disk alert uses utilization (fraction) instead of free bytes |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars    # edit project_id, admin_cidr, sql_password, alert_email
terraform init
terraform validate
terraform plan
terraform apply
```

See `GCP-CREDENTIALS.md` for authentication. Do not commit `terraform.tfvars`.

Optional remote state: copy `backend.tf.example` to `backend.tf` after creating the bucket it describes.

## Notes

- Confirm the verification email Google sends to `alert_email`, otherwise the alert channel stays unverified.
- `sql_tier = "db-g1-small"` is a shared-core tier (Enterprise edition). If your project or region rejects it, use `db-custom-1-3840`.
- The GKE control plane has no public endpoint: run `kubectl`/`helm` from VM2 (`gcloud container clusters get-credentials ... --internal-ip`).
- `deletion_protection = false` is deliberate for a demo stack you tear down with `terraform destroy`; set it to `true` for anything you care about.
- The Cloud SQL instance and Private Service Access peering can take 10-15 minutes to create.
