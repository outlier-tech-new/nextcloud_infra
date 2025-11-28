# NAS Hardening & Final Configuration Checklist

Use this list to complete platform-level configuration before cloning to the second node or onboarding users. Mark items off as they are finished.

---

## 1. Operating System Baseline

- [ ] Apply outstanding security updates: `sudo apt update && sudo apt upgrade -y`
- [ ] Enable unattended upgrades (security only): `sudo dpkg-reconfigure --priority=low unattended-upgrades`
- [ ] Confirm time sync: `timedatectl status` (should show `System clock synchronized: yes`)

## 2. Networking & Access

- [ ] Verify bond configuration survived reboot: `cat /proc/net/bonding/bond0`
- [ ] Confirm SSH is limited to key auth (optional): edit `/etc/ssh/sshd_config` → `PasswordAuthentication no`, `PermitRootLogin prohibit-password`, then `sudo systemctl reload ssh`
- [ ] Add any required firewall rules (ufw/nftables) or document reliance on upstream firewall

## 3. Storage Health & Monitoring

- [ ] Enable SMART monitoring: install `smartmontools`, add `/etc/smartd.conf` entries, and `sudo systemctl enable --now smartd`
- [ ] Schedule monthly scrub: create `/etc/cron.d/zpool-scrub` with `0 3 1 * * root /sbin/zpool scrub tank`
- [ ] Configure email alerts (Postfix/SSMTP) or integrate with existing monitoring (Prometheus/Telegraf)

## 4. Kernel & Service Tunings

- [ ] Set Redis recommendation: add `vm.overcommit_memory = 1` to `/etc/sysctl.d/99-redis.conf`, run `sudo sysctl --system`
- [ ] (Optional) Set `fs.inotify.max_user_watches` higher if large file trees: e.g., `fs.inotify.max_user_watches = 1048576`
- [ ] Ensure Docker and Nextcloud directories have correct ownership (rerun `scripts/04_nextcloud_compose_setup.sh` if needed)

## 5. Nextcloud Application

- [ ] Run the web installer (configure admin user, default apps) *(using headless `occ maintenance:install` if preferred)*
- [ ] Update `NEXTCLOUD_TRUSTED_DOMAINS` with final DNS names and rerun `scripts/05_nextcloud_stack_up.sh`
- [ ] Configure background jobs: `sudo docker compose exec -T nextcloud php occ background:cron`, create cron entry `*/5 * * * * root cd /srv/nextcloud && docker compose exec -T nextcloud php occ system:cron`
- [ ] Set email delivery (SMTP credentials in `.env` / admin panel)
- [ ] Install required apps (Bookmarks, OnlyOffice, etc.) via `occ` or web UI

## 6. zrepl & Replication

- [ ] Install/verify zrepl (manual `.deb` already installed; rerun if repo returns)
- [ ] Populate `/etc/zrepl/zrepl.yml` with production hostnames/datasets
- [ ] Run `./scripts/07_configure_zrepl.sh`, confirm `sudo zrepl status`
- [ ] Exchange SSH keys with the future peer, document key locations

## 7. Logging & Backups

- [ ] Configure log rotation for custom logs (if any) under `/etc/logrotate.d/`
- [ ] Export configuration tarball: `tar czf ~/exports/nas-config-$(date +%Y%m%d).tgz ...` (see `docs/cloning-plan.md`)
- [ ] Back up Nextcloud env files and zrepl configs to secure vault/password manager

## 8. Security & Compliance

- [ ] Document admin passwords/keys in secure vault
- [ ] Verify fail2ban or equivalent is active (if exposed services are reachable directly)
- [ ] Run `sudo lynis audit system` (optional) and review findings

## 9. Prepare for Second Node

- [ ] Update `docs/cloning-plan.md` with any adjustments made during hardening
- [ ] Ensure DNS entries for `nas02`, `nextcloud-02`, etc., exist and point to reserved IPs
- [ ] Confirm scripts `00`–`08` are up to date and executable (`chmod +x scripts/*.sh`)

---

When all boxes above are ticked, proceed to clone the configuration to the house NAS and finish zrepl pairing.

