# USB SSD for Docker + volumes (critical)

Pi microSD is fine for **boot/OS**. Put **Docker root / compose volumes / NVR recordings** on a USB 3 SSD.

## Why

- SD cards wear out under database + image write load (HA, Mosquitto persistence, Scrypted, NVR).
- USB 3 SSD handles Scrypted/NVR trial writes; abort criteria still apply ([NVR-LAZY.md](NVR-LAZY.md)).

## Suggested layout

| Mount | Use |
|-------|-----|
| `/` on microSD | OS, packages |
| `/srv/pi-data` on SSD | Mosquitto, HA config, Victron state, Scrypted volume, NVR media |
| Optional: move Docker data-root to SSD | `/etc/docker/daemon.json` → `"data-root": "/srv/pi-data/docker"` |

Default `DATA_ROOT` in `.env.example` is `/srv/pi-data`.

## Procedure (summary)

1. Plug SSD into a **USB 3** blue port (or powered hub if bus power is tight).
2. Run `sudo scripts/mount-ssd.sh` (interactive) **or** follow manual steps in that script’s comments.
3. Create subdirs:
   ```bash
   sudo mkdir -p /srv/pi-data/{mosquitto,homeassistant,victron,scrypted,nvr,docker}
   sudo chown -R "$USER:$USER" /srv/pi-data
   ```
4. Install Docker **after** the mount exists if you relocate `data-root`.
5. Add `/etc/fstab` entry by **UUID** (script prints it) so the SSD mounts before Docker.

## Power notes

- Bus-powered SSDs + multiple VE.Direct sticks + RTL‑SDR later → use a **powered USB hub**.
- Confirm `dmesg` for under-voltage (`Under-voltage detected`) after stacking devices; fix PSU before chasing flaky serial.

## Backups

- Restate later: restic/Tailscale backups of `/srv/pi-data/homeassistant` and Mosquitto config.
- NVR media is large — back up config, not necessarily all recordings.
