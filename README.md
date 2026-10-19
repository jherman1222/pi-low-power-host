# Pi low-power host

> **Canonical path:** this tree (`/Users/jh/Projects/pi-low-power-host`). See [CANONICAL.md](CANONICAL.md). A parallel copy at `/Users/jh/pi-low-power-host` is reference-only.

Headless Raspberry Pi 4 scaffolding for Discord, Scrypted bridge, Mosquitto, Home Assistant, and isolated Victron VE.Direct telemetry. Pi 1 is not the internet gateway, primary Venus OS host, or a serious long-term NVR.

## Phase map

1. **Inventory:** complete/fill [`INVENTORY.md`](INVENTORY.md), especially physical labels and power ratings.
2. **Flash/headless:** follow [`FLASH.md`](FLASH.md) (hostname `pi-low-power`; optional [`cloud-init/`](cloud-init/) / [`firstrun/`](firstrun/) stubs); prove SSH and Tailscale without a monitor.
3. **Foundation:** mount SSD ([SSD.md](SSD.md)), install Docker/Tailscale, then `./scripts/bring-up-foundation.sh` (Mosquitto + Home Assistant).
4. **Mac migration:** follow [`MIGRATION.md`](MIGRATION.md) one workload at a time with rollback (`./scripts/package-from-mac.sh` helper available).
5. **Victron MQTT:** wire only isolated cables and follow [`ORION.md`](ORION.md) (`compose.victron.yaml`).
6. **Optional lazy NVR:** use the bounded profiles and abort criteria in [`NVR-LAZY.md`](NVR-LAZY.md).
7. **Expand later:** keep Venus OS, captive portal, mesh/SDR, and serious NVR on the paths in [`EXPAND.md`](EXPAND.md).

Day-of cutover tracker: [`CHECKLIST.md`](CHECKLIST.md).

## Hardware baseline

- Pi 4 with active cooling and a quality regulated supply.
- Ethernet preferred; Wi-Fi fallback only.
- USB 3 SSD for Docker state and any recording. Keep write-heavy state off microSD.
- One galvanically isolated VE.Direct-to-USB cable per SmartShunt/SmartSolar.
- Powered USB hub if measured current, resets, or several radios require one.

## Mount the SSD

These commands erase the selected partition. Confirm the device with model/serial; do not copy `/dev/sda` blindly:

```bash
lsblk -o NAME,SIZE,FSTYPE,MODEL,SERIAL,MOUNTPOINTS
sudo wipefs --no-act /dev/sdX
# Only after verifying sdX:
sudo parted /dev/sdX --script mklabel gpt mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L low-power-data /dev/sdX1
sudo mkdir -p /srv/pi-data
sudo blkid /dev/sdX1
```

Add an `/etc/fstab` entry using the actual UUID:

```text
UUID=<uuid> /srv/pi-data ext4 defaults,noatime,nofail,x-systemd.device-timeout=10s 0 2
```

Then:

```bash
sudo mount -a
findmnt /srv/pi-data
sudo chown root:docker /srv/pi-data
sudo chmod 2775 /srv/pi-data
```

The Compose files bind persistent application data under `/srv/pi-data`. Docker's image/layer store remains under `/var/lib/docker` unless moved.

### Put Docker's data root on SSD

Do this before creating important containers:

```bash
sudo systemctl stop docker docker.socket
sudo mkdir -p /srv/pi-data/docker
sudo rsync -aHAXx /var/lib/docker/ /srv/pi-data/docker/
printf '%s\n' '{"data-root":"/srv/pi-data/docker"}' | sudo tee /etc/docker/daemon.json
sudo systemctl start docker
docker info --format '{{.DockerRootDir}}'
```

If `/etc/docker/daemon.json` already exists, merge `data-root` into valid JSON instead of overwriting it. Keep `/var/lib/docker` until containers pass validation, then archive/remove it deliberately. Because `nofail` permits boot without the SSD, verify `findmnt /srv/pi-data` before starting workloads; otherwise Docker could write to the microSD mountpoint directory.

## Install and start foundation

On the Pi, clone/copy this repository, then:

```bash
./scripts/install-docker.sh
# Log out/in after Docker install.
./scripts/install-tailscale.sh
sudo tailscale up --hostname=pi-low-power

cp .env.example .env
chmod 600 .env
# Edit TZ, DATA_ROOT, strong MQTT credentials, and later serial paths.
./scripts/init-mqtt.sh

docker compose -f compose.yaml config
docker compose -f compose.yaml pull
docker compose -f compose.yaml up -d
docker compose -f compose.yaml ps
```

Open Home Assistant at `http://pi-low-power:8123` on LAN/Tailscale, create its owner account, and add the MQTT integration using broker `127.0.0.1:1883`. Do not forward these ports from the router.

Foundation checks:

```bash
docker compose -f compose.yaml logs --tail=100 mosquitto homeassistant
docker exec mosquitto mosquitto_sub \
  -h 127.0.0.1 -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
  -t '$SYS/broker/uptime' -C 1
sudo reboot
```

After reboot, verify the SSD mounted before Docker, both containers returned, Tailscale is online, and HA state persisted.

## Compose layout

- `compose.yaml`: Mosquitto + Home Assistant foundation.
- `compose.workloads.yaml`: discovered `MetalDetected` Discord bot container.
- `compose.victron.yaml`: two VE.Direct-to-MQTT bridge instances.
- Scrypted: official generated stack at `~/.scrypted/docker-compose.yml`; see migration guide.

Run stacks independently so optional failures do not force unrelated services down.

## Backups

Back up configuration and databases, not disposable image layers:

- `/srv/pi-data/homeassistant`
- `/srv/pi-data/mosquitto`
- Pi Scrypted persistent volume
- `/srv/pi-data/metal-detected/archive` if retained
- This repository and a secure, separate secret inventory

Use restic or another encrypted tool to a physically separate destination. A backup is incomplete until a restore is tested. Do not back up live databases by blindly copying files; stop the service or use its supported backup mechanism.

## Success criteria

- [ ] SSH and Tailscale work with no monitor ever attached.
- [ ] SSD is the Docker data root and persistent bind-volume root.
- [ ] Mosquitto and Home Assistant recover after reboot.
- [ ] Discord and Scrypted bridge survive 48–72 hours, Mac shutdown, and inverter-off test.
- [ ] SmartShunt and SmartSolar values appear in MQTT/HA and agree with VictronConnect.
- [ ] Orion model is confirmed; Orion-Tr Smart is not incorrectly treated as VE.Direct.
- [ ] NVR has a written keep-on-Pi versus move-to-NUC decision.
- [ ] Venus/OpenWrt/radios remain a second-host plan that does not make Pi 1 the gateway.

## Safety boundary

Repository artifacts prepare software and checklists only. Flashing media, DC wiring, VE.Direct connections, fusing, converter sizing, and power tests require physical verification. Never feed nominal 12 V directly to a 19 V NUC, expose MQTT/HA to the public internet, or connect non-isolated serial wiring to the Victron system.
