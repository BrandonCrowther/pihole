#!/usr/bin/env bash

# Sets up your network according to the env file.
# Will cut an ssh connection.

set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
# shellcheck disable=SC1091
source .env

IFACE="${1:-$(ip -4 route show default | awk '{print $5}')}"
CON="$(nmcli -g GENERAL.CONNECTION device show "$IFACE")"

firewall-cmd --permanent --add-port="$HOST_PORT/tcp"
# Glances web/API
firewall-cmd --permanent --add-port=61208/tcp
firewall-cmd --reload

nmcli connection modify "$CON" \
  ipv4.method manual \
  ipv4.addresses "$HOST_IP/24" \
  ipv4.gateway "$DHCP_ROUTER" \
  ipv4.dns 127.0.0.1 \
  ipv4.ignore-auto-dns yes

nmcli connection up "$CON"
