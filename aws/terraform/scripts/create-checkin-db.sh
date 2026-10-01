#!/bin/bash
set -euo pipefail

: "${RDS_HOST:?Set RDS_HOST}"
: "${RDS_USER:?Set RDS_USER}"
: "${RDS_PASSWORD:?Set RDS_PASSWORD}"

mysql -h "${RDS_HOST}" -P 3306 -u "${RDS_USER}" -p"${RDS_PASSWORD}" \
  -e "CREATE DATABASE IF NOT EXISTS checkin_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo "checkin_db is ready."
