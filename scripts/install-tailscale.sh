#!/usr/bin/env bash
# Install Tailscale and bring the node up (interactive login).
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo "==> Starting Tailscale (browser/auth URL will print)..."
sudo tailscale up

# Optional: enable Tailscale SSH for phone/Mac access without managing keys separately
read -r -p "Enable Tailscale SSH? [y/N] " ANS
if [[ "${ANS}" =~ ^[Yy]$ ]]; then
  sudo tailscale set --ssh
fi

echo "==> Status:"
tailscale status || sudo tailscale status
echo "From phone/Mac: ssh via MagicDNS or 100.x address. See REMOTE.md"
