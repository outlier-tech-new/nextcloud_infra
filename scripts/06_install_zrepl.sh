#!/usr/bin/env bash
set -euo pipefail

sudo true
sudo install -d -m 755 /usr/share/keyrings
KEYRING=/usr/share/keyrings/zrepl-archive-keyring.gpg
if ping -c 1 repo.zrepl.dev >/dev/null 2>&1; then
  if [ ! -f "$KEYRING" ]; then
    curl -fsSL https://repo.zrepl.dev/apt/apt-key.gpg | sudo gpg --dearmor -o "$KEYRING"
  else
    echo "Keyring $KEYRING already exists; skipping download. Remove the file to refresh."
  fi
  CODENAME=$(lsb_release -cs)
  echo "deb [arch=amd64 signed-by=$KEYRING] https://repo.zrepl.dev/apt/ $CODENAME main" | sudo tee /etc/apt/sources.list.d/zrepl.list
else
  echo "Unable to resolve repo.zrepl.dev; skipping repository configuration." >&2
  exit 1
fi
sudo apt update
sudo apt install -y zrepl
sudo systemctl enable zrepl
sudo systemctl stop zrepl || true



