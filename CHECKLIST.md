# Cutover checklist

Use with [INVENTORY.md](INVENTORY.md), [FLASH.md](FLASH.md), [MIGRATION.md](MIGRATION.md), and [ORION.md](ORION.md).

## Before touching the Pi

- [ ] USB 3 SSD ready (will be ext4 at `/srv/pi-data`)
- [ ] Quality 5 V / USB-C supply for Pi 4 (or known-good PoE+)
- [ ] Ethernet cable preferred
- [ ] Mac SSH key created (inventory found no `~/.ssh` yet)
- [ ] Genuine Victron VE.Direct-USB **ASS030530000** ×2 (shunt + MPPT)
- [ ] Orion label photographed — Tr Smart vs XS ([ORION.md](ORION.md))
- [ ] Optional Mac packaging: `./scripts/package-from-mac.sh`

## Flash & first SSH ([FLASH.md](FLASH.md))

- [ ] Imager: hostname `pi-low-power`, user, SSH key, Ethernet preferred
- [ ] Boot Pi, `ssh user@pi-low-power.local` (no display)
- [ ] Updates + UFW
- [ ] `./scripts/mount-ssd.sh` (+ Docker data-root on SSD per [SSD.md](SSD.md) / [README.md](README.md))
- [ ] `./scripts/install-docker.sh` → re-login
- [ ] `./scripts/install-tailscale.sh` → approve device; phone off-LAN test

## Foundation ([README.md](README.md))

- [ ] Repo on Pi; `.env` from `.env.example` with strong `MQTT_PASSWORD`
- [ ] `./scripts/bring-up-foundation.sh` (or `init-mqtt.sh` + `compose.yaml`)
- [ ] HA owner account created; MQTT integration → `127.0.0.1:1883`
- [ ] Reboot test: SSD mounted, Mosquitto + HA healthy, Tailscale online

## Mac migration ([MIGRATION.md](MIGRATION.md))

- [ ] Discord bot unpacked to `$DATA_ROOT/apps/metal-detected-bot` with `.env` (`chmod 600`)
- [ ] `pm2 stop MetalDetected` on Mac immediately before Pi bot start
- [ ] `./scripts/prepare-discord-bot.sh` + `compose.workloads.yaml up -d --build`
- [ ] Real Discord command + image (`sharp`) test
- [ ] Official Scrypted Docker install (`./scripts/install-scrypted.sh`)
- [ ] Reconfigure Arlo / HomeKit / ONVIF — Arlo bridge-only
- [ ] Decide Homebridge: keep on Mac, migrate later, or retire after Shelly→HA
  - Current Shelly Plus RGBW PM at `192.168.1.168` (Homebridge platform)
- [ ] 48–72 h soak + inverter-off test recorded

## Victron ([ORION.md](ORION.md))

- [ ] Confirm Orion model on label (Tr Smart → no third cable)
- [ ] Plug shunt + MPPT USB one at a time; note `/dev/serial/by-id/`
- [ ] Set `VE_DIRECT_SHUNT` / `VE_DIRECT_MPPT` in `.env`
- [ ] Optional: install [`udev/99-victron-vedirect.rules`](udev/99-victron-vedirect.rules)
- [ ] `docker compose -f compose.victron.yaml up -d --build`
- [ ] MQTT `victron/#` → HA package sensors
- [ ] Readings agree with VictronConnect

## Optional NVR / deferred ([NVR-LAZY.md](NVR-LAZY.md), [EXPAND.md](EXPAND.md))

- [ ] Lazy NVR only with local H.264 RTSP cams — never Arlo as NVR target
- [ ] Abort→NUC criteria understood
- [ ] Venus OS / OpenWrt portal / mesh / SDR parked for second host
