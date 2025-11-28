# Git Repository Plan

Purpose: capture how to turn the current automation assets into a repeatable Git repository that can be cloned onto both NAS nodes.

---

## Repository Layout

```
nas-infra/
├── docs/                # ADRs, network plan, hardening checklist, journal
├── scripts/             # numbered provisioning scripts (00–08)
├── templates/           # environment file templates, zrepl sample configs
├── bootstrap/           # optional helper scripts (occ bootstrap, cron setup)
├── .gitignore
└── README.md            # overview + usage instructions
```

- Keep runtime data (`/srv/nextcloud/app`, datasets, logs) out of the repo.
- Store sensitive env files (`.env`, `nextcloud.env`, `db.env`) only as templates with placeholder values. Real secrets live in Vault/password manager.

## Initialization (run on `nas01`)

```bash
mkdir -p ~/nas-infra/templates
cp -a ~/docs ~/nas-infra/
cp -a ~/scripts ~/nas-infra/
cp ~/config/nextcloud/*.env ~/nas-infra/templates/
cp ~/config/nextcloud/docker-compose.yml ~/nas-infra/templates/
cp ~/config/zrepl/primary.yaml ~/nas-infra/templates/zrepl-primary.yaml
cd ~/nas-infra
cat <<'EOF' > .gitignore
# Secrets & runtime
/templates/*.env.actual
/templates/*.env.local
/secrets/
*.key
*.pem
/srv/
/exports/

# OS artifacts
*.swp
*.swo
.DS_Store

# Logs
*.log
EOF
git init
git add .
git commit -m "Initial NAS automation repository"
```

> **Note:** use `git config` to set username/email if this host has not committed before.

## Ongoing Workflow

1. Make changes to scripts/docs/templates.
2. Run the appropriate provisioning script to apply changes to `/srv/nextcloud` or `/etc/zrepl`.
3. Commit the change (`git commit`) with clear message.
4. Push to remote (GitHub, Gitea, internal bare repo) once ready.

When cloning onto the second NAS:

```bash
cd /home/dtadmin
git clone git@your-repo-host:nas-infra.git
cd nas-infra
./scripts/00_system_precheck.sh
./scripts/01_install_packages.sh
# ... continue per implementation plan
```

After cloning, copy templates into place:

```bash
cp templates/nextcloud.env /srv/nextcloud/nextcloud.env
cp templates/db.env /srv/nextcloud/db.env
# Fill in secrets, then run scripts/04 and 05
```

## Next Steps

- Decide on remote hosting (GitHub private repo, internal Gitea, bare Git over SSH).
- Export current secret values to Vault/password manager.
- Create helper script to run `occ maintenance:install` with values from template.
- Update `README.md` with end-to-end bootstrap instructions.

