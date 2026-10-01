# Flight Reservation Application - Complete AWS/EKS DevOps Package

> Paths in this document are relative to the `aws/` folder; the shared application code (`frontend/`, `FlightReservationApplication/`, `FlightCheckInApplication/`) is one level up.

This package preserves the application source/UI and adapts the container, Jenkins, GitOps, and Argo CD deployment layer for AWS. It pairs with the separate Terraform stack and the AWS DevOps runbook (VPC, EC2 x2, EKS, RDS, S3, ECR, SNS, CloudWatch).

## Application components

- `frontend/`: existing React/Vite UI. No UI source files were changed.
- `FlightReservationApplication/`: existing Spring Boot reservation backend. Datasource config now comes from environment variables.
- `FlightCheckInApplication/`: existing Spring Boot check-in backend. Datasource config now comes from environment variables.
- `gitops/`: Kubernetes manifests for the reservation backend, check-in backend, and frontend, plus a ConfigMap for non-secret RDS/service config. No MariaDB manifests - the app connects to Amazon RDS instead.
- `argocd-application.yaml`: Argo CD Application template, pointed at this repo.
- `Jenkinsfile`: CI pipeline for the Maven and frontend builds, SonarQube, Docker build, ECR push and GitOps image update (Jenkins job *Script Path*: `aws/Jenkinsfile`).

## Runtime routing

The frontend is served by Nginx on port 80. Nginx keeps the browser talking to the same origin and routes:

- `/api/checkin/*` -> `flight-checkin-service:8081`
- `/api/*` -> `flight-reservation-service:8080`
- everything else -> React static files

This avoids changing the existing frontend API code or UI.

## Required one-time values

1. Get the RDS endpoint from `terraform output` and fill it into `gitops/configmap.yaml` (`SPRING_DATASOURCE_URL_RESERVATION` / `SPRING_DATASOURCE_URL_CHECKIN`), replacing `<RDS_ENDPOINT>`.
2. Fill in `FRONTEND_URL` in `gitops/configmap.yaml` once the frontend LoadBalancer/ingress address is known.
3. Copy `gitops/secret.example.yaml` to `gitops/secret.yaml` and set `DB_USERNAME` / `DB_PASSWORD` to the real RDS credentials from `terraform.tfvars` (`rds_username` / `rds_password`). `gitops/secret.yaml` is gitignored - never commit it.
4. Apply the secret once by hand (it's intentionally not in `gitops/kustomization.yaml`, so Argo CD never overwrites or diffs it): `kubectl apply -f gitops/secret.yaml`.
5. Edit `GITHUB_REPO` in `Jenkinsfile` and `repoURL` in `argocd-application.yaml` to point at your repository, and replace `YOUR_AWS_ACCOUNT_ID` in the `gitops/*-deployment.yaml` placeholder image paths (the first Jenkins run rewrites them anyway).
6. Create Jenkins credentials:
   - `sonarqube-token` (secret text)
   - `github` (username/password or PAT, for the GitOps push-back)
7. Attach an IAM instance role to VM1 (Jenkins) with ECR push permissions on the three `flight-reservation-dev-*` repositories - see `docs/JENKINS-CREDENTIALS.md`.

## Argo CD

Apply `argocd-application.yaml` (set `repoURL` to your repository first):

```bash
kubectl apply -f argocd-application.yaml
```

Verify:

```bash
argocd app get flight-reservation
argocd app sync flight-reservation
```

## First deployment

Before the first Argo sync, make sure ECR contains these repositories (created by Terraform) with at least one pushed image each:

- `flight-reservation-dev-reservation`
- `flight-reservation-dev-checkin`
- `flight-reservation-dev-frontend`

The Jenkinsfile pushes the immutable build-number tag to ECR, then updates the GitOps Deployment manifests with the immutable build tag. Argo CD detects the Git change and reconciles the cluster.

## Persistence

The application data lives in **Amazon RDS** (private, not publicly accessible), not in a Kubernetes PVC. Terraform creates `flightdb` on the RDS instance and `terraform/scripts/create-checkin-db.sh` creates `checkin_db`; as deployed (see `docs/screenshots/aws/08-rds-data-stored.png`) both services use `checkin_db`. RDS's own automated backups (per `terraform.tfvars`) are the persistence/backup mechanism - there is no `mariadb-pvc` in this edition.

## Safety

The application source, React components, CSS, assets, routes, and existing Spring Boot business logic were left intact. Only deployment/container/CI/CD configuration was added or changed. Hardcoded database credentials and stale IP addresses that existed in the original `application.properties` files were removed in favor of environment variables sourced from the ConfigMap/Secret above.
