# GCP credentials

Do not store service account keys or access tokens in Terraform files or Git.

## Running Terraform from your workstation (or Cloud Shell)

```bash
gcloud auth login
gcloud auth application-default login          # credentials Terraform uses
gcloud config set project YOUR_PROJECT_ID
gcloud auth application-default set-quota-project YOUR_PROJECT_ID

# A brand-new project needs these two APIs before Terraform can enable the rest:
gcloud services enable serviceusage.googleapis.com cloudresourcemanager.googleapis.com
```

The account you apply with needs permission to create everything in this stack. `roles/owner` on a
dedicated dev project is the simplest; otherwise combine Compute Admin, Kubernetes Engine Admin,
Cloud SQL Admin, Service Networking Admin, Artifact Registry Admin, Storage Admin, Monitoring Admin,
Service Account Admin, Project IAM Admin and Service Usage Admin.

## VMs

The Jenkins and monitoring VMs authenticate as their own Terraform-created service accounts
(attached to the instance). Nothing needs `gcloud auth login` on the VMs, and no key files exist.

## SSH

Both VMs use OS Login. Connect with:

```bash
gcloud compute ssh flight-reservation-dev-jenkins    --zone asia-south1-a --tunnel-through-iap
gcloud compute ssh flight-reservation-dev-monitoring --zone asia-south1-a --tunnel-through-iap
```

`--tunnel-through-iap` uses Identity-Aware Proxy (enabled by `enable_iap_ssh = true`); drop it to use
the VM's public IP, which the firewall only opens to `admin_cidr`.
