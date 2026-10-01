# GCP screenshots — to be added

The uploaded GCP project contained **no GCP-specific screenshots**: its `FRA-SCREENSHOTS/` folder held only the seven application
screenshots, which are byte-identical to the AWS ones and live once in [`../app/`](../app/).

After you deploy the GCP edition, drop your captures in this folder using the names below, then add them to the
[root README](../../../README.md#screenshots) (the *GCP* rows of the coverage table) and to [`gcp/README.md`](../../../gcp/README.md).

| Tool | Suggested file name | What to capture |
|---|---|---|
| Terraform | `10-terraform-init-validate.png` | `terraform init` + `terraform validate` |
| Terraform / GCP | `11-terraform-gcp-resources.png` | `terraform output` / `gcloud compute instances list` / `gcloud container clusters list` |
| Cloud SQL | `08-cloudsql-data-stored.png` | `SHOW TABLES;` and a few rows from `flightdb` / `checkin_db` |
| Jenkins | `20-jenkins-pipeline-success.png` | Green pipeline, all 10 stages |
| Artifact Registry | `25-artifact-registry-images.png` | The three images in `flight-reservation-dev` |
| Argo CD | `21-argocd-synced-healthy.png` | `flight-reservation` app: Healthy + Synced |
| SonarQube | `22-sonarqube-projects.png` | Both backends, quality gate passed |
| Prometheus | `30-prometheus-targets.png` | Target health |
| Grafana | `34-grafana-cluster-networking.png` | Any kube-prometheus-stack dashboard |
| Cloud Monitoring | `40-cloud-monitoring-alert-policies.png` | The four alert policies |

Tip: blur emails, project IDs, public IPs and billing details before committing screenshots to a public repository.
