# Flight Reservation Application - Complete GCP / GKE DevOps Package

> Paths in this document are relative to the `gcp/` folder; the shared application code (`frontend/`, `FlightReservationApplication/`, `FlightCheckInApplication/`) is one level up.

This package keeps the application source and UI unchanged and provides the container, Jenkins, GitOps and Argo CD
deployment layer for Google Cloud. It pairs with the Terraform stack in `terraform/` (VPC, Compute Engine x2, GKE,
Cloud SQL, Cloud Storage, Artifact Registry, Cloud Monitoring).

## Application components

- `frontend/`: React/Vite UI, served by Nginx. No UI source files were changed.
- `FlightReservationApplication/`: Spring Boot reservation backend (:8080). Datasource config comes from environment variables.
- `FlightCheckInApplication/`: Spring Boot check-in backend (:8081). Datasource and booking-service URL come from environment variables.
- `gitops/`: Kubernetes manifests for the three services plus a ConfigMap. No database manifests - the app connects to Cloud SQL.
- `argocd-application.yaml`: Argo CD Application, pointed at this repository.
- `Jenkinsfile`: CI pipeline - build, SonarQube, Docker build, push to Artifact Registry, GitOps image update (Jenkins job *Script Path*: `gcp/Jenkinsfile`).

## Runtime routing

The frontend is served by Nginx on port 80 and keeps the browser on a single origin:

- `/api/checkin/*` -> `flight-checkin-service:8081`
- `/api/*` -> `flight-reservation-service:8080`
- everything else -> React static files

## Required one-time values

1. `terraform/terraform.tfvars`: `project_id`, `admin_cidr`, `sql_password`, `alert_email`.
2. `gitops/configmap.yaml`: replace `<CLOUD_SQL_PRIVATE_IP>` (both JDBC URLs) with `terraform output cloudsql_private_ip`.
3. `gitops/*-deployment.yaml`: replace `YOUR_GCP_PROJECT_ID` in the placeholder image paths (the first Jenkins run rewrites them anyway).
4. `Jenkinsfile`: set `GITHUB_REPO` to your `owner/repo` (the repository Jenkins pushes image tags back to) and `GCP_REGION` / `AR_REPO` if you changed them in Terraform.
5. `argocd-application.yaml`: set `repoURL` to your repository.
6. `gitops/secret.yaml`: copy `gitops/secret.example.yaml`, set the real `DB_USERNAME` / `DB_PASSWORD` (same values as `sql_username` / `sql_password`).
   It is gitignored. Apply it once by hand - it is intentionally not in `gitops/kustomization.yaml`, so Argo CD never overwrites it:
   `kubectl create namespace flight-reservation --dry-run=client -o yaml | kubectl apply -f - && kubectl apply -f gitops/secret.yaml`
7. Jenkins credentials `sonarqube-token` and `github` - see `docs/JENKINS-CREDENTIALS.md`.
8. After the frontend LoadBalancer has an address, set `FRONTEND_URL` in `gitops/configmap.yaml`, push, and restart the backends
   (`kubectl rollout restart deployment -n flight-reservation`) - environment variables from a ConfigMap are only read at pod start.

## Argo CD

Run the first Jenkins build **before** the first sync, so Artifact Registry already contains the three images and the
manifests point at them. Then, from VM2:

```bash
kubectl apply -f argocd-application.yaml
argocd app get flight-reservation
argocd app sync flight-reservation
```

If the GitHub repository is private, register it with Argo CD first (`argocd repo add ... --username ... --password <PAT>`).

## Images

Terraform creates one Artifact Registry Docker repository (`flight-reservation-dev`). The pipeline pushes three images into it,
tagged with the Jenkins build number:

```
<region>-docker.pkg.dev/<project-id>/flight-reservation-dev/reservation:<build>
<region>-docker.pkg.dev/<project-id>/flight-reservation-dev/checkin:<build>
<region>-docker.pkg.dev/<project-id>/flight-reservation-dev/frontend:<build>
```

GKE nodes pull them with their own service account (read access on the repository) - no image pull secret is needed.

## Persistence

Application data lives in **Cloud SQL for MySQL** (private IP only), not in a Kubernetes PVC. Two logical databases exist on the same instance:
`flightdb` (reservation service) and `checkin_db` (check-in service); Terraform creates both. Cloud SQL automated backups are the
backup mechanism.

## Differences from the AWS edition worth knowing

- **Database engine**: Cloud SQL has no MariaDB. The services use MySQL 8.4 with the stock `mysql-connector-j` driver and Hibernate's `MySQLDialect`.
- **Reservation database name**: the AWS ConfigMap pointed the reservation service at `checkin_db`. Here it uses `flightdb`, as the docs always described. The two services have different tables, so either works, but this is the layout the docs describe.
- **Registry**: one repository with three images instead of three repositories.
- **Private cluster**: `kubectl`/`helm` run from VM2 only; the GKE API has no public endpoint.

## Safety

The application source, React components, CSS, assets, routes and Spring Boot business logic were left intact. Hardcoded database credentials,
an AWS RDS hostname and a stale IP address that existed in the original `application.properties` files were replaced with environment variables
(with local-development defaults only).
