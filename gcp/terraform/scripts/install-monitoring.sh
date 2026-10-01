#!/bin/bash
# Installs kube-prometheus-stack (Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics)
# into the GKE cluster. Run this ON the monitoring/admin VM.
#
# Usage: [ADMIN_CIDR=1.2.3.4/32] [GRAFANA_ADMIN_PASSWORD=...] ./install-monitoring.sh [cluster-name] [zone] [project-id]
#
# - Grafana's admin password is read from the "grafana-admin" Secret. If it does not exist yet it is created
#   here (from GRAFANA_ADMIN_PASSWORD, or a random one that is printed once).
# - Grafana stays ClusterIP (use kubectl port-forward) unless ADMIN_CIDR is set; then it is exposed through a
#   LoadBalancer that only accepts traffic from that CIDR.
set -euo pipefail

CLUSTER_NAME="${1:-flight-reservation-dev-gke}"
ZONE="${2:-asia-south1-a}"
PROJECT_ID="${3:-$(curl -fsS -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/project/project-id)}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --zone "${ZONE}" --project "${PROJECT_ID}" --internal-ip

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

if ! kubectl -n monitoring get secret grafana-admin >/dev/null 2>&1; then
  GRAFANA_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-$(openssl rand -base64 18)}"
  kubectl -n monitoring create secret generic grafana-admin \
    --from-literal=admin-user=admin \
    --from-literal=admin-password="${GRAFANA_PASSWORD}"
  echo "Created Secret monitoring/grafana-admin. Grafana login: admin / ${GRAFANA_PASSWORD}"
fi

EXTRA_ARGS=()
if [ -n "${ADMIN_CIDR:-}" ]; then
  EXTRA_ARGS+=(--set grafana.service.type=LoadBalancer)
  EXTRA_ARGS+=(--set "grafana.service.loadBalancerSourceRanges[0]=${ADMIN_CIDR}")
fi

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values "${REPO_ROOT}/monitoring/kube-prometheus-stack-values.yaml" \
  "${EXTRA_ARGS[@]}"

echo
echo "Done. Grafana: kubectl -n monitoring get svc kube-prometheus-stack-grafana"
