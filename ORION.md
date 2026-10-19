# Victron VE.Direct to MQTT

This repository uses a small local Python bridge (`docker/vedirect-mqtt`) rather than Venus OS. One container reads each isolated VE.Direct serial cable and publishes retained JSON plus individual fields to Mosquitto.

## Electrical and USB safety

- Use a genuine or reputable **galvanically isolated** VE.Direct-to-USB cable for each SmartShunt and SmartSolar. Do not improvise a non-isolated TTL cable in a vehicle/solar electrical system.
- Power down and follow Victron wiring instructions before connecting. USB isolation does not make unsafe DC wiring safe.
- Use persistent `/dev/serial/by-id/...` names, never `/dev/ttyUSB0`.
- Add a powered USB hub if several serial/radio devices cause resets. Keep the SSD on a reliable USB 3 path.
- Attach one cable at a time and label both physical ends. Record IDs in `INVENTORY.md`.
- The bridge is telemetry-only. It does not write settings or control chargers.

## Serial / udev notes

- Prefer `/dev/serial/by-id/usb-VictronEnergy_...` paths in `.env`.
- Optional helper rules: [`udev/99-victron-vedirect.rules`](udev/99-victron-vedirect.rules) (reload with `udevadm control --reload-rules`).
- Compose adds the container to group `dialout` and binds each cable to `/dev/vedirect` inside the container.
- **Isolated cable warning:** use galvanically isolated VE.Direct-USB (Victron ASS030530000 or equivalent). Non-isolated USB-TTL adapters are a ground-loop / safety risk on battery systems.

## Bring-up on Pi

With Mosquitto already running:

```bash
cd /path/to/pi-low-power-host
ls -l /dev/serial/by-id/
# Set exact VE_DIRECT_SHUNT and VE_DIRECT_MPPT paths in .env
docker compose -f compose.victron.yaml build --pull
docker compose -f compose.victron.yaml up -d
docker compose -f compose.victron.yaml logs -f
```

The external network is created by the foundation stack (`compose.yaml`). If it is absent, start the foundation stack first.

Inspect topics:

```bash
docker exec mosquitto mosquitto_sub \
  -h 127.0.0.1 -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
  -t 'victron/#' -v
```

Topic map:

| Topic | Payload |
| --- | --- |
| `victron/smartshunt/availability` | `online` / `offline` |
| `victron/smartshunt/state` | JSON frame; commonly `V`, `I`, `P`, `SOC`, `CE`, `TTG` |
| `victron/smartshunt/<field>` | One normalized field |
| `victron/smartsolar/availability` | `online` / `offline` |
| `victron/smartsolar/state` | JSON frame; commonly `V`, `VPV`, `PPV`, `I`, `CS`, history fields |
| `victron/smartsolar/<field>` | One normalized field |

Voltage/current are normalized from millivolts/milliamps; SOC is normalized from per-mille to percent. VE.Direct fields vary by device/firmware. Compare initial readings with VictronConnect before trusting alerts.

## Home Assistant

1. Add the MQTT integration using broker `127.0.0.1`, port `1883`, and credentials from `.env`.
2. Copy `docker/homeassistant/packages/victron_mqtt.yaml` to `${DATA_ROOT}/homeassistant/packages/`.
3. Add this once to `${DATA_ROOT}/homeassistant/configuration.yaml`:

```yaml
homeassistant:
  packages: !include_dir_named packages
```

4. Validate and restart:

```bash
docker exec homeassistant python -m homeassistant --script check_config --config /config
docker restart homeassistant
```

The sensor YAML is deliberately a stub for common fields. Observe actual frames and extend it for the exact models.

## Orion limitation

**Orion-Tr Smart has no VE.Direct port.** It cannot join this USB bridge and buying a third VE.Direct cable will not fix that. For the Orion-Tr Smart, use VictronConnect over Bluetooth for local monitoring/configuration.

Before planning any Orion integration, photograph the label and distinguish Orion-Tr Smart from Orion XS. Orion XS capabilities differ, but should be evaluated from its current manual and the desired GX topology. Do not block this host deployment on Orion telemetry.

Future paths, if centralized Victron GX/VRM becomes valuable:

- Dedicated second Pi running Venus OS Large.
- Cerbo GX.
- A supported model/topology verified from current Victron documentation.

Do not replace the flexible Docker OS on Pi 1 just to gain GX behavior.

## Acceptance

- [ ] Both stable `/dev/serial/by-id` paths are documented.
- [ ] Containers return after reboot.
- [ ] MQTT availability changes to `offline` when a cable is removed.
- [ ] Shunt voltage/current/SOC agree with VictronConnect.
- [ ] MPPT battery/panel readings agree with VictronConnect in daylight.
- [ ] Home Assistant entities survive restart and do not expose MQTT publicly.
- [ ] No USB reset/undervoltage events occur during SSD and camera activity.
