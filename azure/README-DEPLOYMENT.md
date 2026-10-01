# Flight Reservation Application - Complete Azure/AKS DevOps Package

> Paths in this document are relative to the `azure/` folder; the shared application code (`frontend/`, `FlightReservationApplication/`, `FlightCheckInApplication/`) is one level up.

This package preserves the application source/UI and adds the complete container, Jenkins, GitOps, MariaDB, and Argo CD deployment layer.

## Application components

- `frontend/`: existing React/Vite UI. No UI source files were changed.
- `FlightReservationApplication/`: existing Spring Boot reservation backend.
- `FlightCheckInApplication/`: existing Spring Boot check-in backend.
- `gitops/`: Kubernetes manifests for MariaDB, reservation backend, check-in backend, and frontend.
- `argocd-application.yaml`: Argo CD Application template.
- `Jenkinsfile`: CI pipeline for the Maven and frontend builds, SonarQube, Docker build, Docker Hub push and GitOps image update (Jenkins job *Script Path*: `azure/Jenkinsfile`).

## Runtime routing

The frontend is served by Nginx on port 80. Nginx keeps the browser talking to the same origin and routes:

- `/api/checkin/*` -> `flight-checkin-service:8081`
- `/api/*` -> `flight-reservation-service:8080`
- everything else -> React static files

This avoids changing the existing frontend API code or UI.

## Required one-time values

1. Copy `gitops/secret.example.yaml` to `gitops/secret.yaml` (git-ignored), replace `CHANGE_ME_STRONG_PASSWORD`, and apply it once by hand: `kubectl apply -f gitops/secret.yaml` (it is intentionally not part of `gitops/kustomization.yaml`).
2. Replace the Docker Hub user in the `image:` lines of `gitops/*-deployment.yaml` (the first Jenkins run rewrites them) and set `repoURL` in `argocd-application.yaml` to your repository.
3. Create Jenkins credentials:
   - `dockerhub-creds` (username/password)
   - `github` (username + PAT, for the GitOps push-back)
   - `sonarqube-token` (secret text)

## Argo CD

Apply `argocd-application.yaml` after replacing the repository URL:

```bash
kubectl apply -f argocd-application.yaml
```

Verify:

```bash
argocd app get flight-reservation
argocd app sync flight-reservation
```

## First deployment

Before the first Argo sync, make sure Docker Hub contains these images:

- `<dockerhub-user>/flight-reservation-app`
- `<dockerhub-user>/flight-checkin-app`
- `<dockerhub-user>/flight-frontend`

The Jenkinsfile pushes both the immutable build number tag and `latest`, then updates the GitOps Deployment manifests with the immutable build tag. Argo CD detects the Git change and reconciles the cluster.

## Persistence

MariaDB uses `mariadb-pvc` so application data survives pod replacement. Two logical databases are created on first MariaDB initialization: `flightdb` and `checkin_db`.

## Safety

The application source, React components, CSS, assets, routes, and existing Spring Boot business logic were left intact. Only deployment/container/CI/CD configuration was added or separated.
