#!/usr/bin/env bash
set -euo pipefail

sudo true

SMART_EMAIL=${SMART_EMAIL:-admin@outliertechnology.co.uk}
SCRUB_CRON_FILE=/etc/cron.d/zpool-scrub
INOTIFY_VALUE=${INOTIFY_VALUE:-1048576}

sudo apt update
sudo apt upgrade -y
sudo apt install -y unattended-upgrades smartmontools
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive unattended-upgrades || true

sudo tee /etc/sysctl.d/99-redis.conf >/dev/null <<'EOF'
vm.overcommit_memory = 1
EOF

sudo tee /etc/sysctl.d/98-inotify.conf >/dev/null <<EOF
fs.inotify.max_user_watches = ${INOTIFY_VALUE}
EOF

sudo sysctl --system >/dev/null

for device in /dev/nvme0n1 /dev/nvme1n1; do
  if [ -e "$device" ] && ! sudo grep -q "^${device} " /etc/smartd.conf; then
    echo "${device} -a -m ${SMART_EMAIL}" | sudo tee -a /etc/smartd.conf >/dev/null
  fi
done

sudo systemctl enable --now smartmontools.service

sudo tee "${SCRUB_CRON_FILE}" >/dev/null <<'EOF'
0 3 1 * * root /sbin/zpool scrub tank
EOF
sudo chmod 644 "${SCRUB_CRON_FILE}"

echo "OS hardening complete. Review cron, sysctl, and SMART configurations as needed."

