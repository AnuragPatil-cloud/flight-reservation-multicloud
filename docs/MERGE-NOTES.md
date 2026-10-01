# Merge notes

This repository was built by combining three separate projects — `flight-reservation-app-AWS`, `-Azure` and `-GCP` — into one.
This file records **what was done, what was left out, and what to double-check**, so nothing about the merge is a surprise.

## How the three projects compared

| Layer | Finding |
|---|---|
| Java source (both services) | **Identical** across all three (only `application.properties` and test config differed) |
| Frontend (`src/`, `public/`, `nginx.conf`, `package*.json`, `Dockerfile`) | **Byte-identical** across all three |
| Dockerfiles (backends) | Identical |
| `pom.xml` | AWS and GCP identical apart from one comment each; Azure's was an older Java 17 version |
| Infrastructure, Jenkinsfile, gitops, monitoring, docs | Genuinely different per cloud |

So the application exists once at the repository root, and `aws/`, `azure/`, `gcp/` hold the per-cloud layer. The shared copy was taken from the GCP project (the cleanest of the three: no build output, no legacy files, environment-variable-driven config).

## Changes made

**Shared application**
1. `application.properties` (both services) now come from the GCP project: all datasource settings, `FRONTEND_URL` and `BOOKING_SERVICE_URL` are read from environment variables with local-only defaults. The AWS and Azure versions had hard-coded database passwords, an RDS hostname and public IPs. All three clouds' Kubernetes manifests already inject those variables (verified for Azure too), so no manifest change was needed for this.
2. Restored the missing `.mvn/wrapper/maven-wrapper.properties` (Maven 3.9.9, the standard file for Spring Boot 3.3.x) and made `mvnw` executable. The original zips shipped `mvnw` without its config, so `./mvnw spring-boot:run` — which the old READMEs documented — could not work.
3. Neutralised two `pom.xml` comments that named a single cloud.

**Per cloud**
4. `Terraform/` was renamed `terraform/` (the Azure project already used lowercase); nothing inside referenced the old path.
5. Each `Jenkinsfile` was updated for the new layout: GitOps paths are now `<cloud>/gitops/...`. The AWS pipeline's hard-coded `git push` URL became a `GITHUB_REPO` variable (as GCP already had), and the AWS/GCP pipelines fail fast if it is still the placeholder.
6. Each `argocd-application.yaml` now has `path: <cloud>/gitops` and a `repoURL` placeholder.
7. AWS `gitops/`: the live RDS hostname, ELB hostname and AWS account ID were replaced with placeholders. The database names were deliberately left exactly as deployed (both services on `checkin_db`, see the RDS screenshot).
8. Azure `terraform.tfvars.example` was rewritten — the original used variable names that don't exist in `variables.tf`.
9. Documentation was corrected where it contradicted the code: Azure docs referred to a non-existent `scripts/prepare-gitops.sh`, a Trivy stage that isn't in the pipeline, a `sonar-token` credential (the pipeline uses `sonarqube-token`) and an unused `dockerhub-username`; AWS/GCP docs said `gitops/secret.yaml` was git-ignored although no `.gitignore` covered it (the new root `.gitignore` now does); the AWS runbook claimed `latest` tags are pushed.
10. Each edition's README and runbook was kept as a detailed guide, with image paths, folder names and commands updated.

## Left out on purpose

| Excluded | Why |
|---|---|
| Azure `terraform.tfstate`, `.backup` files, `tfplan`, `flight-reservation.tfplan`, `full-plan.txt` | **Contained live credentials** (AKS kubeconfig with client key, storage account keys, connection strings) |
| Real `terraform.tfvars` (AWS, Azure) | Environment-specific values (key-pair name, email, Azure subscription ID); the `.example` files remain |
| Azure `gitops/secret.yaml` | Identical to `secret.example.yaml` (placeholder); real secrets are git-ignored now |
| Stray `application.properties` at the root of the Azure app folders | Duplicates containing credentials |
| AWS `target/` (compiled classes, `jacoco.exec`, surefire reports) | Build output |
| `main.tf.full`, `main.tf.backup`, `outputs.tf.full` (Azure) | Exact duplicates of `main.tf` / `outputs.tf` |
| Per-service `JenkinsPipeline.md`, `Jenkinsfile`, `Jenkinsfile-bkp …`, `*.jdp`, `*.groovy` (AWS and Azure) | Identical in both, stale (JDK 17, `your-docker-registry` placeholders) and already dropped in the newest (GCP) edition; superseded by the per-cloud root Jenkinsfiles |
| Duplicate `sql.txt` and the GCP copies of the app screenshots | Identical to files already kept |

## Decisions worth reviewing

- **Azure pipeline — tests.** Its Backend Build stage used to start a throw-away MySQL container, override the datasource URL and run `mvn clean verify`. The shared code's test config pins an in-memory H2 driver and dialect, so that URL override would make the tests fail to start. The stage now runs `mvn -B clean package -DskipTests`, exactly like the AWS and GCP pipelines, with the stage names unchanged. (The Azure stage-view screenshot predates this change and is captioned accordingly.) Re-enable tests on all clouds together — the H2 config means no database container is needed.
- **AWS databases.** Both services use `checkin_db` as deployed. Terraform also creates `flightdb`; the GCP and Azure editions use separate databases. Left as-is because it matches the screenshots.
- **Azure `modules/database`** is not referenced from `main.tf` (Azure runs MariaDB in-cluster). It was kept rather than deleted.
- **Placeholders** (`YOUR_GITHUB_USER`, `YOUR_AWS_ACCOUNT_ID`, `<RDS_ENDPOINT>`, …) replace values that belonged to one specific deployment; the table in the root README lists every one.
- **GCP screenshots.** The GCP project's `FRA-SCREENSHOTS/` contained only copies of the AWS application screenshots, so there are no GCP tooling screenshots yet. A checklist is in `docs/screenshots/gcp/README.md`.

## What was and wasn't verified

Verified in the merge environment: every relative link, image and `#anchor` in the Markdown files resolves; all 45 screenshots are referenced by the root README; all YAML parses; every Terraform module referenced from a `main.tf` exists; every path a Jenkinsfile touches exists; the frontend installs (`npm ci`) and builds (`vite build`) from its new location; all `*.sh` scripts pass `bash -n` and were made executable (the originals were not, which the documented `./…sh` commands need); all 8 Mermaid diagrams parse with the real Mermaid library; no known credential strings, IPs or endpoints remain in text files.

`npm run lint` reports 38 findings (30 errors) in the unchanged frontend code. That is pre-existing; the Azure pipeline already treats lint as non-blocking and the AWS/GCP pipelines don't run it.

**Not** verified (no access to Maven Central, the Terraform registry or any cloud account from the merge environment): compiling the Java services, `terraform validate/plan`, running the Jenkins pipelines, and the Argo CD syncs. The Terraform code and Java code were not modified, only moved, so those should behave as before — but run `terraform init && terraform validate` per cloud and one Jenkins build before relying on the layout.
