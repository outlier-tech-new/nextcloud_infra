#!/usr/bin/env bash
set -euo pipefail

sudo true
sudo mkdir -p /etc/zrepl
sudo mkdir -p /etc/zrepl/keys
if [ -f /etc/zrepl/keys/id_ed25519 ]; then
  echo "zrepl key already exists"
else
  sudo ssh-keygen -t ed25519 -N "" -C "zrepl-$(hostname)" -f /etc/zrepl/keys/id_ed25519
fi
sudo install -m 600 /home/dtadmin/config/zrepl/primary.yaml /etc/zrepl/zrepl.yml
sudo chown root:root /etc/zrepl/zrepl.yml
sudo systemctl daemon-reload
sudo systemctl start zrepl
sudo systemctl enable zrepl
sudo systemctl status zrepl --no-pager



