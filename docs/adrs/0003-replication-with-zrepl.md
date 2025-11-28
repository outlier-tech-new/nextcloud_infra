# ADR 0003: Replication with zrepl

- Status: Proposed
- Date: 2025-11-12

## Context

The twin NAS deployment requires asynchronous replication between an office and home node. Alternatives evaluated in `docs/storage-replication-plan.md` include Sanoid/Syncoid, zrepl, and manual `zfs send/receive` automation. The team needs resumable transfers, policy-driven pruning, and a daemonized workflow that integrates cleanly with observability tooling.

## Decision

Standardize on `zrepl` for dataset replication. Both nodes will run the upstream Debian/Ubuntu package, managed as a systemd service. Configuration will live in version-controlled YAML files with per-node variables (target hostnames, snapshot retention policies), enabling straightforward duplication across environments.

## Consequences

- **Positive**: Provides resumable, incremental replication with built-in pruning and metrics endpoints; supports flexible push/pull topologies for the office ↔ home link.
- **Positive**: Aligns with infrastructure-as-code goals because zrepl configuration is declarative YAML and can be templatized.
- **Negative**: Higher learning curve than simple cron jobs; configuration mistakes can interrupt replication or delete snapshots prematurely.
- **Negative**: Adds a long-running daemon that must be monitored and updated alongside the rest of the stack.



