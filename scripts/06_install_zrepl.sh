#!/usr/bin/env bash
set -euo pipefail

sudo true

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_DEB="${REPO_ROOT}/scripts/zrepl_0.6.1-2_amd64.deb"

if command -v zrepl >/dev/null 2>&1; then
  echo "zrepl already installed."
  exit 0
fi

sudo install -d -m 755 /usr/share/keyrings
KEYRING=/usr/share/keyrings/zrepl-archive-keyring.gpg

if ping -c 1 repo.zrepl.dev >/dev/null 2>&1; then
  if [ ! -f "$KEYRING" ]; then
    curl -fsSL https://repo.zrepl.dev/apt/apt-key.gpg | sudo gpg --dearmor -o "$KEYRING"
  else
    echo "Keyring $KEYRING already exists; skipping download. Remove the file to refresh."
  fi
  codename=$(lsb_release -cs)
  echo "deb [arch=amd64 signed-by=$KEYRING] https://repo.zrepl.dev/apt/ $codename main" | sudo tee /etc/apt/sources.list.d/zrepl.list
  sudo apt update
  sudo apt install -y zrepl
else
  echo "Unable to reach repo.zrepl.dev; falling back to local .deb."
  if [ ! -f "$LOCAL_DEB" ]; then
    echo "Local zrepl package not found at $LOCAL_DEB" >&2
    exit 1
  fi
  sudo dpkg -i "$LOCAL_DEB" || sudo apt -f install -y
fi

sudo systemctl enable zrepl
sudo systemctl stop zrepl || true
