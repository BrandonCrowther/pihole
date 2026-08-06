# Pi-hole + Unbound

A portable, self-contained network DNS + DHCP stack: **Pi-hole** for ad-blocking
DNS and DHCP, backed by a local **Unbound** recursive resolver (with Cloudflare
as a fallback). Everything host-specific lives in `.env`, so the same repo boots
on any Docker host — a Pi, a NUC, a VM — by editing one file.

## What's in here

| File | Purpose |
|------|---------|
| `docker-compose.yaml` | The two services (pihole, unbound), fully parameterized |
| `env.template` | Copy to `.env` and fill in your host/LAN values |
| `etc-unbound/unbound.conf` | Unbound recursive-resolver config (host-agnostic) |
| `run.sh` | Live `padd` dashboard helper |
| `ARCHITECTURE.md` | How the pieces fit together |

Runtime state (Pi-hole's databases, leases, TLS keys, gravity blocklists, logs)
is **not** committed — the container regenerates it on first boot. See
[Restoring blocklists & local records](#restoring-blocklists--local-records).

## Prerequisites

- **Docker** + the **compose plugin** (`curl -sSL https://get.docker.com | sh`).
- A **static IP** for the host, ideally *outside* the DHCP pool you configure below.
- **Ports free** on the host: `53` (DNS), `67` (DHCP), plus your `WEB_PORT`.
  This stack uses **host networking**, which DHCP requires.
- On Linux hosts, `systemd-resolved` usually squats on port 53. Free it:
  ```bash
  sudo sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
  sudo systemctl restart systemd-resolved
  ```

## Setup

1. `cp env.template .env`
2. Edit `.env`: set `PASSWORD`, your `SERVER_IP`, and the DHCP range/router for
   your LAN. (Set `DHCP_ACTIVE=false` if something else serves DHCP.)
3. `docker compose up -d`
4. Open the admin UI at `http://<SERVER_IP>:<WEB_PORT>` (default `:8314`).
5. Point your network at this server for DNS:
   - **If Pi-hole is your DHCP server** (`DHCP_ACTIVE=true`): **disable the
     router's DHCP**, then reboot/renew clients so they pick up Pi-hole as
     their DNS. Clients cache the old lease, so a reconnect/reboot is needed.
   - **If the router stays the DHCP server**: point the router's advertised
     DNS at `SERVER_IP`.

## Verify

```bash
# Unbound resolves recursively:
dig @127.0.0.1 -p 5335 google.com +short
# Pi-hole answers and forwards:
dig @<SERVER_IP> google.com +short
# A client got the right lease (DNS should be SERVER_IP):
#   Windows: ipconfig /all    macOS: scutil --dns
```

## Restoring blocklists & local records

Because runtime state isn't versioned, a fresh boot starts with Pi-hole's
default blocklist. Re-add your adlists and local DNS records via the admin UI
(**Lists** and **Settings → Local DNS Records**), or restore a Pi-hole
Teleporter backup (**Settings → Teleporter**).

## Portability checklist (per host)

Only `.env` should ever need changing between hosts:

- `SERVER_IP` — the new host's static IP
- `DHCP_START` / `DHCP_END` / `DHCP_ROUTER` — the target LAN
- `TZ`, `PASSWORD`

## Troubleshooting

- **Unbound not answering:** `dig @127.0.0.1 -p 5335 google.com`. If it fails,
  `docker compose logs unbound`.
- **Clients still using the old DNS:** they're on a cached lease — reboot them,
  or shorten `DHCP_LEASE` temporarily.
- **Port 53 already in use:** something else (often `systemd-resolved`) owns it
  — see [Prerequisites](#prerequisites).
