#!/usr/bin/env bash
set -euo pipefail

sudo true

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="${REPO_ROOT}/templates"

sudo mkdir -p /srv/nextcloud /srv/nextcloud/sync /srv/nextcloud/collab /srv/nextcloud/db /srv/nextcloud/redis /srv/nextcloud/app

sudo install -m 640 "${TEMPLATE_DIR}/compose.env" /srv/nextcloud/.env
sudo install -m 640 "${TEMPLATE_DIR}/nextcloud.env" /srv/nextcloud/nextcloud.env
sudo install -m 640 "${TEMPLATE_DIR}/db.env" /srv/nextcloud/db.env
sudo install -m 644 "${TEMPLATE_DIR}/docker-compose.yml" /srv/nextcloud/docker-compose.yml

sudo chown 0:0 /srv/nextcloud/.env /srv/nextcloud/nextcloud.env /srv/nextcloud/db.env /srv/nextcloud/docker-compose.yml
sudo chown -R 33:33 /srv/nextcloud/app /srv/nextcloud/sync /srv/nextcloud/collab
sudo chown -R 999:999 /srv/nextcloud/db /srv/nextcloud/redis
