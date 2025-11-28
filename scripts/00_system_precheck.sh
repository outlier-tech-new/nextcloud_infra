#!/usr/bin/env bash
set -euo pipefail

sudo true
hostnamectl
lsb_release -a
uname -a
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
df -h
snap list || true
command -v zpool >/dev/null 2>&1 && zpool status || true
command -v docker >/dev/null 2>&1 && docker info || true



