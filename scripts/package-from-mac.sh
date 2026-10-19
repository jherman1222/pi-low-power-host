#!/usr/bin/env bash
# Run ON THE MAC to package Discord bot (+ optional Homebridge config) for scp to the Pi.
# Treat the tarball as secret if .env / Homebridge credentials are included.
set -euo pipefail

OUT="${1:-$HOME/Desktop/pi-migrate-$(date +%Y%m%d).tgz}"
BOT="${BOT_SRC:-$HOME/metal-detected-bot}"
HB="${HOMEBRIDGE_SRC:-$HOME/.homebridge}"
INCLUDE_HOMEBRIDGE="${INCLUDE_HOMEBRIDGE:-1}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/metal-detected-bot"

rsync -a \
  --exclude node_modules \
  --exclude bot_archive \
  --exclude .git \
  --exclude '*.log' \
  "$BOT/" "$tmpdir/metal-detected-bot/"

if [[ "${INCLUDE_HOMEBRIDGE}" == "1" && -d "$HB" ]]; then
  mkdir -p "$tmpdir/homebridge"
  rsync -a \
    --exclude accessories \
    --exclude persist \
    --exclude backups \
    --exclude '*.log' \
    "$HB/" "$tmpdir/homebridge/"
fi

tar -C "$tmpdir" -czf "$OUT" .
chmod 600 "$OUT"

echo "Wrote $OUT"
echo "Copy: scp '$OUT' USER@pi-low-power.local:~/"
echo "On Pi unpack bot into \$DATA_ROOT/apps/metal-detected-bot then:"
echo "  ./scripts/prepare-discord-bot.sh"
echo "  docker compose -f compose.workloads.yaml up -d --build"
if [[ -d "$BOT/bot_archive" ]]; then
  echo "Note: bot_archive was excluded ($(du -sh "$BOT/bot_archive" | awk '{print $1}'))."
fi
