#!/usr/bin/env bash
# Install Docker Engine + Compose plugin (Ubuntu / Debian / Pi OS).
set -euo pipefail

if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed: $(docker --version)"
  docker compose version || true
  exit 0
fi

sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings

if [[ -f /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
else
  echo "Cannot detect OS" >&2
  exit 1
fi

curl -fsSL "https://download.docker.com/linux/${ID}/gpg" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "${SUDO_USER:-$USER}"
echo "Log out/in (or newgrp docker) so group membership applies."
docker --version
docker compose version
