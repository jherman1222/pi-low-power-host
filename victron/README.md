# Legacy Victron folder

The active VE.Direct → MQTT path is:

- Bridge image: [`docker/vedirect-mqtt/`](../docker/vedirect-mqtt/)
- Compose: [`compose.victron.yaml`](../compose.victron.yaml)
- Docs: [`ORION.md`](../ORION.md)
- HA stubs: [`docker/homeassistant/packages/victron_mqtt.yaml`](../docker/homeassistant/packages/victron_mqtt.yaml)
- Optional udev: [`udev/99-victron-vedirect.rules`](../udev/99-victron-vedirect.rules)

Files in this `victron/` directory are retained only as reference scaffolding. Do not start them alongside `compose.victron.yaml`.
