#!/usr/bin/env bash
set -euo pipefail

sudo true
sudo mkdir -p /srv/nextcloud
sudo mkdir -p /srv/nextcloud/sync
sudo mkdir -p /srv/nextcloud/collab
sudo mkdir -p /srv/nextcloud/db
sudo mkdir -p /srv/nextcloud/redis
sudo mkdir -p /srv/nextcloud/app
sudo install -m 640 ../templates/compose.env /srv/nextcloud/.env
sudo install -m 640 ../templates/nextcloud.env /srv/nextcloud/nextcloud.env
sudo install -m 640 ../templates/db.env /srv/nextcloud/db.env
sudo install -m 644 ../templates/docker-compose.yml /srv/nextcloud/docker-compose.yml
sudo chown 0:0 /srv/nextcloud/.env
sudo chown 0:0 /srv/nextcloud/nextcloud.env
sudo chown 0:0 /srv/nextcloud/db.env
sudo chown 0:0 /srv/nextcloud/docker-compose.yml
sudo chown -R 33:33 /srv/nextcloud/app
sudo chown -R 33:33 /srv/nextcloud/sync
sudo chown -R 33:33 /srv/nextcloud/collab
sudo chown -R 999:999 /srv/nextcloud/db
sudo chown -R 999:999 /srv/nextcloud/redis

