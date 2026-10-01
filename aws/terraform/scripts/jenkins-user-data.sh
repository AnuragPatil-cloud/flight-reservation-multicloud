#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg unzip git maven openjdk-21-jre-headless docker.io

# SonarQube kernel settings
echo "vm.max_map_count=524288" > /etc/sysctl.d/99-sonarqube.conf
echo "fs.file-max=131072" >> /etc/sysctl.d/99-sonarqube.conf
sysctl --system >/dev/null

systemctl enable --now docker

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | tee /etc/apt/keyrings/jenkins.asc >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/jenkins.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y jenkins
systemctl enable --now jenkins
usermod -aG docker jenkins
systemctl restart jenkins

docker volume create sonarqube_data || true
docker volume create sonarqube_extensions || true
docker volume create sonarqube_logs || true

docker rm -f sonarqube 2>/dev/null || true
docker run -d   --name sonarqube   --restart unless-stopped   -p 9000:9000   -v sonarqube_data:/opt/sonarqube/data   -v sonarqube_extensions:/opt/sonarqube/extensions   -v sonarqube_logs:/opt/sonarqube/logs   sonarqube:community
