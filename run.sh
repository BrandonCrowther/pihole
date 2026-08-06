#!/usr/bin/env bash
# Live Pi-hole dashboard (padd) inside the running container.
set -euo pipefail
cd "$(dirname "$0")"
docker compose exec pihole padd
