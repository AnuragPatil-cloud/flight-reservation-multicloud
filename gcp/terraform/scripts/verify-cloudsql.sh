#!/bin/bash
# Quick connectivity check from the monitoring/admin VM (inside the VPC) to the private Cloud SQL instance.
# Both application databases are created by Terraform - this only confirms you can reach them.
#
# Usage: DB_HOST=<cloudsql_private_ip> DB_USER=flightadmin DB_PASSWORD=... ./verify-cloudsql.sh
set -euo pipefail

: "${DB_HOST:?Set DB_HOST (terraform output cloudsql_private_ip)}"
: "${DB_USER:?Set DB_USER}"
: "${DB_PASSWORD:?Set DB_PASSWORD}"

mysql -h "${DB_HOST}" -P 3306 -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SHOW DATABASES;"
