#!/usr/bin/env bash
set -euo pipefail

sudo true
sudo zpool status
sudo zfs list
cd /srv/nextcloud
sudo docker compose ps
sudo docker compose exec -T nextcloud_app php occ status || true
sudo systemctl status zrepl --no-pager
sudo zrepl status || true



