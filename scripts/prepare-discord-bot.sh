#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

if [[ ! -f .env ]]; then
  echo "Copy .env.example to .env and configure it first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

: "${DISCORD_BOT_SOURCE:?DISCORD_BOT_SOURCE is required}"
[[ -f "${DISCORD_BOT_SOURCE}/package-lock.json" ]] || {
  echo "No package-lock.json under ${DISCORD_BOT_SOURCE}" >&2
  exit 1
}

install -m 0644 docker/discord-bot/Dockerfile.pi "${DISCORD_BOT_SOURCE}/Dockerfile.pi"

cat <<'EOF' > "${DISCORD_BOT_SOURCE}/.dockerignore"
node_modules
.git
.env
*.log
bot_archive
EOF

install -d -m 0750 "${DATA_ROOT}/metal-detected/archive"
echo "Prepared ${DISCORD_BOT_SOURCE} for an arm64 container build."
echo "Ensure ${DISCORD_BOT_SOURCE}/.env exists with Pi production secrets, chmod 600 it, then run:"
echo "  docker compose -f compose.workloads.yaml build"
