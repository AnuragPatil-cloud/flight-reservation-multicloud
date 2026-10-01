# Monitoring stack

The monitoring/admin VM (`flight-reservation-dev-monitoring`) is the administration host. The monitoring
stack runs **inside the GKE cluster** rather than on the VM, so it does not compete for the VM's resources.

Stack: `kube-prometheus-stack` (Prometheus + Grafana + Alertmanager + node-exporter + kube-state-metrics).
Argo CD (GitOps controller) is installed separately with `terraform/scripts/install-argocd.sh`.

Install it from the monitoring/admin VM (the GKE control plane endpoint is private) after the application is healthy:

```bash
# on the monitoring/admin VM
./terraform/scripts/install-monitoring.sh
```

The script fetches cluster credentials, creates the `grafana-admin` Secret if it is missing (random password,
printed once, or `GRAFANA_ADMIN_PASSWORD`), and runs `helm upgrade --install` with
[`kube-prometheus-stack-values.yaml`](./kube-prometheus-stack-values.yaml).

Open Grafana without exposing it publicly:

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

To expose Grafana through a LoadBalancer restricted to your IP instead, run the script with
`ADMIN_CIDR=<your-ip>/32`.

GKE notes: etcd, scheduler, controller-manager and kube-proxy scraping is turned off in the values file
because GKE's managed control plane does not expose them. GCP-level alerts (VM CPU, Cloud SQL CPU/disk)
are defined in Terraform (`modules/cloud-monitoring`) and delivered by email.

Application-specific scraping can be added later if Actuator/Micrometer endpoints are enabled in the Spring Boot services.
