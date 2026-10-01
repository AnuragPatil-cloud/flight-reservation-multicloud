# Jenkins credentials

Create these credentials in Jenkins (VM1 - `flight-reservation-dev-jenkins`):

- `sonarqube-token`: Secret text containing the SonarQube token.
- `github`: Username with password (a GitHub PAT works as the password) - used for the
  `git push` back to `main` in the GitOps stage.

## AWS / ECR authentication

This pipeline does **not** use a stored AWS access key. Attach an IAM role/instance
profile to the Jenkins EC2 instance (VM1) with at least:

- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`
- `ecr:PutImage`

scoped to the three repositories:

- `flight-reservation-dev-reservation`
- `flight-reservation-dev-checkin`
- `flight-reservation-dev-frontend`

With the role attached, `aws ecr get-login-password` and `docker push` in the
Jenkinsfile work with no credentials stored in Jenkins at all. This matches the
credentials rule in the runbook: no AWS keys in Jenkins, Git, or `terraform.tfvars`.

## Job configuration

Create a **Pipeline** job with *Pipeline script from SCM* pointing at this repository (branch `main`) and set **Script Path** to `aws/Jenkinsfile`.
The workspace root is the repository root, so the pipeline finds the shared `frontend/`, `FlightReservationApplication/` and `FlightCheckInApplication/` folders and the `aws/gitops/` manifests it updates.
