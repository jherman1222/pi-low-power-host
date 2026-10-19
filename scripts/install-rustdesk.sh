#!/usr/bin/env bash
# Optional RustDesk host for GUI remote (phone/Mac). Prefer Tailscale-only for headless.
# See REMOTE.md for trade-offs.
set -euo pipefail

echo "RustDesk needs a graphical session for a full desktop experience."
echo "On Ubuntu Server, install a light DE first if you want GUI remote, e.g.:"
echo "  sudo apt install -y xfce4 xfce4-goodies lightdm"
echo

ARCH="$(dpkg --print-architecture)"
TMP="$(mktemp -d)"
cd "$TMP"

# Resolve current .deb from GitHub releases (arm64 for Pi 4).
# Pin/adjust version if the redirect changes.
LATEST_URL="$(curl -fsSL -o /dev/null -w '%{url_effective}' \
  https://github.com/rustdesk/rustdesk/releases/latest)"
TAG="${LATEST_URL##*/}"
echo "Latest tag: $TAG"

DEB="rustdesk-${TAG#v}-${ARCH}.deb"
# Naming varies; try common patterns
CANDIDATES=(
  "https://github.com/rustdesk/rustdesk/releases/download/${TAG}/rustdesk-${TAG#v}-${ARCH}.deb"
  "https://github.com/rustdesk/rustdesk/releases/download/${TAG}/rustdesk-${TAG}-${ARCH}.deb"
)

OK=0
for URL in "${CANDIDATES[@]}"; do
  if curl -fsSL -o rustdesk.deb "$URL"; then
    OK=1
    break
  fi
done

if [[ "$OK" -ne 1 ]]; then
  echo "Could not download RustDesk .deb automatically."
  echo "Download the arm64/aarch64 .deb from https://rustdesk.com and: sudo apt install ./rustdesk.deb"
  exit 1
fi

sudo apt-get update
sudo apt-get install -y ./rustdesk.deb || sudo dpkg -i ./rustdesk.deb
sudo apt-get install -f -y

echo
echo "Configure RustDesk UI or CLI; set a permanent password."
echo "Connect using the Pi Tailscale IP — do not expose ports on Starlink WAN."
echo "UFW tip: sudo ufw allow from 100.64.0.0/10 to any port 21118"
