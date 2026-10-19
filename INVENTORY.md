# Mac and hardware inventory

Captured on 2026-07-18 from a live scan of this Mac Mini. Secrets and database contents were not copied into this repo.

## Always-on Mac services (migration targets)

| Item | Finding | Migration implication |
| --- | --- | --- |
| Host | Mac Mini M4 (`Mac16,10` / `MU9D3LL/A`), 16 GB RAM, arm64 | Pi images/containers must be `linux/arm64`. |
| Discord bot | `/Users/jh/metal-detected-bot`; PM2 name **`MetalDetected`**; entry `index.js`; deps `discord.js`, Google GenAI, `dotenv`, `sharp`, PM2 | Copy source without `node_modules`/`bot_archive`; rebuild `sharp` on Pi; supervise via `compose.workloads.yaml`. |
| Bot env keys | `DISCORD_TOKEN`, `GEMINI_API_KEY` (optional `GEMINI_CHAT_MODEL`, `GEMINI_IMAGE_MODEL`) | Create `.env` on Pi only; never Git. |
| Bot runtime | PM2 LaunchAgent `pm2.jh.plist` → `pm2 resurrect`; process online at inventory | Stop Mac bot before Pi start to avoid duplicate Discord sessions. |
| Scrypted | LaunchAgent `app.scrypted.server.plist` → `npx -y scrypted serve`; cwd `/Users/jh/.scrypted` (~381 MB) | Fresh Linux Docker install; prefer UI backup/restore over blind Darwin volume copy. |
| Scrypted plugins (on disk / running) | `@scrypted/arlo` (Python plugin process observed), `core`, `homekit`, `onvif`, `prebuffer-mixin`, `snapshot`, `webrtc` | Screenshot plugin/device list before cutover. **Arlo = bridge/live-view only (not NVR).** |
| Listening ports | Scrypted `10081`/`10443`/`11080`; Homebridge UI `8581` + bridge `52000`; RustDesk `21118` | Reach UIs over Tailscale/LAN — no Starlink WAN forwards. |
| Homebridge | System LaunchDaemon `com.homebridge.server`; data `~/.homebridge`; bridge **Homebridge 287B** | Out of day-1 “must migrate” list. Platform **`ShellyPlusRGBWPM`** device host **`192.168.1.168`**. Keep on Mac temporarily, move Shelly to HA later, or run Homebridge on Pi. |
| Tailscale | App running (`io.tailscale.ipn.macsys`) | Enroll Pi as `pi-low-power` on same tailnet; phone off-LAN test is a success criterion. |
| RustDesk | Listening on Mac (`21118`) | Optional on Pi ([REMOTE.md](REMOTE.md)); Tailscale SSH is enough for headless. |
| Docker | **Not installed** / not on PATH | Pi foundation installs via `scripts/install-docker.sh`. |
| SSH keys | **No `~/.ssh` directory** at inventory time | Create ed25519 key before Imager flash ([FLASH.md](FLASH.md)). |
| Victron-related Mac apps | VictronConnect.app; local projects `~/VictronFlipper`, `~/VictronFlipper-fw` (Flipper tools — not Pi host services) | Do not migrate Flipper projects to Pi 1. |
| Other LaunchAgents | Steam, Epic, Riot, Google updater, SteerMouse | Do not migrate. |

Treat a real Discord command/response test as required; PM2 “online” alone is not proof of health. PM2 logs historically included Discord/Google API errors and a Discord.js ready-event deprecation warning.

## Fill before buying or wiring

- [ ] Raspberry Pi 4 RAM size: `____ GB`
- [ ] Pi power source and rating: `____`
- [ ] USB SSD make/model/capacity: `____`
- [ ] SmartShunt exact model/firmware/serial (photo label): `____`
- [ ] SmartSolar exact model/firmware/serial (photo label): `____`
- [ ] Orion label and model: `____` (confirm **Orion-Tr Smart** versus **Orion XS**)
- [ ] Number of genuine galvanically isolated VE.Direct-USB cables (**ASS030530000**): `____` (need **2** for shunt + MPPT)
- [ ] NUC make/model (escape hatch): `____`
- [ ] NUC adapter output: `____ V / ____ A / ____ W`
- [ ] Candidate 12 V → 19 V regulated DC-DC continuous/peak: `____`
- [ ] Existing Arlo cameras (count/models): `____`
- [ ] Local RTSP/H.264 camera candidates + substream support: `____`
- [ ] Confirm Shelly Plus RGBW PM still at `192.168.1.168` / DHCP reservation: `____`
- [ ] Router DHCP reservation for `pi-low-power`: `____`
- [ ] Tailnet owner / device approval policy: `____`

## Pre-cutover captures

1. In Scrypted, screenshot System Settings, installed plugins, device list, HomeKit pairings, and stream settings.
2. Back up Scrypted while stopped:
   `launchctl unload ~/Library/LaunchAgents/app.scrypted.server.plist`, archive `~/.scrypted/volume`, then reload.
3. Confirm bot env **names** only; transfer `.env` via `scp`/secure channel, never Git. Optional helper: `./scripts/package-from-mac.sh`.
4. Decide Homebridge: remain on Mac, migrate later, or retire after Shelly/HA parity.
5. Photograph Victron labels (especially Orion) into a private folder (not required in Git).

## Physical inventory commands (on the Pi)

Attach **one** VE.Direct cable at a time:

```bash
lsusb
ls -l /dev/serial/by-id/
udevadm info --query=property --name=/dev/ttyUSB0
dmesg --ctime | tail -n 50
```

Record each `/dev/serial/by-id/...` path in `.env` as `VE_DIRECT_SHUNT` / `VE_DIRECT_MPPT`. Do not rely on shifting `/dev/ttyUSB0` numbers. Optional udev helper: [`udev/99-victron-vedirect.rules`](udev/99-victron-vedirect.rules).

## Camera strategy (decision)

| Role | Plan |
| --- | --- |
| Arlo | Scrypted **bridge / live-view / HomeKit** only — not Scrypted NVR target |
| New local cams | ONVIF/RTSP **H.264** only for any [NVR-LAZY.md](NVR-LAZY.md) trial |
| Escape hatch | NUC + regulated 12→19 V DC-DC if Pi NVR aborts |

## NUC PSU sizing note

When filling the NUC rows above: size the DC-DC to the **stock 19 V adapter amp rating + headroom**, never feed raw “12 V” into a 19 V barrel. Details in [EXPAND.md](EXPAND.md).
