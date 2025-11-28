#!/usr/bin/env bash
set -euo pipefail

sudo true
if snap list | grep -q "^nextcloud"; then
  sudo snap stop nextcloud || true
  sudo snap disable nextcloud || true
  sudo snap remove nextcloud
fi
if snap list | grep -q "^nextcloud"; then
  echo "nextcloud snap still present"
else
  echo "nextcloud snap removed"
fi
sudo rm -rf /var/snap/nextcloud
sudo rm -rf /home/"$USER"/snap/nextcloud



