# NAS Cloning & Secondary Setup Plan

Purpose: capture the exact steps to turn the newly configured office NAS into a template for the second node (house NAS) so both appliances share the same dataset layout, Nextcloud stack, secrets, and zrepl configuration. Follow this plan once the primary node is stable; check off each section during execution to avoid drift.

---

## 1. Capture State on the Primary Node

1. **Finalize configuration files**  
   - Ensure `/srv/nextcloud/.env`, `nextcloud.env`, and `db.env` contain production credentials (no `changeme`).  
   - Verify `/srv/nextcloud/docker-compose.yml` matches `config/nextcloud/docker-compose.yml`.  
   - Confirm `/etc/zrepl/zrepl.yml` exists and includes real hostnames/datasets (or leave placeholders if you will fill them post-clone).
2. **Snapshot critical datasets**  
   ```bash
   sudo zfs snapshot tank/nextcloud-app@pre-clone
   sudo zfs snapshot tank/nextcloud-sync@pre-clone
   sudo zfs snapshot tank/nextcloud-collab@pre-clone
   sudo zfs snapshot tank/nextcloud-db@pre-clone
   sudo zfs snapshot tank/nextcloud-redis@pre-clone
   sudo zfs snapshot tank/backups@pre-clone
   ```
3. **Archive configuration & scripts**  
   ```bash
   mkdir -p ~/exports
   tar czf ~/exports/nas-config-$(date +%Y%m%d).tgz \
     /home/dtadmin/config \
     /home/dtadmin/scripts \
     /srv/nextcloud/*.env \
     /srv/nextcloud/docker-compose.yml \
     /etc/zrepl \
     /etc/systemd/system/docker.service.d 2>/dev/null || true
   ```
4. **Record version info**  
   ```bash
   ./scripts/08_post_checks.sh > ~/exports/post-checks-$(date +%Y%m%d).log
   dpkg-query -W zrepl docker-ce docker-ce-cli containerd.io docker-compose-plugin zfsutils-linux >> ~/exports/package-versions-$(date +%Y%m%d).txt
   ```

## 2. Prepare the Second Node

1. **Install Ubuntu 24.04 and match firmware**  
   - Apply same BIOS/firmware revisions where practical.
2. **Create admin user (`dtadmin`)**  
   - Ensure UID/GID match the primary (check with `id dtadmin` on each host).
3. **Copy repository & scripts**  
   ```bash
   rsync -aP dtadmin@office-nas:/home/dtadmin/{config,scripts,docs} /home/dtadmin/
   ```
4. **Mirror package installs**  
   - Run `scripts/00_system_precheck.sh` to record baseline.  
   - Run `scripts/01_install_packages.sh` (Docker repo already set up by script).  
   - Install zrepl via `.deb` if the repo is still offline (see below).

## 3. Sync Secrets & Configuration

1. **Copy environment files**  
   ```bash
   rsync -aP dtadmin@office-nas:/srv/nextcloud/{.env,nextcloud.env,db.env} /srv/nextcloud/
   rsync -aP dtadmin@office-nas:/srv/nextcloud/docker-compose.yml /srv/nextcloud/
   ```
   Ensure permissions (`chmod 600` for *.env).
2. **Clone zrepl configuration**  
   ```bash
   sudo rsync -aP dtadmin@office-nas:/etc/zrepl /etc/
   ```
   Update `/etc/zrepl/zrepl.yml` with the secondary’s role (e.g., receiving sink). Adjust `HOME_NODE_HOSTNAME` → office host, `BACKUP_ROOT` → something like `tank/replica`.
3. **Copy SSH key pairs**  
   - Fetch `/etc/zrepl/keys/id_ed25519*` from primary to secondary (or regenerate and exchange later).  
   - Add the public keys to `authorized_keys` on each peer.

## 4. Recreate Storage Layout

1. **Run `scripts/02_storage_bootstrap.sh`** on the secondary (will create the pool + datasets).  
   - Confirm `zfs get recordsize` etc. match primary (`zfs get all tank/nextcloud-*`).
2. **Replicate initial snapshots** (manual seed):  
   - From primary:  
     ```bash
     sudo zfs send -R tank/nextcloud-sync@pre-clone | pv | ssh zrepl@secondary-nas sudo zfs recv -u tank/nextcloud-sync
     ```
     Repeat for other datasets, or script via `zfs send -R tank@pre-clone`.
   - Alternatively, run `zrepl` once configured to perform the first sync.

## 5. Bring Up Services on Secondary

1. **Apply config and start stack**  
   - Run `scripts/04_nextcloud_compose_setup.sh`.  
   - Verify `.env`/`nextcloud.env`/`db.env` contain the copied secrets.  
   - Run `scripts/05_nextcloud_stack_up.sh` (should succeed since data is preloaded).  
2. **Install zrepl**  
   - If repo DNS still broken, reuse cached `.deb` from `~/downloads`; otherwise rerun script 06.  
   - Run `scripts/07_configure_zrepl.sh` to apply updated config.
3. **Verify replication**  
   ```bash
   sudo zrepl status
   sudo zfs list -t snapshot tank/nextcloud-sync
   ```

## 6. Final Alignment

1. **Update host-specific values**  
   - `/etc/hostname`, `/etc/hosts`, DNS records, SSL certificates.  
   - Update Nextcloud trusted domains and background cron hostnames.
2. **Document failover steps**  
   - Write runbook: stop primary, run final `zrepl` sync, promote snapshots on secondary, start Compose, update DNS, etc.
3. **Back up exports**  
   - Copy `~/exports/*.tgz` and logs to a secure location (Vault, offline storage).

## Notes

- Until zrepl’s apt repository is restored, retain the manual `.deb` so both nodes install the same version.  
- For long-term operations, consider using infrastructure-as-code (Ansible, etc.) to reapply these steps automatically.

---

Next session: continue with Section 2 on the secondary node once it’s bootstrapped. Capture any deviations in this document to keep both systems aligned.



