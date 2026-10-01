# Monitoring on EKS

Run the setup from VM2 after Terraform creates EKS:

```bash
aws eks update-kubeconfig --region ap-south-1 --name flight-reservation-dev-eks
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/kube-prometheus-stack-values.yaml
```

This installs Prometheus, Grafana, Alertmanager, node-exporter and kube-state-metrics in EKS.
