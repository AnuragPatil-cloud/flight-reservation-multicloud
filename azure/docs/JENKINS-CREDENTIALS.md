# Jenkins credentials

Create these credentials in Jenkins:

- `dockerhub-creds`: Username with password type.
- `github`: Username with password (a GitHub PAT works as the password) - used for the `git push` back to `main` in the GitOps stage.
- `sonarqube-token`: Secret text containing the SonarQube token.

Also define a SonarQube server in *Manage Jenkins -> System* named `Sonarqube` (the name the `Jenkinsfile` uses).

## Job configuration

Create a **Pipeline** job with *Pipeline script from SCM* pointing at this repository (branch `main`) and set **Script Path** to `azure/Jenkinsfile`.
The workspace root is the repository root, so the pipeline finds the shared `frontend/`, `FlightReservationApplication/` and `FlightCheckInApplication/` folders and the `azure/gitops/` manifests it updates.
