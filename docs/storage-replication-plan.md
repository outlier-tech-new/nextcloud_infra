# Storage and Replication Plan

## Goals
- Replace Dropbox with self-hosted Nextcloud backed by redundant on-premises storage.
- Deploy two identical NAS nodes: this system in the office, a peer in the house.
- Use ZFS for data integrity, snapshotting, and replication between nodes.

## Proposed Layout
- System disk remains dedicated to the OS and infrastructure tooling.
- Create one ZFS pool (`tank` as a placeholder name) composed of a single mirrored vdev using `nvme0n1` and `nvme1n1`.
- Organize datasets to separate workloads, for example:
  - `tank/nextcloud-data`
  - `tank/nextcloud-db`
  - `tank/nextcloud-logs`
  - `tank/backups`
- Apply dataset tuning:
  - Enable `compression=lz4` and `atime=off` (or `relatime` if required).
  - Consider smaller `recordsize` (16K) for database datasets; keep 128K for general file data.
- Plan future expansion by adding additional mirrored vdevs (pairs of matched disks) as storage needs grow; keep cold spares on hand.

## Nextcloud Deployment Considerations
- The installer provided the Nextcloud snap, which offers ease of maintenance but limited customization (database backend, Redis, PHP tuning).
- If you need more control, evaluate migrating to a docker-compose or package-based installation before attaching production data.
- No matter the deployment method, put the Nextcloud data directory and database files on dedicated ZFS datasets for snapshotting and replication.

## Replication Tooling Options
- **Sanoid + Syncoid**
  - Pros: Simple configuration, automatic snapshot retention, handles incremental send/receive with compression, established project with good logging.
  - Cons: Snapshot naming is opinionated; relies on Perl; less granular per-filesystem policy compared to zrepl.
  - Best for: Fast setup with conventional retention schedules and single replication target.
- **zrepl**
  - Pros: Daemonized replication with push/pull modes, resumable transfers, Prometheus metrics, powerful include/exclude rules, automatic pruning on both sides.
  - Cons: More complex YAML configuration, steeper learning curve, runs as a long-lived service.
  - Best for: Policy-driven replication with observability, especially when scaling beyond one peer or requiring bidirectional flows.
- **Manual scripting (zfs send/receive)**
  - Pros: Maximum control, minimal dependencies, easy to integrate into existing orchestration (Ansible, cron).
  - Cons: Must manage snapshot naming, retention, retries, and alerting yourself; higher risk of human error.
  - Best for: Highly customized workflows or environments with existing automation that handles scheduling and monitoring.
- **Other utilities**
  - `zfs-autobackup`: Lightweight Python tool balancing simplicity and flexibility.
  - `pyznap`: Snapshot rotation companion if you keep manual replication scripts.

## Operational Checklist (Initial)
- Install `zfsutils-linux` and enable `zfs-import-cache.service`.
- Create pool and datasets; test snapshot creation and rollback.
- Configure SMART monitoring, monthly `zpool scrub`, and email/alerting for pool health.
- Decide on replication tooling, configure policies, and test a full send/receive cycle including resume after interruption.
- Prepare UPS integration, NTP, and secure remote management (hardened SSH, admin MFA).
- Schedule Nextcloud background jobs (`snap run nextcloud.occ` cron) and document the failover plan once the second node is online.
