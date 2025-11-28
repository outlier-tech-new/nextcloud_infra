# ADR 0001: Nextcloud Deployment Without Snap

- Status: Proposed
- Date: 2025-11-12

## Context

The system inventory (`docs/system-inventory.md`) shows that the evaluation host currently runs the Nextcloud snap package. The snap simplifies installation but constrains file layout, database selection, and update cadence. It also hampers repeatable automation because configuration lives inside snap-managed paths that are difficult to template. The storage replication plan (`docs/storage-replication-plan.md`) calls for mirrored ZFS datasets per workload and future replication between two nodes, which is awkward to realize through the snap.

## Decision

Remove the Nextcloud snap and redeploy Nextcloud via a containerized stack managed with `docker compose`. This stack will:

- Use first-party container images for Nextcloud, MariaDB, and Redis.
- Persist application state on dedicated ZFS datasets (`tank/nextcloud-app`, `tank/nextcloud-sync`, `tank/nextcloud-db`, `tank/nextcloud-redis`) mounted under `/srv/nextcloud`.
- Rely on environment files and declarative compose definitions committed to version control, enabling repeatable automation on both NAS nodes.

## Consequences

- **Positive**: Full control over PHP, database, caching, and upgrade cadence; consistent filesystem layout that maps cleanly onto ZFS datasets; automation-friendly configuration.
- **Positive**: Easier to integrate with backup, monitoring, and CI/CD tooling because Compose artifacts and env files can be shared between hosts.
- **Negative**: Requires management of container runtime packages and lifecycle, including security updates and image pulls.
- **Negative**: Adds responsibility for database hardening, credential rotation, and service monitoring that the snap previously abstracted.

