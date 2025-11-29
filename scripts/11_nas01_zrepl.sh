#!/usr/bin/env bash
set -euo pipefail

sudo true

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="${REPO_ROOT}/templates/zrepl/nas01.yml"
KEY_DIR="/etc/zrepl/keys"
KEY_PATH="${KEY_DIR}/id_ed25519_zrepl_nas01"
PUB_PATH="${KEY_PATH}.pub"

if [ ! -f "${TEMPLATE}" ]; then
  echo "Template not found at ${TEMPLATE}" >&2
  exit 1
fi

if ! command -v zrepl >/dev/null 2>&1; then
  echo "zrepl is not installed. Run scripts/06_install_zrepl.sh first." >&2
  exit 1
fi

sudo mkdir -p /etc/zrepl "${KEY_DIR}"

if [ ! -f "${KEY_PATH}" ]; then
  FQDN=$(hostname --fqdn 2>/dev/null || hostname)
  sudo ssh-keygen -t ed25519 -N "" -C "zrepl-nas01@${FQDN}" -f "${KEY_PATH}"
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
echo "Public key for this node:"
sudo cat "${PUB_PATH}"
echo
echo "Copy the above into nas02's /var/lib/zrepl/.ssh/authorized_keys with the stdinserver prefix if not already present:"
echo 'command="/usr/lib/zrepl/zrepl stdinserver" SSH_PUBLIC_KEY'

