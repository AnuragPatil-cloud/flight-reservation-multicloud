# Jenkins credentials

Create these credentials in Jenkins (VM1 - `flight-reservation-dev-jenkins`):

- `sonarqube-token`: Secret text containing the SonarQube token.
- `github`: Username with password (a GitHub PAT works as the password) - used for the
  `git push` back to `main` in the GitOps stage.

Also define a SonarQube server in *Manage Jenkins -> System* named `Sonarqube` (this is the name the
`Jenkinsfile` uses in `SONARQUBE_ENV`), pointing at `http://localhost:9000` (SonarQube runs on the same VM).

## Google Cloud / Artifact Registry authentication

This pipeline does **not** use a stored service account key. The Jenkins VM runs as the Terraform-created
service account `fra-dev-jenkins@<project-id>.iam.gserviceaccount.com`, and `gcloud` on the VM picks up that
identity automatically from the metadata server.

That service account is granted:

| Role | Scope | Why |
|---|---|---|
| `roles/artifactregistry.writer` | the `flight-reservation-dev` repository only | `docker push` |
| `roles/logging.logWriter`, `roles/monitoring.metricWriter` | project | Ops Agent logs and metrics |

The *Artifact Registry Login* stage runs
`gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://<region>-docker.pkg.dev`,
so no credentials are stored in Jenkins, Git, or `terraform.tfvars`.

Do not create or download service account keys for this project.

## Job configuration

Create a **Pipeline** job with *Pipeline script from SCM* pointing at this repository (branch `main`) and set **Script Path** to `gcp/Jenkinsfile`.
The workspace root is the repository root, so the pipeline finds the shared `frontend/`, `FlightReservationApplication/` and `FlightCheckInApplication/` folders and the `gcp/gitops/` manifests it updates.
