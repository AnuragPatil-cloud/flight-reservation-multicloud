#!/bin/bash
# Bootstrap for the monitoring / administration VM (Ubuntu 24.04 on Compute Engine).
# Installs: gcloud CLI, kubectl, GKE auth plugin, Helm, Argo CD CLI, MySQL client, Ops Agent.
# This is the host that talks to the PRIVATE GKE control plane endpoint.
#
# Compute Engine runs the startup script on EVERY boot, so the real work is guarded by a marker file.
set -euo pipefail

MARKER=/var/lib/flight-reservation-monitoring.bootstrapped
if [ -f "${MARKER}" ]; then
  echo "Monitoring VM already bootstrapped - nothing to do."
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg unzip git jq mysql-client apt-transport-https

# Google Cloud CLI, kubectl and the GKE auth plugin from Google's apt repository
install -m 0755 -d /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get update
apt-get install -y google-cloud-cli kubectl google-cloud-cli-gke-gcloud-auth-plugin

# Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Argo CD CLI
curl -fsSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Ops Agent
curl -fsSL -o /tmp/add-google-cloud-ops-agent-repo.sh https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash /tmp/add-google-cloud-ops-agent-repo.sh --also-install

# Prometheus/Grafana are installed into GKE from this host with Helm (scripts/install-monitoring.sh).

touch "${MARKER}"
echo "Monitoring VM bootstrap finished."
