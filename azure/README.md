# ✈️ Flight Reservation Application — Azure/AKS Edition

A full-stack flight reservation and check-in platform, built as a microservices system and shipped to production with an end-to-end DevOps pipeline: Terraform-provisioned Azure infrastructure, Jenkins CI, Docker, GitOps with Argo CD on AKS, and Prometheus/Grafana monitoring.

<p align="center">
  <img src="../docs/screenshots/azure/app-home.png" alt="Flight Reservation System home page" width="850">
</p>

<p align="center">
  <img alt="Java 21" src="https://img.shields.io/badge/Java-21-orange?logo=openjdk&logoColor=white">
  <img alt="Spring Boot 3.3.5" src="https://img.shields.io/badge/Spring%20Boot-3.3.5-6DB33F?logo=springboot&logoColor=white">
  <img alt="React 19" src="https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black">
  <img alt="Vite 6" src="https://img.shields.io/badge/Vite-6-646CFF?logo=vite&logoColor=white">
  <img alt="MariaDB" src="https://img.shields.io/badge/MariaDB-11.8-003545?logo=mariadb&logoColor=white">
  <img alt="Docker" src="https://img.shields.io/badge/Docker-blue?logo=docker&logoColor=white">
  <img alt="Kubernetes" src="https://img.shields.io/badge/AKS-Kubernetes-326CE5?logo=kubernetes&logoColor=white">
  <img alt="Terraform" src="https://img.shields.io/badge/Terraform-Azure-7B42BC?logo=terraform&logoColor=white">
  <img alt="Jenkins" src="https://img.shields.io/badge/CI-Jenkins-D24939?logo=jenkins&logoColor=white">
  <img alt="Argo CD" src="https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?logo=argo&logoColor=white">
</p>

---

## Table of contents

- [Overview](#overview)
- [Features](#features)
- [Application screenshots](#application-screenshots)
- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Repository layout](#repository-layout)
- [API reference](#api-reference)
- [Infrastructure (Terraform)](#infrastructure-terraform)
- [CI/CD pipeline (Jenkins)](#cicd-pipeline-jenkins)
- [GitOps deployment (Argo CD + AKS)](#gitops-deployment-argo-cd--aks)
- [Monitoring](#monitoring)
- [Getting started locally](#getting-started-locally)
- [Deploying to Azure](#deploying-to-azure)
- [Security notes](#security-notes)
- [Roadmap](#roadmap)
- [Author](#author)

---

## Overview

This project is a **flight booking and check-in system** split into three independently deployable services — a React SPA, a reservation backend, and a check-in backend — backed by a shared MariaDB database. It doubles as a reference implementation of a **production-style Azure DevOps pipeline**: infrastructure as code, containerized builds, automated testing, GitOps-driven continuous delivery, and cluster observability.

Everything from provisioning the Azure resource groups to promoting a new container image into the running AKS cluster is automated and captured with real screenshots below.

## Features

**Traveller-facing**
- Register / log in with JWT-based authentication
- Search flights by origin, destination, and date
- Book a flight and view a personal booking list
- Download a generated PDF e-ticket for a booking
- Self-service profile view and update
- Online check-in with baggage count, decoupled into its own service

**Admin-facing**
- Admin login (separate authentication guard from traveller login)
- Create, update, and delete flights
- View the full flight list and the list of registered admins
- Add additional admin accounts

**Platform**
- Stateless JWT auth shared across two independent Spring Boot services
- Nginx-based single-origin routing so the SPA never deals with CORS
- Fully automated build → scan → image → deploy pipeline
- Self-healing, auto-synced GitOps deployment
- Cost guardrails (Azure budget + alert thresholds) and email alerting baked into the infrastructure code

## Application screenshots

| Home | Login | Register |
|---|---|---|
| <img src="../docs/screenshots/azure/app-home.png" width="280"> | <img src="../docs/screenshots/azure/app-login.png" width="280"> | <img src="../docs/screenshots/azure/app-registration.png" width="280"> |

| Search flights | Profile | Contact |
|---|---|---|
| <img src="../docs/screenshots/azure/app-search-flights.png" width="280"> | <img src="../docs/screenshots/azure/app-profile.png" width="280"> | <img src="../docs/screenshots/azure/app-contact.png" width="280"> |

## Architecture

```mermaid
flowchart TD
    U([Browser]) --> FE["Nginx + React SPA<br/>(flight-frontend, :80)"]

    FE -- "/api/*" --> RES["Reservation Service<br/>Spring Boot :8080"]
    FE -- "/api/checkin/*" --> CHK["Check-in Service<br/>Spring Boot :8081"]

    CHK -- "validates booking via" --> RES

    RES --> DB[(MariaDB 11.8<br/>flightdb / checkin_db)]
    CHK --> DB

    RES -. "generates" .-> PDF[/PDF e-ticket via iText/]
```

The frontend is served by **Nginx on port 80** and acts as the single origin for the browser. It reverse-proxies:

- `/api/checkin/*` → `flight-checkin-service:8081`
- `/api/*` → `flight-reservation-service:8080`
- everything else → the React static build (SPA fallback)

This means the UI never needs to know the backend service addresses at runtime — only Nginx does — which keeps the two backend services free to move, scale, or restart independently.

### Delivery pipeline

```mermaid
flowchart LR
    Dev([git push]) --> Jenkins["Jenkins on CI VM<br/>build · test · scan"]
    Jenkins -- "docker push" --> Hub[(Docker Hub<br/>anuragpatilcloud/*)]
    Jenkins -- "commit new image tag" --> Git[(GitOps repo<br/>/gitops)]
    Git --> Argo["Argo CD<br/>auto-sync + self-heal"]
    Argo --> AKS["AKS cluster<br/>flight-reservation namespace"]
    Mon["Monitoring VM"] -- "helm install" --> Prom["kube-prometheus-stack<br/>(Prometheus/Grafana/Alertmanager)"]
    Prom -.-> AKS
```

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React 19, Vite 6, React Router 7, Redux Toolkit, Axios, React Toastify, Boxicons |
| Reservation service | Java 21, Spring Boot 3.3.5, Spring Security, Spring Data JPA, JJWT, iTextPDF |
| Check-in service | Java 21, Spring Boot 3.3.5, Spring Security, Spring Data JPA, JJWT |
| Database | MariaDB 11.8 (two logical schemas: `flightdb`, `checkin_db`) |
| Containers | Docker, Nginx (frontend static/reverse proxy), Eclipse Temurin JRE (backend) |
| Infrastructure as Code | Terraform (modular: network, VM, AKS, storage, alerting, budgets) |
| Cloud | Microsoft Azure (AKS, Virtual Machines, Storage, Monitor, Consumption Budgets) |
| CI | Jenkins (self-hosted on an Azure VM), SonarQube |
| CD / GitOps | Argo CD (auto-sync, self-heal, prune) |
| Orchestration | Azure Kubernetes Service (AKS), Kustomize-style manifests |
| Monitoring | kube-prometheus-stack (Prometheus, Grafana, Alertmanager) via Helm |

## Repository layout

This folder is one of three cloud editions inside the **flight-reservation-multicloud** repository. The application code is shared and lives at the repository root; everything in this folder is specific to Azure.

```
flight-reservation-multicloud/
├── frontend/ · FlightReservationApplication/ · FlightCheckInApplication/   # shared application (same code on every cloud)
├── azure/                              # <- this edition
│   ├── terraform/                    # Azure IaC (network, vm, aks, storage, sns, budgets modules)
│   ├── gitops/                       # Kubernetes manifests synced by Argo CD
│   ├── monitoring/                   # kube-prometheus-stack values + Grafana secret template
│   ├── docs/                         # Jenkins credentials setup
│   ├── Jenkinsfile                   # CI pipeline (Jenkins job Script Path: azure/Jenkinsfile)
│   ├── argocd-application.yaml       # Argo CD Application definition
│   ├── README-DEPLOYMENT.md          # Detailed one-time deployment notes
│   └── README.md                     # this file
├── aws/  azure/  gcp/                # the three editions
└── docs/screenshots/                 # every screenshot used in the READMEs
```

The `terraform/modules/database` module is present but intentionally **not wired into** `terraform/main.tf`: this edition runs MariaDB inside the cluster (see `gitops/mariadb-*.yaml`).

## API reference

### User service — `/api/users` (Reservation app)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/register` | Register a new user |
| POST | `/login` | Authenticate and receive a JWT |
| GET | `/{id}` | Fetch a user by ID |
| GET | `/userList` | List all registered users |
| PUT | `/update/{id}` | Update a user's profile |

### Flight service — `/api/flights` (Reservation app)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/create` | Add a new flight (admin) |
| GET | `/all` | List all flights |
| GET | `/search` | Search flights by origin, destination, date |
| PUT | `/update/{id}` | Update a flight (admin) |
| DELETE | `/delete/{id}` | Remove a flight (admin) |

### Booking service — `/api/bookings` (Reservation app)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/book` | Create a booking |
| GET | `/user/{userId}` | List a user's bookings |
| GET | `/details/{bookingId}` | Get a single booking's details |
| GET | `/download-ticket/{bookingId}` | Download the e-ticket as a generated PDF |

### Check-in service — `/api/checkin` (Check-in app)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/{bookingId}` | Check in a booking (`numberOfBags` param, JWT bearer token); the service validates the booking against the reservation service before completing check-in |

## Infrastructure (Terraform)

Provisioning is split into composable modules under `terraform/modules/`:

| Module | Provisions |
|---|---|
| `network` | Resource group, VNet, and subnets (used twice — once for the VM network, once for the AKS network) |
| `vm` | Two Linux VMs — a **CI VM** (Jenkins, Docker, Maven, Terraform, Azure CLI) and a **monitoring/admin VM** (kubectl, Helm, Argo CD CLI, Azure CLI) — each with its own public IP and NSG |
| `aks` | The AKS cluster (system-assigned identity, configurable node VM size) |
| `storage` | An Azure Storage account/container for shared artifacts |
| `sns` | An Azure Monitor Action Group for email alerting |
| `budgets` | A monthly Azure subscription budget with 80%/100% threshold notifications |

The VM and AKS workloads live in **separate virtual networks** with their own resource groups, so the always-on cluster and the more elastic CI/monitoring VMs can be sized, budgeted, and torn down independently.

<p align="center">
  <img src="../docs/screenshots/azure/terraform-output.png" alt="terraform output showing provisioned resource names" width="700">
</p>

<p align="center">
  <img src="../docs/screenshots/azure/az-resource-list.png" alt="az resource list of everything provisioned" width="700">
</p>

Applying the stack requires a `terraform.tfvars` (copy `terraform/terraform.tfvars.example`) with at minimum your Azure `subscription_id`, a `project_name`, and an SSH public key path — see `terraform/variables.tf` for the full set of inputs and their defaults (regions, VM sizes, AKS node size, environment name).

## CI/CD pipeline (Jenkins)

The [`Jenkinsfile`](./Jenkinsfile) (Jenkins job *Script Path*: `azure/Jenkinsfile`) runs on the Terraform-provisioned CI VM and drives every merge to `main` through eight stages:

> 📝 The *stage view* and *build history* screenshots below come from the original Azure pipeline, whose Backend Build stage ran the tests against a throw-away MySQL container. In this merged repository that stage builds with `-DskipTests` (the shared code keeps its tests on in-memory H2), so the stage names are unchanged but that one stage's log differs.

1. **Checkout** — pull the repository
2. **Backend Build** — `mvn clean package -DskipTests` for the reservation and check-in services (tests are skipped in CI, as in the AWS and GCP editions)
3. **Frontend Checks** — `npm ci`, ESLint (non-blocking), and a production Vite build
4. **SonarQube Analysis** — static analysis and quality-gate reporting
5. **Docker Build** — build images for all three services
6. **Push Images** — push immutable build-numbered tags and `latest` to Docker Hub
7. **Update GitOps** — patch the image tags into `gitops/*.yaml` and push the commit back to `main` (`[skip ci]`)
8. **Post Actions** — clean up the ephemeral database container and dangling images

<p align="center">
  <img src="../docs/screenshots/azure/jenkins-pipeline-success.png" alt="Jenkins pipeline — all stages green" width="700">
</p>

<p align="center">
  <img src="../docs/screenshots/azure/jenkins-pipeline-stage-view.png" alt="Jenkins pipeline stage view" width="700">
</p>

Getting a fully green pipeline took a few iterations, as any real CI setup does:

<p align="center">
  <img src="../docs/screenshots/azure/jenkins-build-history.png" alt="Jenkins build history during initial pipeline debugging" width="700">
</p>

The CI VM's toolchain (Java 21, Maven, Docker, Terraform, Azure CLI) is provisioned once by Terraform's `vm` module:

<p align="center">
  <img src="../docs/screenshots/azure/ci-vm-tools-installed.png" alt="CI VM toolchain versions" width="700">
</p>

Required Jenkins credentials are documented in [`docs/JENKINS-CREDENTIALS.md`](./docs/JENKINS-CREDENTIALS.md):

- `dockerhub-creds` — Docker Hub username/password
- `github` — GitHub username + PAT, used by the *Update GitOps* stage to push back to `main`
- `sonarqube-token` — SonarQube token (secret text)

## GitOps deployment (Argo CD + AKS)

The `gitops/` directory is a Kustomize-style manifest set — namespace, MariaDB (PVC + init ConfigMap + Deployment + Service), the two Spring Boot Deployments/Services, and the frontend Deployment/Service — all in the `flight-reservation` namespace.

[`argocd-application.yaml`](./argocd-application.yaml) points Argo CD at that folder on `main` with **automated sync, self-heal, and prune** enabled, so any commit that lands on `main` (including the Jenkins image-tag bump) is reconciled onto the cluster within seconds, and any manual `kubectl` drift is reverted automatically.

<p align="center">
  <img src="../docs/screenshots/azure/argocd-app-tree.png" alt="Argo CD application tree — healthy and synced" width="700">
</p>

<p align="center">
  <img src="../docs/screenshots/azure/argocd-app-info.png" alt="Argo CD sync details and resource list" width="700">
</p>

```bash
kubectl apply -f argocd-application.yaml
argocd app get flight-reservation
argocd app sync flight-reservation
```

## Monitoring

The monitoring/admin VM (kubectl, Helm, Argo CD CLI) is used to install **kube-prometheus-stack** *inside* the AKS cluster, rather than running Prometheus/Grafana on the VM itself — keeping the VM a thin control point and the metrics pipeline part of the same GitOps-managed cluster:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/kube-prometheus-stack-values.yaml
```

<p align="center">
  <img src="../docs/screenshots/azure/monitoring-vm-setup.png" alt="Monitoring VM toolchain — kubectl, Helm, Argo CD CLI" width="700">
</p>

Application-level metrics can be added later by enabling the Spring Boot Actuator/Micrometer endpoints and pointing a `ServiceMonitor` at them.

## Getting started locally

The application is identical on every cloud, so the local-run instructions live once in the [root README](../README.md#run-locally).

## Deploying to Azure

The full one-time setup — Terraform apply, Docker Hub image names, Jenkins credentials, and the Argo CD bootstrap — is documented in [`README-DEPLOYMENT.md`](./README-DEPLOYMENT.md). Run the commands from the `azure/` folder. In short:

1. `cd azure/terraform && terraform init && terraform apply` the stack to create the VNets, CI VM, monitoring VM, AKS cluster, storage, alerting, and budget.
2. Provision Jenkins on the CI VM, add the credentials listed above, and create a Pipeline job from SCM with *Script Path* `azure/Jenkinsfile`.
3. Copy `gitops/secret.example.yaml` to `gitops/secret.yaml` (git-ignored) and `monitoring/grafana-admin-secret.example.yaml` likewise, set real, unique passwords, and `kubectl apply` them by hand (never commit real secrets — see below).
4. Set `repoURL` in `azure/argocd-application.yaml` to your repository and `kubectl apply` it.
5. Push to `main` — Jenkins builds, pushes images, and updates the GitOps manifests; Argo CD takes it from there.

## Security notes

- `gitops/secret.example.yaml` and `monitoring/grafana-admin-secret.example.yaml` ship with `CHANGE_ME_STRONG_PASSWORD` placeholders — copy them, set real values, and apply them by hand. The real `gitops/secret.yaml` is git-ignored; never commit it.
- Both Spring Boot services read their datasource settings from environment variables (`SPRING_DATASOURCE_*`), injected by the Kubernetes Deployments in `gitops/`. The earlier hard-coded sample credentials were removed from the merged repository — rotate any credentials that were ever pushed to git history before publishing it.
- The screenshots under `docs/screenshots/azure/` include a demo profile page with sample personal details used purely for testing — swap it for a screenshot with placeholder data if you plan to publish this repository publicly.

## Roadmap

Ideas for extending this project further:
- Add a `docker-compose.yml` for a one-command local stack (frontend + both services + MariaDB)
- Wire up Spring Boot Actuator/Micrometer so Prometheus can scrape real application metrics, not just cluster metrics
- Add automated frontend tests to the Jenkins pipeline (Testing Library is already a dependency)
- Introduce a staging environment/namespace ahead of `main` in the GitOps flow

## Author

**Anurag Patil** — DevOps Engineer
GitHub: [AnuragPatil-cloud](https://github.com/AnuragPatil-cloud)

---

