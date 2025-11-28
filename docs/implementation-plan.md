# NAS Deployment Implementation Plan

This plan assumes a fresh Ubuntu 24.04 LTS installation on both NAS nodes with the mirrored NVMe devices available but unpartitioned. Execute the scripts in numerical order from `/home/dtadmin/scripts`. Each script is idempotent where practical and keeps one command per line to aid troubleshooting.

## Prerequisites

- Ensure passwordless sudo or be prepared to enter the password for privileged steps.
- Verify network reachability between the office and home nodes (SSH, firewall rules).
- Sync this repository to both hosts so script and configuration versions match.

## Execution Steps

1. `scripts/00_system_precheck.sh`  
   Gather baseline information (kernel, disks, services) for the run log.
2. `scripts/01_install_packages.sh`  
   Install required packages: ZFS tooling, Docker engine + Compose plugin, and zrepl repository prerequisites.
3. `scripts/02_storage_bootstrap.sh`  
   Create the `tank` pool and datasets (`nextcloud-sync`, `nextcloud-collab`, `nextcloud-db`, `nextcloud-redis`, `backups`) with tuned properties.
4. `scripts/03_remove_snap_nextcloud.sh`  
   Stop services, export data if required, and remove the Nextcloud snap and related snaps.
5. `scripts/04_nextcloud_compose_setup.sh`  
   Create `/srv/nextcloud`, write the `docker-compose.yml`, and install environment files.  
   **Pause after this step to edit `/srv/nextcloud/.env`, `/srv/nextcloud/nextcloud.env`, and `/srv/nextcloud/db.env` with production credentials and domain settings. `scripts/05_nextcloud_stack_up.sh` will refuse to proceed while any `changeme` placeholders remain.**
6. `scripts/05_nextcloud_stack_up.sh`  
   Pull images, start the Compose stack, and run initial Nextcloud CLI bootstrap commands.
7. `scripts/06_install_zrepl.sh`  
   Add the upstream zrepl repository and install the daemon.  
   **Note:** As of 2025-11-21 the `repo.zrepl.dev` DNS record is missing (NXDOMAIN). Either wait for upstream to restore it or install the latest `.deb` from https://github.com/zrepl/zrepl/releases. Once DNS resolves again, re-run this script to switch back to the repository-managed package.
8. `scripts/07_configure_zrepl.sh`  
   Copy the templated YAML from `config/zrepl/primary.yaml`, adjust host-specific variables (`HOME_NODE_HOSTNAME`, `BACKUP_ROOT`, SSH users), enable and start the service.
9. `scripts/08_post_checks.sh`  
   Run validation commands (zpool status, docker ps, zrepl status) and remind the operator to set up monitoring, UPS integration, and cron jobs.

### Remote Node Adaptation

- After completing the office node, repeat the process on the home node with appropriate dataset and hostnames.
- Update the zrepl YAML on each side to reflect the peer's addresses and replication roles.
- Use `scripts/07_configure_zrepl.sh` on both nodes to apply modifications whenever the YAML changes.

## Operational Follow-Up

- Configure SMART monitoring and schedule monthly `zpool scrub`.
- Set up UPS integration and alerting.
- Document credentials and store them securely (e.g., Vault).
- Schedule `docker compose pull` + `docker compose up -d` maintenance windows for Nextcloud updates.

