#!/usr/bin/env bash
set -euo pipefail

sudo true

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${REPO_ROOT}/templates/zrepl/nas02.yml"
KEY_DIR="/etc/zrepl/keys"
KEY_PATH="${KEY_DIR}/id_ed25519_zrepl_nas02"
PUB_PATH="${KEY_PATH}.pub"
AUTHORIZED_DIR="/var/lib/zrepl/.ssh"
AUTHORIZED_FILE="${AUTHORIZED_DIR}/authorized_keys"

if [ ! -f "${TEMPLATE}" ]; then
  echo "Template not found at ${TEMPLATE}" >&2
  exit 1
fi

if ! command -v zrepl >/dev/null 2>&1; then
  echo "zrepl is not installed. Run scripts/06_install_zrepl.sh first." >&2
  exit 1
fi

sudo mkdir -p /etc/zrepl "${KEY_DIR}"
sudo install -d -m 700 -o zrepl -g zrepl "${AUTHORIZED_DIR}"

if [ ! -f "${KEY_PATH}" ]; then
  FQDN=$(hostname --fqdn 2>/dev/null || hostname)
  sudo ssh-keygen -t ed25519 -N "" -C "zrepl-nas02@${FQDN}" -f "${KEY_PATH}"
  echo "Generated zrepl key at ${KEY_PATH}"
fi

sudo install -m 600 "${TEMPLATE}" /etc/zrepl/zrepl.yml

if ! sudo zrepl configcheck; then
  echo "zrepl configcheck failed; review /etc/zrepl/zrepl.yml" >&2
  exit 1
fi

sudo systemctl daemon-reload
sudo systemctl enable --now zrepl
sudo systemctl restart zrepl
sudo zrepl status

echo
echo "Public key for this node (if nas02 ever needs to initiate outbound replication):"
sudo cat "${PUB_PATH}"
echo
echo "Ensure nas01's public key (id_ed25519_zrepl_nas01.pub) appears in ${AUTHORIZED_FILE} with:"
echo 'command="/usr/lib/zrepl/zrepl stdinserver" SSH_PUBLIC_KEY'

