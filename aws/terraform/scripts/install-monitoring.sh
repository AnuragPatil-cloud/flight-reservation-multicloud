#!/bin/bash
set -e

CLUSTER_NAME="${1:-flight-reservation-dev-eks}"
REGION="${2:-ap-south-1}"

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f "$(dirname "$0")/../monitoring/kube-prometheus-stack-values.yaml"
