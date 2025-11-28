# ADR 0004: Automation-First Deployment Workflow

- Status: Proposed
- Date: 2025-11-27

## Context

Manual web-based configuration introduces drift and makes it difficult to reproduce the NAS + Nextcloud environment on the second node. The project has already produced shell scripts for storage, Docker deployment, and zrepl installation, but the initial Nextcloud bootstrap was still interactive. We want a fully scripted, repeatable workflow that can be checked into version control and executed on any new node without touching a browser.

## Decision

1. **Enforce CLI/bootstrap tooling for all components.**  
   - Replace the web installer with `occ maintenance:install` (or equivalent scripted bootstrap) so admin credentials, database settings, and data paths are supplied via automation.  
   - Capture post-install tweaks (trusted domains, overwrite URLs, background job mode, app installs) as `occ` commands in shell scripts or Ansible tasks.

2. **Maintain configuration assets in Git.**  
   - Create a dedicated repository containing `docs/`, `scripts/`, template environment files, and any provisioning helpers.  
   - Exclude runtime secrets (`/srv/nextcloud/*.env`, zrepl keys) via `.gitignore`; store them in Vault/password manager.  
   - Treat the repository as the single source of truth for both NAS nodes; onboarding the second node becomes `git clone` + run scripts.

## Consequences

- **Positive:** End-to-end reproducibility; easier disaster recovery and secondary node bootstrap; auditable history of infra changes.  
- **Positive:** Aligns with infrastructure-as-code best practices; enables future automation (Ansible, CI pipelines).  
- **Negative:** Requires upfront work to script the Nextcloud bootstrap and keep scripts in sync with container updates.  
- **Negative:** Operators must be comfortable running CLI tooling (no GUI shortcuts).  
- **Negative:** Secrets management must be handled separately (Vault, password manager) because they are intentionally excluded from Git.

