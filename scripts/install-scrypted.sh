#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -eq 0 ]]; then
  echo "Run as the normal Pi user; the official installer invokes sudo." >&2
  exit 1
fi

url="https://raw.githubusercontent.com/koush/scrypted/main/install/docker/install-scrypted-docker-compose.sh"
target="${HOME}/install-scrypted-docker-compose.sh"

curl -fsSL "${url}" -o "${target}"
chmod 0700 "${target}"

echo "Downloaded the official Scrypted Linux Docker installer to ${target}"
echo "Review it, then run:"
echo "  sudo SERVICE_USER=${USER} bash ${target}"
echo "After installation: rm ${target}"
echo "Official instructions: https://docs.scrypted.app/install/linux-docker.html"
