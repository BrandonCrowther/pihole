# Architecture

Two containers, both on the **host network**, cooperating over the host's
loopback interface.

```
                        ┌──────────────────────────────────────────┐
   LAN clients          │  Docker host (SERVER_IP, static)          │
   192.168.2.0/24       │                                           │
        │  DNS :53 ─────┼──▶ pihole ──(blocked? null)               │
        │               │      │                                    │
        │               │      └─(allowed)─▶ 127.0.0.1#5335          │
        │               │                        │                  │
        │               │                     unbound (recursive)   │
        │               │                        │                  │
        │  DHCP :67 ────┼──▶ pihole              └──▶ root/authoritative
        │               │   (leases, gateway,        nameservers    │
        │               │    advertises itself                      │
        │               │    as DNS)          (fallback: 1.1.1.1)   │
        └───────────────┼───────────────────────────────────────────
                        └──────────────────────────────────────────┘
```

## Pi-hole

- **DNS** on `:53` — blocks ad/tracker domains, forwards the rest to Unbound.
- **DHCP** on `:67` — hands out leases, advertises the **router** (`DHCP_ROUTER`)
  as the gateway and **itself** (the host IP) as the DNS server.
- **Upstreams:** `127.0.0.1#5335` (Unbound) first, `1.1.1.1` as a fallback so a
  single Unbound failure isn't total DNS loss.
- **Web UI** on `WEB_PORT`.

## Unbound

- Recursive resolver listening on `127.0.0.1:5335` (loopback only — reachable by
  Pi-hole, not exposed to the LAN).
- Talks directly to the root and authoritative nameservers (not a forwarder),
  with DNSSEC validation, qname-minimisation, and local caching.

## Why host networking

DHCP depends on broadcast packets that do not traverse a Docker bridge, and
Pi-hole must advertise the host's real LAN IP as the DNS server. Host networking
is the simplest correct answer; both containers share the host's loopback, which
is how Pi-hole reaches Unbound at `127.0.0.1#5335`.

## State vs. config

- **Config (versioned):** `docker-compose.yaml`, `etc-unbound/unbound.conf`, `.env`
  (from `env.template`). This is all that's needed to reproduce the stack.
- **State (not versioned):** `etc-pihole/` (databases, leases, gravity
  blocklists, TLS keys) and `var-log-pihole/`. Regenerated on boot; restore
  blocklists/records via the UI or a Teleporter backup.
