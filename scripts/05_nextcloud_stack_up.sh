#!/usr/bin/env bash
set -euo pipefail

sudo true
cd /srv/nextcloud

require_file() {
  local file="$1"
  if ! sudo test -f "$file"; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
}

read_secret() {
  local file="$1"
  local key="$2"
  local value
  value=$(sudo awk -F= -v key="$key" '$1==key {print $2; exit}' "$file")
  value=${value%$'\r'}
  if [ -z "$value" ]; then
    echo "Value for ${key} in ${file} is missing" >&2
    exit 1
  fi
  if [[ "$value" == changeme* ]]; then
    echo "Value for ${key} in ${file} still uses placeholder 'changeme'; update secrets before proceeding." >&2
    exit 1
  fi
  printf '%s' "$value"
}

require_file ".env"
require_file "nextcloud.env"
require_file "db.env"

REDIS_HOST_PASSWORD=$(read_secret ".env" "REDIS_HOST_PASSWORD")
MYSQL_ROOT_PASSWORD=$(read_secret "db.env" "MYSQL_ROOT_PASSWORD")

export REDIS_HOST_PASSWORD

compose() {
  sudo --preserve-env=REDIS_HOST_PASSWORD docker compose "$@"
}

compose pull
compose up -d db redis

echo "Waiting for MariaDB service to accept connections..."
db_ready=0
for attempt in {1..12}; do
  if compose exec -T db mariadb-admin ping -h localhost -u root "-p${MYSQL_ROOT_PASSWORD}" --silent; then
    db_ready=1
    break
  fi
  sleep 5
done

if [ "$db_ready" -ne 1 ]; then
  echo "MariaDB did not become ready; check container logs." >&2
  compose logs db
  exit 1
fi

compose up -d
compose ps
compose logs --tail=50 nextcloud || true

echo "Waiting for Nextcloud service to become ready..."
app_ready=0
for attempt in {1..12}; do
  if compose ps --status running --services | grep -qx nextcloud; then
    app_ready=1
    break
  fi
  sleep 5
done

if [ "$app_ready" -ne 1 ]; then
  echo "Nextcloud service failed to reach running state; inspect logs above." >&2
  exit 1
fi

compose exec -T --user 33 nextcloud php occ status || true



