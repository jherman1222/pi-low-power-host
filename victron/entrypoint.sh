#!/usr/bin/env bash
# Run birdie1/victron for each serial device listed in /config/config.yml.
# Usage inside container: continuous poll loop per device index.
set -euo pipefail

CONFIG="${CONFIG_FILE:-/config/config.yml}"
if [[ ! -f "$CONFIG" ]]; then
  echo "Missing $CONFIG — copy victron/config.yml.example to victron/config.yml" >&2
  exit 1
fi

cp "$CONFIG" /opt/victron/config.yml

# Discover device count (simple YAML list under devices:)
COUNT="$(python3 - <<'PY'
import yaml
with open("/opt/victron/config.yml") as f:
    cfg = yaml.safe_load(f)
print(len(cfg.get("devices") or []))
PY
)"

if [[ "$COUNT" -lt 1 ]]; then
  echo "No devices in config.yml" >&2
  exit 1
fi

echo "Starting victron readers for $COUNT device(s)..."
pids=()
for ((i = 0; i < COUNT; i++)); do
  (
    while true; do
      python3 /opt/victron/victron.py -d "$i" -c || true
      sleep "${VICTRON_POLL_SECONDS:-5}"
    done
  ) &
  pids+=($!)
done

trap 'kill "${pids[@]}" 2>/dev/null || true' EXIT
wait
