#!/usr/bin/env bash
# Mount a USB SSD at /srv/pi-data and add an fstab UUID entry.
set -euo pipefail

MOUNT_POINT="${MOUNT_POINT:-/srv/pi-data}"

echo "==> Listing block devices (find your SSD, e.g. /dev/sda):"
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,SERIAL,FSTYPE,UUID,MOUNTPOINT

if [[ "${1:-}" == "--print-only" ]]; then
  exit 0
fi

read -r -p "Enter device partition to mount (e.g. /dev/sda1): " DEV
if [[ ! -b "$DEV" ]]; then
  echo "Not a block device: $DEV" >&2
  exit 1
fi

FSTYPE="$(lsblk -no FSTYPE "$DEV" || true)"
UUID="$(lsblk -no UUID "$DEV" || true)"

if [[ -z "$FSTYPE" ]]; then
  echo "No filesystem on $DEV."
  read -r -p "Create ext4 on $DEV? THIS ERASES DATA. Type YES: " CONFIRM
  [[ "$CONFIRM" == "YES" ]] || exit 1
  sudo mkfs.ext4 -L pi-data "$DEV"
  FSTYPE=ext4
  UUID="$(lsblk -no UUID "$DEV")"
fi

if [[ -z "$UUID" ]]; then
  echo "Could not read UUID for $DEV" >&2
  exit 1
fi

sudo mkdir -p "$MOUNT_POINT"
if ! grep -q "$UUID" /etc/fstab 2>/dev/null; then
  echo "UUID=$UUID $MOUNT_POINT $FSTYPE defaults,noatime,nofail,x-systemd.device-timeout=10s 0 2" | sudo tee -a /etc/fstab
fi

sudo mount "$MOUNT_POINT" || sudo mount -a
sudo mkdir -p "$MOUNT_POINT"/{mosquitto/{data,log},homeassistant,victron,scrypted,nvr,docker}
sudo chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$MOUNT_POINT"

echo "==> Mounted. df:"
df -h "$MOUNT_POINT"
echo "Optional: set Docker data-root to $MOUNT_POINT/docker in /etc/docker/daemon.json (see SSD.md)"
