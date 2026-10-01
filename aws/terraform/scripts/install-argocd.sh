#!/bin/bash
set -e

CLUSTER_NAME="${1:-flight-reservation-dev-eks}"
REGION="${2:-ap-south-1}"

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd --namespace argocd
