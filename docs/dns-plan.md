# DNS Plan – outliertechnology.co.uk

Purpose: define hostnames, records, and related settings for the internal network supporting the twin NAS deployment and Nextcloud service. This plan assumes an authoritative DNS server you control (Pi-hole, Keenetic, Unbound, Windows DNS, etc.) serves the same zone as the public domain using split-horizon or internal-only entries.

---

## Core Records

| Name | Type | Value | TTL | Notes |
|------|------|-------|-----|-------|
| `nas-office` | A | `192.168.1.24` | 300 | Office NAS primary node (bond0 IP). |
| `nas-house` | A | `192.168.1.25` | 300 | House NAS secondary node (set once second box is bonded). |
| `nextcloud` | CNAME | `nas-office.outliertechnology.co.uk.` | 300 | Internal service alias pointing at active node. Update to `nas-house` during failover. |
| `nextcloud-admin` | CNAME | `nas-office.outliertechnology.co.uk.` | 300 | Optional admin-only alias. |
| `nas-office-mgmt` | A | `192.168.1.124` | 300 | (Optional) Out-of-band NIC/IP if added later. |
| `nas-house-mgmt` | A | `192.168.1.125` | 300 | (Optional) for second node. |
| `smtp-relay` | A | `<mail server IP>` | 300 | If Nextcloud sends email via local relay. |

### Reverse DNS

Create PTR records in the appropriate reverse zone (e.g. `24.1.168.192.in-addr.arpa → nas-office.outliertechnology.co.uk`). This is important for logging and TLS certificates.

---

## Service-specific Settings

### Nextcloud Trusted Domains
- Update `/srv/nextcloud/nextcloud.env` (`NEXTCLOUD_TRUSTED_DOMAINS`) to include:  
  `nextcloud.outliertechnology.co.uk nas-office.outliertechnology.co.uk nas-house.outliertechnology.co.uk`
- If you expose Nextcloud externally, add the public FQDN here as well and handle TLS via reverse proxy or ACME client.

### Certificates
- If you terminate HTTPS directly on the NAS, issue certificates covering `nextcloud.outliertechnology.co.uk` plus node hostnames. Use an internal ACME solution (step-ca, Smallstep) or wildcard certificate from your external provider.
- For a reverse proxy (nginx/Traefik/Caddy), point the proxy at `nextcloud.outliertechnology.co.uk` internally so no certificate changes are needed when failing over.

### Service Discovery & Monitoring
- Consider `nas-office._ssh.outliertechnology.co.uk TXT "port=22"` style records if you rely on service discovery tools.
- Add static SRV records if tools expect them (e.g., `_nextcloud._tcp`), though not required for standard clients.
- Create A or CNAME records for monitoring/metrics endpoints if deploying Prometheus exporters (`zrepl`, SMART, etc.).

---

## DHCP/DNS Integration

- Ensure DHCP reservations map the bond MACs to the same IPs configured above so leases always match DNS.
- If your DHCP server can update DNS dynamically, bind each reservation to the desired hostname.
- Make sure the NAS hosts use internal DNS by setting the resolver address in netplan (or relying on DHCP nameservers).

---

## Failover Procedure Notes

- During planned failover, change only the CNAME target:  
  `nextcloud.outliertechnology.co.uk → nas-house.outliertechnology.co.uk`  
  TTL 300s keeps propagation short.
- Update reverse PTRs if IPs swap roles permanently.
- Document the DNS change in the failover runbook (`docs/cloning-plan.md` reference).

---

## Future Expansion

- Reserve subdomains now for future services (e.g., `metrics`, `backups`, `vault`, `nas-repo`).
- If you later expose services externally, set up split-horizon DNS so internal clients resolve to local IPs while external users hit public IPs/DMZ proxies.
- Track DNS changes in version control (e.g. managed zone file in Git) to keep history aligned with infrastructure-as-code practices.

