#!/usr/bin/env bash
# One-shot foundation after flash + SSD + Docker: MQTT prep + compose up.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env — edit MQTT_PASSWORD (and paths) then re-run." >&2
  exit 1
fi

./scripts/init-mqtt.sh
docker compose -f compose.yaml pull
docker compose -f compose.yaml up -d
docker compose -f compose.yaml ps

echo
echo "Home Assistant: http://$(hostname -I 2>/dev/null | awk '{print $1}'):8123 (or Tailscale MagicDNS)"
echo "MQTT broker: 127.0.0.1:1883 (HA uses host networking — use 127.0.0.1)"
echo "Do not port-forward MQTT/HA from Starlink WAN."
