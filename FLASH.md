# Phase 1a — Flash headless (no monitor)

**OS pick (from plan):** prefer **Ubuntu Server 24.04 LTS 64-bit** (Scrypted-friendly) **or** Raspberry Pi OS Lite 64-bit for Imager-first simplicity.

Do **not** flash: Venus OS, OpenWrt, Home Assistant OS, or full desktop images for Pi 1.

Suggested hostname: **`pi-low-power`** (matches MagicDNS / docs elsewhere).

## Hardware before flashing

- Pi 4 (4 GB+ preferred)
- Quality USB‑C / official PSU or regulated 5 V / PoE+ HAT
- microSD for boot (32 GB+); plan to put Docker data on **USB 3 SSD**
- Ethernet to Starlink/router preferred (Wi‑Fi fallback only)
- Active cooling

## SSH key on the Mac (do this first)

This Mac had **no `~/.ssh` directory** at inventory time. Create a key before flashing so Imager can embed it:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "jh@mac-mini-pi-host" -f ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub   # paste into Imager / cloud-init
```

## Option A — Ubuntu Server 24.04 (recommended)

1. Download the **Raspberry Pi** image of Ubuntu Server 24.04 LTS (arm64) from Canonical, or pick it in Raspberry Pi Imager if listed.
2. Flash with [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
3. Open **OS customisation** (gear / Edit settings) before Write:
   - **Hostname:** `pi-low-power`
   - Username + strong password **or** (preferred) SSH authorized key only
   - **Enable SSH**
   - Wi‑Fi SSID/password **only if** Ethernet unavailable
   - Locale / timezone (`America/Los_Angeles` matches `.env.example`)
4. Eject, insert SD, connect **Ethernet** + power. **No HDMI.**
5. From Mac (same LAN):

   ```bash
   ssh <user>@pi-low-power.local
   # or check router DHCP leases for the address
   ```

6. First login:

   ```bash
   sudo apt update && sudo apt full-upgrade -y
   sudo reboot
   ```

### cloud-init stub (advanced)

See [`cloud-init/user-data.example`](cloud-init/user-data.example). On Ubuntu’s `system-boot` partition you can place a customized `user-data` with hostname + `ssh_authorized_keys`. Prefer Imager UI unless you already know cloud-init.

## Option B — Raspberry Pi OS Lite 64-bit

1. Open Raspberry Pi Imager → Raspberry Pi OS (other) → **Lite (64-bit)**.
2. Gear / OS customisation:
   - Hostname `pi-low-power`, user, password
   - **Enable SSH** (public key preferred)
   - Wireless LAN if needed
   - Optional: Raspberry Pi Connect
3. Write → boot → `ssh user@pi-low-power.local`

Optional firstrun sketch: [`firstrun/firstrun.sh.example`](firstrun/firstrun.sh.example). Imager customisation is enough for most installs.

Raspberry Pi Connect is a fine GUI-less remote if you stay on Pi OS; on Ubuntu, use Tailscale (+ optional RustDesk) — see [REMOTE.md](REMOTE.md).

## Immediately after first SSH

```bash
hostnamectl
ip -br a

sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw --force enable
```

Then copy/clone this repo onto the Pi and run foundation scripts:

1. `sudo ./scripts/mount-ssd.sh` — prepare USB SSD (see [SSD.md](SSD.md))
2. `./scripts/install-docker.sh` — then log out/in for `docker` group
3. `./scripts/install-tailscale.sh` → `sudo tailscale up --hostname=pi-low-power`
4. Verify Tailscale SSH/MagicDNS from a **phone off-LAN**
5. Optional: `./scripts/install-rustdesk.sh` if you want GUI remote
6. `./scripts/bring-up-foundation.sh`

## Wi‑Fi vs Ethernet

| | Ethernet | Wi‑Fi |
|--|----------|-------|
| Reliability | Prefer | Fallback |
| USB3 + Wi‑Fi coexistence | Better | Can be flaky on Pi 4 |
| Headless recovery | Easier with cable | Need correct SSID first boot |

## First-boot checklist

- [ ] SSH key created on Mac and pasted into Imager / cloud-init
- [ ] Hostname `pi-low-power`
- [ ] Ethernet connected before first power-on (preferred)
- [ ] `ssh <user>@pi-low-power.local` works with **no monitor**
- [ ] Packages updated; UFW allows SSH
- [ ] Tailscale up; phone off-LAN can reach the Pi
- [ ] Ready for foundation compose ([README.md](README.md))

## Success criteria

- [ ] SSH works with **no monitor ever attached**
- [ ] Hostname resolves on LAN (`.local` or DHCP reservation)
- [ ] Tailscale up; SSH from phone off-LAN ([REMOTE.md](REMOTE.md))
- [ ] Ready for [compose.yaml](compose.yaml) / `scripts/bring-up-foundation.sh`
