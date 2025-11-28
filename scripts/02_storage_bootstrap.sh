#!/usr/bin/env bash
set -euo pipefail

sudo true
sudo mkdir -p /srv/nextcloud
sudo mkdir -p /srv/backups
if sudo zpool list tank >/dev/null 2>&1; then
  echo "zpool tank already exists"
else
  sudo zpool create -f tank mirror /dev/nvme0n1 /dev/nvme1n1
fi
sudo zpool set autotrim=on tank
sudo zpool set autoreplace=on tank
sudo zpool set listsnapshots=on tank
sudo zfs set compression=lz4 tank
sudo zfs set atime=off tank
if sudo zfs list tank/nextcloud-app >/dev/null 2>&1; then
  echo "dataset tank/nextcloud-app already exists"
else
  sudo zfs create -o mountpoint=/srv/nextcloud/app -o compression=lz4 -o atime=off -o recordsize=128K tank/nextcloud-app
fi
if sudo zfs list tank/nextcloud-sync >/dev/null 2>&1; then
  echo "dataset tank/nextcloud-sync already exists"
else
  sudo zfs create -o mountpoint=/srv/nextcloud/sync -o compression=lz4 -o atime=off -o recordsize=128K tank/nextcloud-sync
fi
if sudo zfs list tank/nextcloud-collab >/dev/null 2>&1; then
  echo "dataset tank/nextcloud-collab already exists"
else
  sudo zfs create -o mountpoint=/srv/nextcloud/collab -o compression=lz4 -o atime=off -o recordsize=16K tank/nextcloud-collab
fi
if sudo zfs list tank/nextcloud-db >/dev/null 2>&1; then
  echo "dataset tank/nextcloud-db already exists"
else
  sudo zfs create -o mountpoint=/srv/nextcloud/db -o compression=lz4 -o atime=off -o recordsize=16K -o primarycache=metadata tank/nextcloud-db
fi
if sudo zfs list tank/nextcloud-redis >/dev/null 2>&1; then
  echo "dataset tank/nextcloud-redis already exists"
else
  sudo zfs create -o mountpoint=/srv/nextcloud/redis -o compression=lz4 -o atime=off -o recordsize=16K -o primarycache=metadata tank/nextcloud-redis
fi
if sudo zfs list tank/backups >/dev/null 2>&1; then
  echo "dataset tank/backups already exists"
else
  sudo zfs create -o mountpoint=/srv/backups -o compression=lz4 -o atime=off -o recordsize=128K tank/backups
fi
sudo chown -R 33:33 /srv/nextcloud/app
sudo chown -R 33:33 /srv/nextcloud/sync
sudo chown -R 33:33 /srv/nextcloud/collab
sudo chown -R 999:999 /srv/nextcloud/db
sudo chown -R 999:999 /srv/nextcloud/redis



