#!/bin/bash
# Installs Argo CD into the GKE cluster. Run this ON the monitoring/admin VM
# (the GKE control plane endpoint is private).
#
# Usage: ./install-argocd.sh [cluster-name] [zone] [project-id]
set -euo pipefail

CLUSTER_NAME="${1:-flight-reservation-dev-gke}"
ZONE="${2:-asia-south1-a}"
PROJECT_ID="${3:-$(curl -fsS -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/project/project-id)}"

gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --zone "${ZONE}" --project "${PROJECT_ID}" --internal-ip

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd --namespace argocd

echo
echo "Argo CD installed. Initial admin password:"
echo "  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo "Open the UI from your laptop through the admin VM:"
echo "  kubectl -n argocd port-forward svc/argocd-server 8080:443     # on the VM, or use an SSH tunnel"
