# Mac workload migration

Migrate one workload at a time. Keep the Mac copies intact and stopped—not deleted—until the Pi has passed 48–72 hours and the inverter-off test.

## What was found

- Discord bot: `/Users/jh/metal-detected-bot`, PM2 name `MetalDetected`, entrypoint `index.js`, Node 22, currently configured as a single fork-mode process.
- Scrypted: native launchd install under `/Users/jh/.scrypted`, data under `/Users/jh/.scrypted/volume`.
- Homebridge: `/Users/jh/.homebridge` under a system launch daemon. It is not part of this cutover; decide separately whether to keep, migrate, or retire it.

## Discord bot

### Prepare on the Mac

1. Review the source for hard-coded Mac paths and native assumptions (`/Users/jh/metal-detected-bot`, PM2 name `MetalDetected`).
2. Record required environment variable names (`DISCORD_TOKEN`, `GEMINI_API_KEY`). Do not put values in this repository.
3. Exclude `node_modules`; the Mac includes Darwin/arm64 native packages that cannot run in Linux.
4. Decide whether `bot_archive/` and logs must move. Treat exported Discord data as sensitive.
5. Transfer source over Tailscale or LAN (pick one):

```bash
# Option A — direct rsync (preferred; keeps .env off the wire if you omit it)
rsync -a --delete \
  --exclude node_modules --exclude .git --exclude .env --exclude bot_archive --exclude '*.log' \
  /Users/jh/metal-detected-bot/ \
  <pi-user>@pi-low-power:/srv/pi-data/apps/metal-detected-bot/

# Option B — tarball helper from this repo (may include .env — treat as secret)
./scripts/package-from-mac.sh
scp ~/Desktop/pi-migrate-*.tgz <pi-user>@pi-low-power:~/
```

Create `/srv/pi-data/apps/metal-detected-bot/.env` directly on the Pi (or copy securely), `chmod 600` it, and never commit it.

### Build on the Pi

From this repository:

```bash
cp .env.example .env
# Edit DATA_ROOT and DISCORD_BOT_SOURCE, then:
chmod 600 .env
./scripts/prepare-discord-bot.sh
docker compose -f compose.workloads.yaml build --pull
```

To avoid two sessions using the same Discord token, stop PM2 on the Mac immediately before the first Pi start:

```bash
pm2 stop MetalDetected
```

Then on Pi:

```bash
docker compose -f compose.workloads.yaml up -d
docker compose -f compose.workloads.yaml logs -f --tail=100 metal-detected
```

Test a real command, image processing (uses `sharp`), Google API response, Discord reconnect after Pi reboot, and recovery after WAN loss. Existing PM2 logs showed Discord/Google API errors and a Discord.js ready-event deprecation warning, so “container running” is not sufficient.

## Scrypted bridge

Use the [official Linux Docker instructions](https://docs.scrypted.app/install/linux-docker.html). The wrapper only downloads the official installer for review:

```bash
./scripts/install-scrypted.sh
less ~/install-scrypted-docker-compose.sh
sudo SERVICE_USER=$USER bash ~/install-scrypted-docker-compose.sh
rm ~/install-scrypted-docker-compose.sh
```

The official installer writes `~/.scrypted/docker-compose.yml`. Keep that generated stack separate from this repository so Scrypted's installer can manage supported settings. Select SSD storage when prompted.

Before restoring anything, capture the Mac UI's plugin/device list. Found artifacts include core, prebuffer, snapshot, WebRTC, HomeKit, ONVIF, and an Arlo artifact whose enabled state was not proven. Explicitly verify Arlo, Shelly, camera, HomeKit, and ONVIF configuration.

For a filesystem backup, stop Scrypted on the Mac, archive only its persistent volume, and restart it if migration is not immediate:

```bash
launchctl unload ~/Library/LaunchAgents/app.scrypted.server.plist
tar -C ~/.scrypted -czf ~/scrypted-volume-$(date +%F).tar.gz volume
launchctl load ~/Library/LaunchAgents/app.scrypted.server.plist
```

Copy that archive to encrypted/controlled storage. Do not blindly overlay a running Linux install. Stop the Pi Scrypted service, retain its fresh volume as a rollback copy, restore according to the current Scrypted migration guidance, correct ownership to the installer-selected service user, then start and inspect logs. If direct restore fails, use Scrypted's supported backup/restore UI instead.

Bridge-phase validation:

- [ ] UI opens over LAN and Tailscale; no router port-forward exists.
- [ ] Arlo is live-view/bridge only.
- [ ] Shelly and Wi-Fi/ONVIF devices respond.
- [ ] HomeKit pairings or re-pair steps are documented.
- [ ] Streams start after reboot and after WAN interruption.
- [ ] No NVR recording/object detection is enabled yet.

## Observation window

For 48–72 continuous hours:

- [ ] `docker compose ps` remains healthy.
- [ ] Discord commands and reconnects work.
- [ ] Scrypted bridge streams remain usable.
- [ ] `df -h`, `docker system df`, and SSD SMART data remain normal.
- [ ] Pi reports no thermal throttling or undervoltage.
- [ ] Mosquitto and Home Assistant restart cleanly after a planned reboot.
- [ ] Tailscale access works from a phone off-LAN.
- [ ] Homebridge's remaining role is understood; no accessory silently disappeared.

## Inverter-off acceptance test

1. Confirm Pi, SSD, Starlink/router, and any required Ethernet switch are on the intended DC-backed power path.
2. Ensure backups are current and someone can restore inverter power manually.
3. Stop/shut down the Mac, then turn the inverter off.
4. Run for a representative period while checking Discord, Scrypted live view, MQTT/HA, WAN, temperatures, voltage, and USB resets.
5. Restore power and verify no filesystem or database errors.

Pass means the Pi stack and network survive with the Mac and inverter off. Record duration, battery SOC start/end, lowest voltage, Pi maximum temperature, and incidents.

## Rollback

If any required function fails:

```bash
# Pi
docker compose -f compose.workloads.yaml stop metal-detected
```

Then on Mac:

```bash
pm2 start MetalDetected
launchctl load ~/Library/LaunchAgents/app.scrypted.server.plist  # only if currently unloaded
```

Never run both bot instances simultaneously. Do not delete Mac service data until after the observation window, inverter test, backup restore test, and explicit acceptance.
