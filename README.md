# Pi-hole + Unbound

A rehosting of <https://github.com/BrandonCrowther/pi5-homelab> into its' own repository so it can be deployed by itself. I have an old Raspberry Pi 3 sitting around, so the primary destination is that.

Having my network reliant on a box sharing a home with a bunch of random projects was beginning to be a bit reckless.

## Prerequisites

- **Docker** + the **compose plugin** (`curl -sSL https://get.docker.com | sh`).
- A **static IP** for the host, ideally *outside* the DHCP pool you configure below.
- **Ports free** on the host: `53` (DNS), `67` (DHCP), plus your `HOST_PORT`.
  This stack uses **host networking**, which DHCP requires.

## Setup

1. `cp env.template .env`
2. Edit `.env`: set `PASSWORD`, your `HOST_IP`, and the DHCP range/router for
   your LAN. (Set `DHCP_ACTIVE=false` if something else serves DHCP.)
3. `docker compose up -d`
4. `sudo ./setup-network.sh` to configure your static ip and dns settings. Will drop your SSH session.
5. `docker compose restart`
6. Open the admin UI at `http://<HOST_IP>:<HOST_PORT>` (default `:8314`).

## Scripts

Set your static IP:

```bash
sudo nmtui
```

Unblock port 53:

```bash
sudo sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
```

Verify connection:

```bash
# Unbound resolves recursively:
dig @127.0.0.1 -p 5335 google.com +short
# Pi-hole answers and forwards:
dig @<HOST_IP> google.com +short
# A client got the right lease (DNS should be HOST_IP):
#   Windows: ipconfig /all    macOS: scutil --dns
```
