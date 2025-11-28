# ADR 0002: ZFS Dataset Layout and Recordsize

- Status: Proposed
- Date: 2025-11-12

## Context

Workloads will be dominated by synchronized documents and frequently edited CSV files, with no general-purpose database services on the NAS pair. The storage replication plan anticipates mirrored NVMe pools with dataset-per-workload tuning. ZFS defaults to a `recordsize` of 128K, which is optimal for large sequential files but can amplify write amplification for small, frequently updated files.

## Decision

Adopt a tiered dataset strategy:

- Create `tank/nextcloud-sync` (primary Nextcloud content) with `recordsize=128K`, `compression=lz4`, and `atime=off` to favor throughput for mixed media, office documents, and larger files.
- Create `tank/nextcloud-collab` for frequently mutated CSV or similar structured files, setting `recordsize=16K` alongside `compression=lz4` and `atime=off` to reduce read-modify-write overhead.

Datasets remain lightweight, so the split offers tuning flexibility without meaningful administrative burden.

## Consequences

- **Positive**: Maintains high sequential throughput for bulk file sync while optimizing small-block updates in collaborative datasets.
- **Positive**: Allows future datasets (e.g., databases, logs, backups) to inherit defaults or override properties independently.
- **Negative**: Workloads must be routed to the appropriate dataset; misplacing data could negate the tuning benefits.
- **Negative**: Slightly increases administrative surface area (additional mountpoints and permissions management).



