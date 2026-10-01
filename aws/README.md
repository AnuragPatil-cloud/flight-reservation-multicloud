# ✈️ Flight Reservation System — End-to-End DevOps on AWS

A full-stack **flight booking and check-in platform** (React + two Spring Boot microservices) that is provisioned with **Terraform**, built by **Jenkins**, scanned by **SonarQube**, stored in **Amazon ECR**, delivered to **Amazon EKS** through **Argo CD (GitOps)**, and observed with **Prometheus, Grafana and CloudWatch**.

The application is the vehicle; the focus of this repository is the **production-style AWS DevOps pipeline around it** — everything from creating the VPC to rolling a new container image onto the cluster is automated.

<p align="center">
  <img src="../docs/screenshots/app/01-app-home.png" alt="Flight Reservation System home page" width="850">
</p>

<p align="center">
  <img alt="Java 21" src="https://img.shields.io/badge/Java-21-orange?logo=openjdk&logoColor=white">
  <img alt="Spring Boot 3.3.5" src="https://img.shields.io/badge/Spring%20Boot-3.3.5-6DB33F?logo=springboot&logoColor=white">
  <img alt="React 19" src="https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black">
  <img alt="Vite 6" src="https://img.shields.io/badge/Vite-6-646CFF?logo=vite&logoColor=white">
  <img alt="MariaDB on RDS" src="https://img.shields.io/badge/MariaDB-RDS-003545?logo=mariadb&logoColor=white">
  <img alt="Docker" src="https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white">
  <img alt="Amazon EKS" src="https://img.shields.io/badge/Amazon%20EKS-326CE5?logo=kubernetes&logoColor=white">
  <img alt="Terraform" src="https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white">
  <img alt="Jenkins" src="https://img.shields.io/badge/CI-Jenkins-D24939?logo=jenkins&logoColor=white">
  <img alt="Argo CD" src="https://img.shields.io/badge/GitOps-Argo%20CD-EF7B4D?logo=argo&logoColor=white">
  <img alt="SonarQube" src="https://img.shields.io/badge/SonarQube-4E9BCD?logo=sonarqube&logoColor=white">
  <img alt="Prometheus" src="https://img.shields.io/badge/Prometheus-E6522C?logo=prometheus&logoColor=white">
  <img alt="Grafana" src="https://img.shields.io/badge/Grafana-F46800?logo=grafana&logoColor=white">
</p>

---

## At a glance

**What this project demonstrates**

- **Infrastructure as Code** — 11 modular Terraform modules create the whole AWS environment (VPC, EC2, EKS, RDS, S3, ECR, IAM, SNS, CloudWatch).
- **CI pipeline** — a 10-stage Jenkins pipeline: verify AWS → build → SonarQube analysis → Docker build → push to ECR → update GitOps manifests.
- **GitOps continuous delivery** — Argo CD watches the `gitops/` folder and auto-syncs, self-heals and prunes the EKS namespace.
- **Observability & alerting** — `kube-prometheus-stack` (Prometheus, Grafana, Alertmanager) inside the cluster, plus CloudWatch alarms that email through SNS.
- **Security-minded design** — private EKS API endpoint, private encrypted RDS, least-open security groups, IAM instance roles instead of stored AWS keys, non-root backend containers.

| | |
|---|---|
| **Cloud / region** | AWS · `ap-south-1` (Mumbai) |
| **Kubernetes** | Amazon EKS 1.35 · 2 × `c7i-flex.large` worker nodes |
| **Database** | Amazon RDS MariaDB 10.11 (private, encrypted, gp3) |
| **CI** | Jenkins on EC2 · 10 stages · build #4 finished in 8 min 44 s |
| **CD** | Argo CD — automated sync, self-heal, prune |
| **Observability** | Prometheus · Grafana · Alertmanager · CloudWatch → SNS email |
| **IaC** | Terraform ≥ 1.6 · AWS provider 6.66.0 |

> This is the **AWS edition** of the [flight-reservation-multicloud](../README.md) project. The application is shared with the Azure and GCP editions; this folder holds the AWS infrastructure, pipeline and GitOps layer.

---

## Table of contents

- [Features](#features)
- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Screenshots](#screenshots)
- [CI/CD pipeline](#cicd-pipeline-jenkins--ecr)
- [GitOps deployment](#gitops-deployment-argo-cd--eks)
- [Infrastructure (Terraform)](#infrastructure-terraform)
- [Monitoring & alerting](#monitoring--alerting)
- [Repository layout](#repository-layout)
- [API reference](#api-reference)
- [Run locally](#run-locally)
- [Deploy to AWS](#deploy-to-aws)
- [Security notes](#security-notes)
- [Roadmap](#roadmap)
- [Author](#author)

---

## Features

**Traveller**
- Register and log in (JWT authentication)
- Search flights by origin, destination and date
- Book a flight through a (simulated) payment step
- View personal bookings and **download a PDF e-ticket** (generated with iTextPDF)
- View and update profile
- **Online check-in** with baggage count, handled by a separate check-in service

**Admin**
- Separate admin login and profile
- Add and delete flights, and view the full flight list
- Add admin accounts and view the admin list

**Platform**
- Stateless JWT auth shared across two independent Spring Boot services
- The check-in service validates the booking (and that it belongs to the caller) by calling the reservation service
- Nginx reverse proxy gives the browser a single origin, so the SPA never deals with CORS or service addresses
- Fully automated build → scan → image → deploy flow with self-healing GitOps

---

## Architecture

```mermaid
flowchart TB
    user([Browser])
    lb["AWS Load Balancer<br/>(Service type LoadBalancer)"]

    subgraph vpc["AWS VPC · ap-south-1 · 2 Availability Zones"]
        subgraph pub["Public subnets"]
            jenkins["VM1 · Jenkins + SonarQube"]
            ops["VM2 · kubectl / Helm / Argo CD CLI"]
        end

        subgraph eks["EKS cluster · private subnets · 2 nodes"]
            fe["flight-frontend<br/>Nginx + React :80"]
            res["flight-reservation-service<br/>Spring Boot :8080"]
            chk["flight-checkin-service<br/>Spring Boot :8081"]
            argo["Argo CD"]
            mon["Prometheus · Grafana · Alertmanager"]
        end

        subgraph dbs["Database subnets"]
            rds[("Amazon RDS<br/>MariaDB 10.11")]
        end
    end

    ecr[("Amazon ECR<br/>3 repositories")]

    user --> lb --> fe
    fe -->|"/api/*"| res
    fe -->|"/api/checkin/*"| chk
    chk -->|"validates booking"| res
    res --> rds
    chk --> rds
    jenkins -->|"push images"| ecr
    ecr -->|"pull images"| eks
    ops -->|"kubectl / helm via private API endpoint"| eks
```

The frontend is served by **Nginx on port 80** and is the only entry point for the browser. It reverse-proxies:

| Path | Target |
|---|---|
| `/api/checkin/*` | `flight-checkin-service:8081` |
| `/api/*` | `flight-reservation-service:8080` |
| everything else | React static build (SPA fallback to `index.html`) |

### Delivery flow

```mermaid
flowchart LR
    dev([Developer]) -->|git push| gh[("GitHub<br/>main")]
    gh -->|checkout| jk["Jenkins<br/>10-stage pipeline"]
    jk --> build["Maven + Vite build"] --> sonar["SonarQube<br/>analysis"] --> docker["Docker build<br/>3 images"]
    docker -->|"push :BUILD_NUMBER"| ecr[("Amazon ECR")]
    jk -->|"commit new image tags<br/>to gitops/"| gh
    gh -->|"watched by"| argo["Argo CD<br/>auto-sync + self-heal"]
    argo -->|deploys| eks["EKS<br/>flight-reservation namespace"]
```

---

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React 19, Vite 6, React Router 7, Redux Toolkit, Axios, React Toastify |
| Reservation service | Java 21, Spring Boot 3.3.5, Spring Security, Spring Data JPA, JJWT, iTextPDF |
| Check-in service | Java 21, Spring Boot 3.3.5, Spring Security, Spring Data JPA, JJWT |
| Database | Amazon RDS MariaDB 10.11 |
| Containers | Docker · Nginx 1.29 (frontend) · Eclipse Temurin 21 JRE Alpine (backends, non-root user) |
| Infrastructure as Code | Terraform — modules: `vpc`, `security-groups`, `iam`, `ec2-jenkins`, `ec2-monitoring`, `eks`, `rds`, `s3`, `ecr`, `sns`, `cloudwatch` |
| Cloud | AWS — VPC, EC2, EKS, RDS, S3, ECR, IAM, CloudWatch, SNS |
| CI | Jenkins, Maven, npm, SonarQube (Community) |
| CD / GitOps | Argo CD, Kubernetes manifests + Kustomize |
| Monitoring | kube-prometheus-stack (Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics) via Helm |

---

## Screenshots

### Application

<table>
  <tr>
    <td align="center"><img src="../docs/screenshots/app/02-app-login.png" alt="Login page" width="290"><br><sub><b>Login</b></sub></td>
    <td align="center"><img src="../docs/screenshots/app/03-app-registration.png" alt="Registration page" width="290"><br><sub><b>Register</b></sub></td>
    <td align="center"><img src="../docs/screenshots/app/04-app-profile.png" alt="User profile page" width="290"><br><sub><b>Profile</b></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="../docs/screenshots/app/05-app-search-flights.png" alt="Search flights page" width="290"><br><sub><b>Search &amp; book flights</b></sub></td>
    <td align="center"><img src="../docs/screenshots/app/06-app-my-bookings.png" alt="My bookings page with ticket download" width="290"><br><sub><b>My bookings + PDF ticket</b></sub></td>
    <td align="center"><img src="../docs/screenshots/app/07-app-contact.png" alt="Contact page" width="290"><br><sub><b>Contact</b></sub></td>
  </tr>
</table>

**Data persisted in Amazon RDS** — bookings, flights and users written by the running application:

<p align="center">
  <img src="../docs/screenshots/aws/08-rds-data-stored.png" alt="MariaDB tables and rows on RDS" width="600">
</p>

### Infrastructure as Code (Terraform)

<table>
  <tr>
    <td align="center"><img src="../docs/screenshots/aws/10-terraform-init-validate.png" alt="terraform init and validate" width="420"><br><sub><b><code>terraform init</code> &amp; <code>validate</code></b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/11-terraform-aws-resources.png" alt="EC2 instances, EKS cluster and node group created by Terraform" width="420"><br><sub><b>Resources created: 2 EC2 VMs, EKS cluster, node group</b></sub></td>
  </tr>
</table>

### CI/CD

**Jenkins — pipeline #4 green across all stages (8 min 44 s):**

<p align="center">
  <img src="../docs/screenshots/aws/20-jenkins-pipeline-success.png" alt="Jenkins pipeline success" width="850">
</p>

**Argo CD — application `flight-reservation` is Healthy and Synced (3 Deployments, 3 Services, ConfigMap, Namespace):**

<p align="center">
  <img src="../docs/screenshots/aws/21-argocd-synced-healthy.png" alt="Argo CD application tree, healthy and synced" width="850">
</p>

<details>
<summary><b>SonarQube analysis</b> (click to expand)</summary>

<br>

Both backends are analysed on every pipeline run and pass the quality gate.

<table>
  <tr>
    <td align="center"><img src="../docs/screenshots/aws/22-sonarqube-projects.png" alt="SonarQube projects" width="290"><br><sub><b>Projects</b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/23-sonarqube-reservation-service.png" alt="SonarQube reservation service" width="290"><br><sub><b>Reservation service</b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/24-sonarqube-checkin-service.png" alt="SonarQube check-in service" width="290"><br><sub><b>Check-in service</b></sub></td>
  </tr>
</table>

</details>

### Monitoring & alerting

<table>
  <tr>
    <td align="center"><img src="../docs/screenshots/aws/34-grafana-cluster-networking.png" alt="Grafana cluster networking dashboard" width="420"><br><sub><b>Grafana — cluster networking (per namespace)</b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/36-grafana-node-exporter.png" alt="Grafana node exporter dashboard" width="420"><br><sub><b>Grafana — node CPU / memory</b></sub></td>
  </tr>
</table>

**CloudWatch alarms** (Jenkins CPU, monitoring-VM CPU, RDS CPU, RDS free storage) — all wired to an SNS email topic:

<p align="center">
  <img src="../docs/screenshots/aws/40-cloudwatch-alarms.png" alt="CloudWatch alarms" width="850">
</p>

<details>
<summary><b>More monitoring screenshots</b> — Prometheus, Grafana, CloudWatch (click to expand)</summary>

<br>

**Prometheus**

<table>
  <tr>
    <td align="center"><img src="../docs/screenshots/aws/30-prometheus-targets.png" alt="Prometheus target health" width="420"><br><sub><b>Target health</b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/31-prometheus-up-query.png" alt="Prometheus up query" width="420"><br><sub><b><code>up</code> query — all scrape targets</b></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="../docs/screenshots/aws/32-prometheus-app-pods.png" alt="kube_pod_info for flight-reservation namespace" width="420"><br><sub><b>Application pods in <code>flight-reservation</code></b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/33-prometheus-pod-cpu.png" alt="Pod CPU usage query" width="420"><br><sub><b>Pod CPU usage</b></sub></td>
  </tr>
</table>

**Grafana**

<table>
  <tr>
    <td align="center"><img src="../docs/screenshots/aws/35-grafana-compute-resources-pod.png" alt="Grafana compute resources by pod" width="420"><br><sub><b>Compute resources — pod</b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/37-grafana-api-server.png" alt="Grafana Kubernetes API server dashboard" width="420"><br><sub><b>Kubernetes API server</b></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="../docs/screenshots/aws/38-grafana-alertmanager.png" alt="Grafana Alertmanager overview" width="420"><br><sub><b>Alertmanager overview</b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/39-grafana-coredns.png" alt="Grafana CoreDNS dashboard" width="420"><br><sub><b>CoreDNS</b></sub></td>
  </tr>
</table>

**CloudWatch alarm detail**

<table>
  <tr>
    <td align="center"><img src="../docs/screenshots/aws/41-cloudwatch-jenkins-cpu.png" alt="Jenkins high CPU alarm" width="290"><br><sub><b>Jenkins VM CPU</b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/42-cloudwatch-monitoring-cpu.png" alt="Monitoring VM high CPU alarm" width="290"><br><sub><b>Monitoring VM CPU</b></sub></td>
    <td align="center"><img src="../docs/screenshots/aws/43-cloudwatch-rds-cpu.png" alt="RDS high CPU alarm" width="290"><br><sub><b>RDS CPU</b></sub></td>
  </tr>
</table>

</details>

---

## CI/CD pipeline (Jenkins + ECR)

The [`Jenkinsfile`](./Jenkinsfile) (Jenkins job *Script Path*: `aws/Jenkinsfile`) runs on the Terraform-provisioned Jenkins VM (VM1). It uses `timestamps()`, `disableConcurrentBuilds()` and a 60-minute timeout.

| # | Stage | What it does |
|---|---|---|
| 1 | **Verify AWS** | `aws sts get-caller-identity` and confirms the three ECR repositories exist |
| 2 | **Backend Build** | `mvn clean package` for the reservation and check-in services |
| 3 | **Frontend Build** | `npm ci` + `npm run build` (Vite), API base path set to `/api` |
| 4 | **SonarQube Analysis** | `mvn sonar:sonar` for both backends using the `sonarqube-token` credential |
| 5 | **Docker Build** | Builds the three images (reservation, check-in, frontend) |
| 6 | **ECR Login** | `aws ecr get-login-password` using the VM's IAM instance role |
| 7 | **Tag Images** | Tags images as `<account>.dkr.ecr.ap-south-1.amazonaws.com/<repo>:<BUILD_NUMBER>` |
| 8 | **Push Images to ECR** | Pushes the three immutable, build-numbered tags |
| 9 | **Update GitOps** | Rewrites the `image:` lines in `gitops/*-deployment.yaml`, commits and pushes to `main` |
| 10 | **Docker Cleanup** | Removes local images and prunes dangling layers |

**Credentials** ([`docs/JENKINS-CREDENTIALS.md`](./docs/JENKINS-CREDENTIALS.md)):

- `sonarqube-token` — SonarQube token (secret text)
- `github` — GitHub username + PAT, used by the *Update GitOps* stage to push back to `main`
- **No AWS access keys are stored in Jenkins** — ECR access comes from the VM1 IAM instance role.

---

## GitOps deployment (Argo CD + EKS)

The [`gitops/`](./gitops) folder holds the Kubernetes manifests for the `flight-reservation` namespace:

| Manifest | Purpose |
|---|---|
| `namespace.yaml` | `flight-reservation` namespace |
| `configmap.yaml` | RDS JDBC URLs, in-cluster booking-service URL, frontend URL |
| `reservation-deployment.yaml` / `-service.yaml` | Reservation backend, port 8080 |
| `checkin-deployment.yaml` / `-service.yaml` | Check-in backend, port 8081 |
| `frontend-deployment.yaml` / `-service.yaml` | Nginx + React, exposed with a `LoadBalancer` Service on port 80 |
| `secret.example.yaml` | Template for DB credentials (applied by hand, deliberately **not** part of `kustomization.yaml`, so Argo CD never overwrites it) |

Each backend Deployment sets CPU/memory requests and limits and has liveness and readiness probes. MariaDB is **not** a pod — the services connect to the private RDS instance.

[`argocd-application.yaml`](./argocd-application.yaml) points Argo CD at `gitops/` on `main` with **automated sync, self-heal and prune**, so a Jenkins image-tag commit is rolled out automatically and any manual `kubectl` drift is reverted.

```bash
kubectl apply -f argocd-application.yaml
argocd app get flight-reservation
argocd app sync flight-reservation
```

---

## Infrastructure (Terraform)

Everything lives in [`terraform/`](./terraform) and is split into modules wired together in `main.tf`.

| Module | Provisions |
|---|---|
| `vpc` | VPC `10.0.0.0/16`, public / private / database subnets across 2 AZs, Internet Gateway, NAT Gateway, route tables |
| `security-groups` | Jenkins SG (SSH 22, Jenkins 8080, SonarQube 9000 — **admin IP only**), monitoring SG (SSH — admin IP only), RDS SG (3306 — **VPC CIDR only**) |
| `iam` | Jenkins role (ECR + CloudWatch agent), monitoring role (CloudWatch read-only + EKS describe), EKS cluster and node roles |
| `ec2-jenkins` | VM1 `flight-reservation-dev-jenkins` — bootstraps Docker, Jenkins, Maven, Java 21 and a SonarQube container |
| `ec2-monitoring` | VM2 `flight-reservation-dev-monitoring` — bootstraps AWS CLI, kubectl, Helm, Argo CD CLI, MariaDB client |
| `eks` | Cluster `flight-reservation-dev-eks` (Kubernetes 1.35) with a **private-only API endpoint**, managed node group of 2 × `c7i-flex.large`, and an EKS access entry granting VM2 cluster-admin |
| `rds` | MariaDB 10.11 on `db.t3.micro`, 20 GiB gp3 (autoscaling to 100 GiB), **encrypted**, **not publicly accessible**, subnet-group in the database subnets |
| `s3` | Application-files bucket with versioning, server-side encryption and public access blocked |
| `ecr` | `flight-reservation-dev-reservation`, `-checkin`, `-frontend` |
| `sns` | Alerts topic with an email subscription |
| `cloudwatch` | Alarms: Jenkins CPU, monitoring CPU, RDS CPU (threshold 80 %) and RDS free storage (< 5 GiB) |

Helper scripts in [`terraform/scripts/`](./terraform/scripts): `create-checkin-db.sh`, `install-argocd.sh`, `install-monitoring.sh`, plus the EC2 user-data bootstrap scripts.

---

## Monitoring & alerting

- **In-cluster metrics** — `kube-prometheus-stack` is installed into the EKS cluster from VM2 with Helm, so Prometheus, Grafana, Alertmanager, node-exporter and kube-state-metrics run next to the workloads they watch. Values files: [`monitoring/`](./monitoring) (Grafana as `ClusterIP`, admin password from a Kubernetes Secret) and [`terraform/monitoring/`](./terraform/monitoring) (Grafana exposed through a `LoadBalancer`, used by `install-monitoring.sh`).
- **AWS-level alerts** — CloudWatch alarms on the two EC2 hosts and on RDS publish to an SNS topic that emails the administrator.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/kube-prometheus-stack-values.yaml
```

---

## Repository layout

This folder is one of three cloud editions inside the **flight-reservation-multicloud** repository. The application code is shared and lives at the repository root; everything in this folder is specific to AWS.

```
flight-reservation-multicloud/
├── frontend/ · FlightReservationApplication/ · FlightCheckInApplication/   # shared application (same code on every cloud)
├── aws/                              # <- this edition
│   ├── terraform/                    # AWS infrastructure (11 modules) + helper scripts
│   ├── gitops/                       # Kubernetes manifests synced by Argo CD
│   ├── monitoring/                   # kube-prometheus-stack values + Grafana secret template
│   ├── docs/                         # Jenkins credentials setup
│   ├── Jenkinsfile                   # CI pipeline (Jenkins job Script Path: aws/Jenkinsfile)
│   ├── argocd-application.yaml       # Argo CD Application definition
│   ├── README-DEPLOYMENT.md          # Detailed one-time deployment notes
│   └── README.md                     # this file
├── aws/  azure/  gcp/                # the three editions
└── docs/screenshots/                 # every screenshot used in the READMEs
```

---

## API reference

All endpoints except `register` and `login` require a JWT: `Authorization: Bearer <token>`.

### Users — `/api/users` (reservation service)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/register` | Register a user (public) |
| POST | `/login` | Authenticate and receive a JWT (public) |
| GET | `/{id}` | Get a user by ID |
| GET | `/userList` | List registered users |
| PUT | `/update/{id}` | Update a user's profile |

### Flights — `/api/flights` (reservation service)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/create` | Add a flight |
| GET | `/all` | List all flights |
| GET | `/search?origin=&destination=&departureDate=` | Search flights |
| PUT | `/update/{id}` | Update a flight |
| DELETE | `/delete/{id}` | Delete a flight |

### Bookings — `/api/bookings` (reservation service)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/book` | Create a booking |
| GET | `/user/{userId}` | List a user's bookings |
| GET | `/details/{bookingId}` | Get one booking |
| GET | `/download-ticket/{bookingId}` | Download the PDF e-ticket |

### Check-in — `/api/checkin` (check-in service)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/{bookingId}?numberOfBags=` | Check in a booking. The service calls the reservation service to confirm the booking exists and belongs to the caller |

---

## Run locally

The application is identical on every cloud, so the local-run instructions live once in the [root README](../README.md#run-locally).

---

## Deploy to AWS

> ⚠️ This creates billable resources (EKS control plane, NAT Gateway, 4 × `c7i-flex.large`, RDS). Run `terraform destroy` when you are done.

> **Working directory:** run the commands in this section from the `aws/` folder of the repository unless a step says otherwise. In Jenkins, set the pipeline job's *Script Path* to `aws/Jenkinsfile` and edit the repository name inside it where noted.

**1. Provision the infrastructure**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars    # then edit: admin_cidr, key_name, rds_password, alert_email
terraform init && terraform validate
terraform plan
terraform apply
```

Confirm the SNS subscription email that AWS sends to `alert_email`. Use `aws configure` or an instance role for AWS credentials — never put keys in Terraform files.

**2. Prepare the database and cluster access (from VM2, which is inside the VPC)**

```bash
RDS_HOST=<rds_endpoint> RDS_USER=<user> RDS_PASSWORD=<password> ./terraform/scripts/create-checkin-db.sh
aws eks update-kubeconfig --region ap-south-1 --name flight-reservation-dev-eks
./terraform/scripts/install-argocd.sh
```

**3. Configure Jenkins on VM1** — add the `sonarqube-token` and `github` credentials, define a SonarQube server named `Sonarqube`, and create a Pipeline job from SCM with *Script Path* `aws/Jenkinsfile`, and set `GITHUB_REPO` at the top of that file to your `owner/repo`.

**4. Fill in the environment values**

- `gitops/configmap.yaml` — replace `<RDS_ENDPOINT>` (`terraform output rds_endpoint`) and, once known, `<FRONTEND_LOADBALANCER_HOSTNAME>`.
- `argocd-application.yaml` — set `repoURL` to your repository. `gitops/*-deployment.yaml` — `YOUR_AWS_ACCOUNT_ID` in the placeholder image paths (the first Jenkins run rewrites them anyway).
- Create the DB credentials Secret from the template and apply it by hand:

```bash
cp gitops/secret.example.yaml gitops/secret.yaml     # edit with the real RDS credentials
kubectl create namespace flight-reservation
kubectl apply -f gitops/secret.yaml
```

**5. First release** — run the Jenkins pipeline so ECR contains images and the GitOps manifests point at them, then hand control to Argo CD:

```bash
kubectl apply -f argocd-application.yaml
kubectl get svc flight-frontend -n flight-reservation     # public address of the app
```

**6. Install monitoring**

```bash
./terraform/scripts/install-monitoring.sh
```

From here on, every push that goes through Jenkins is rolled out to the cluster automatically. More detail is in [`README-DEPLOYMENT.md`](./README-DEPLOYMENT.md).

---

## Security notes

- **Network** — the EKS API endpoint is private (reachable only from inside the VPC via VM2); RDS is in private database subnets, encrypted at rest and reachable only from within the VPC; Jenkins/SonarQube/SSH are open only to the administrator's IP.
- **Credentials at runtime** — the backends receive `SPRING_DATASOURCE_USERNAME` / `SPRING_DATASOURCE_PASSWORD` from a Kubernetes Secret and the JDBC URL from a ConfigMap. The Secret is applied manually and is intentionally excluded from the GitOps kustomization.
- **AWS access** — Jenkins and the monitoring VM use IAM instance roles; no AWS access keys are stored in Jenkins or in Git.
- **Containers** — backend images run as a non-root user.
- **Demo defaults** — the seeded `admin` account and the simulated payment page are for demonstration only.

---

## Roadmap

Ideas for taking this further:

- Run unit tests in the Jenkins pipeline (currently skipped for faster builds) and publish JaCoCo coverage to SonarQube
- Work through the open SonarQube findings
- Enforce `ROLE_ADMIN` at the API layer for `/api/flights/**` (admin actions are currently hidden in the UI; the API requires a valid JWT)
- Remote Terraform state (S3 + state locking) and a separate staging environment
- Ingress with TLS (AWS Load Balancer Controller) instead of a plain `LoadBalancer` Service; add HPAs
- Enable Spring Boot Actuator/Micrometer and a `ServiceMonitor` so Prometheus scrapes application metrics, not only cluster metrics
- `docker-compose.yml` for a one-command local stack
- Frontend tests (Testing Library is already a dependency) in the pipeline

---

## Author

**Anurag Patil** — DevOps Engineer

- GitHub: [@AnuragPatil-cloud](https://github.com/AnuragPatil-cloud)
- Email: [anurag.patil.devops@gmail.com](mailto:anurag.patil.devops@gmail.com)

If you're reviewing this project, the quickest tour is: the [architecture](#architecture) → the [Jenkins](#cicd-pipeline-jenkins--ecr) and [Argo CD](#gitops-deployment-argo-cd--eks) screenshots → the [`terraform/`](./terraform) modules.
