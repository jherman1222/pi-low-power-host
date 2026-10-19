#!/usr/bin/env bash
# Prepare Mosquitto config + password file under DATA_ROOT, then ready for compose.yaml.
set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f .env ]]; then
  echo "Copy .env.example to .env and set MQTT credentials first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

: "${DATA_ROOT:?DATA_ROOT is required}"
: "${MQTT_USER:?MQTT_USER is required}"
: "${MQTT_PASSWORD:?MQTT_PASSWORD is required}"

if [[ "${MQTT_PASSWORD}" == "replace-with-a-long-random-password" ]]; then
  echo "Change MQTT_PASSWORD in .env before continuing." >&2
  exit 1
fi

sudo install -d -m 0750 \
  "${DATA_ROOT}/mosquitto/config" \
  "${DATA_ROOT}/mosquitto/data" \
  "${DATA_ROOT}/mosquitto/log" \
  "${DATA_ROOT}/homeassistant" \
  "${DATA_ROOT}/metal-detected/archive" \
  "${DATA_ROOT}/apps"

sudo install -m 0644 mosquitto/config/mosquitto.conf \
  "${DATA_ROOT}/mosquitto/config/mosquitto.conf"

docker run --rm \
  -v "${DATA_ROOT}/mosquitto/config:/work" \
  eclipse-mosquitto:2 \
  mosquitto_passwd -b -c /work/passwd "${MQTT_USER}" "${MQTT_PASSWORD}"

# Mosquitto image runs as uid 1883
sudo chown -R 1883:1883 \
  "${DATA_ROOT}/mosquitto/config" \
  "${DATA_ROOT}/mosquitto/data" \
  "${DATA_ROOT}/mosquitto/log"
sudo chmod 0640 "${DATA_ROOT}/mosquitto/config/passwd"
sudo chown -R "${USER}:$(id -gn)" "${DATA_ROOT}/homeassistant" \
  "${DATA_ROOT}/metal-detected" "${DATA_ROOT}/apps"

echo "Mosquitto config + passwd ready under ${DATA_ROOT}/mosquitto"
echo "Next: docker compose -f compose.yaml up -d"
