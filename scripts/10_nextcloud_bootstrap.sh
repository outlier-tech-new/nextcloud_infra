#!/usr/bin/env bash
set -euo pipefail

NEXTCLOUD_DIR=/srv/nextcloud
ENV_FILE=${NEXTCLOUD_DIR}/nextcloud.env
DB_ENV_FILE=${NEXTCLOUD_DIR}/db.env
COMPOSE_PROJECT_DIR=${NEXTCLOUD_DIR}
CRON_FILE=/etc/cron.d/nextcloud-cron

sudo true

require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
}

require_file "${ENV_FILE}"
require_file "${DB_ENV_FILE}"

set -a
source "${ENV_FILE}"
source "${DB_ENV_FILE}"
set +a

if [[ "${NEXTCLOUD_ADMIN_PASSWORD}" == changeme* ]]; then
  echo "NEXTCLOUD_ADMIN_PASSWORD must be set to a non-placeholder value in ${ENV_FILE}" >&2
  exit 1
fi

compose() {
  sudo docker compose --project-directory "${COMPOSE_PROJECT_DIR}" "$@"
}

if ! compose ps --services | grep -qx nextcloud; then
  echo "Nextcloud service is not running. Start it with scripts/05_nextcloud_stack_up.sh first." >&2
  exit 1
fi

installed=0
if compose exec -T --user 33 nextcloud php occ status >/dev/null 2>&1; then
  installed=1
fi

if [ "${installed}" -eq 0 ]; then
  compose exec -T --user 33 nextcloud php occ maintenance:install \
    --database "mysql" \
    --database-host "${MYSQL_HOST}" \
    --database-name "${MYSQL_DATABASE}" \
    --database-user "${MYSQL_USER}" \
    --database-pass "${MYSQL_PASSWORD}" \
    --admin-user "${NEXTCLOUD_ADMIN_USER}" \
    --admin-pass "${NEXTCLOUD_ADMIN_PASSWORD}" \
    --data-dir "${NEXTCLOUD_DATA_DIR}"
fi

compose exec -T --user 33 nextcloud php occ maintenance:mode --off >/dev/null 2>&1 || true

IFS=' ' read -r -a domain_array <<< "${NEXTCLOUD_TRUSTED_DOMAINS}"
if [ "${#domain_array[@]}" -eq 0 ]; then
  domain_array=("localhost")
fi

index=0
for domain in "${domain_array[@]}"; do
  compose exec -T --user 33 nextcloud php occ config:system:set trusted_domains "${index}" --value="${domain}" --type=string
  index=$((index + 1))
done

if [ -n "${OVERWRITEPROTOCOL:-}" ]; then
  compose exec -T --user 33 nextcloud php occ config:system:set overwriteprotocol --value="${OVERWRITEPROTOCOL}" --type=string
fi

if [ -n "${OVERWRITECLIURL:-}" ]; then
  compose exec -T --user 33 nextcloud php occ config:system:set overwrite.cli.url --value="${OVERWRITECLIURL}" --type=string
fi

compose exec -T --user 33 nextcloud php occ background:cron

sudo tee "${CRON_FILE}" >/dev/null <<'EOF'
*/5 * * * * root cd /srv/nextcloud && docker compose exec -T --user 33 nextcloud php occ system:cron >/dev/null 2>&1
EOF
sudo chmod 644 "${CRON_FILE}"

if [ -n "${NEXTCLOUD_APPS:-}" ]; then
  IFS=' ' read -r -a apps <<< "${NEXTCLOUD_APPS}"
  for app in "${apps[@]}"; do
    compose exec -T --user 33 nextcloud php occ app:install "${app}" >/dev/null 2>&1 || true
  done
fi

echo "Nextcloud bootstrap complete."

