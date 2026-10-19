#!/usr/bin/env python3
"""Small VE.Direct text-mode to MQTT bridge for one serial device."""

import json
import os
import signal
import time
from typing import Any

import paho.mqtt.client as mqtt
import serial


SERIAL_DEVICE = os.environ.get("SERIAL_DEVICE", "/dev/vedirect")
SERIAL_BAUD = int(os.environ.get("SERIAL_BAUD", "19200"))
MQTT_HOST = os.environ.get("MQTT_HOST", "mosquitto")
MQTT_PORT = int(os.environ.get("MQTT_PORT", "1883"))
MQTT_PREFIX = os.environ.get("MQTT_PREFIX", "victron/device").strip("/")
PUBLISH_INTERVAL = float(os.environ.get("PUBLISH_INTERVAL", "2"))

SCALES = {
    "V": 0.001,       # battery voltage, mV -> V
    "VS": 0.001,      # auxiliary/starter voltage
    "VPV": 0.001,     # panel voltage
    "I": 0.001,       # current, mA -> A
    "IL": 0.001,      # load current
    "P": 1.0,         # power, W
    "PPV": 1.0,       # panel power, W
    "SOC": 0.1,       # per mille -> %
    "CE": 0.001,      # consumed Ah, mAh -> Ah
    "TTG": 1.0,       # minutes
    "H19": 0.01,      # yield total, 0.01 kWh
    "H20": 0.01,      # yield today, 0.01 kWh
    "H21": 1.0,       # max power today, W
    "H22": 0.01,      # yield yesterday, 0.01 kWh
    "H23": 1.0,       # max power yesterday, W
}

stop = False


def normalize(key: str, value: str) -> Any:
    if key in SCALES:
        try:
            return round(float(value) * SCALES[key], 4)
        except ValueError:
            return value
    return value


def request_stop(*_: object) -> None:
    global stop
    stop = True


def make_client() -> mqtt.Client:
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    username = os.environ.get("MQTT_USERNAME")
    if username:
        client.username_pw_set(username, os.environ.get("MQTT_PASSWORD", ""))
    client.will_set(f"{MQTT_PREFIX}/availability", "offline", retain=True)
    client.connect(MQTT_HOST, MQTT_PORT, keepalive=30)
    client.loop_start()
    client.publish(f"{MQTT_PREFIX}/availability", "online", retain=True)
    return client


def publish(client: mqtt.Client, frame: dict[str, Any]) -> None:
    frame["received_at"] = int(time.time())
    client.publish(
        f"{MQTT_PREFIX}/state",
        json.dumps(frame, separators=(",", ":")),
        qos=0,
        retain=True,
    )
    for key, value in frame.items():
        client.publish(f"{MQTT_PREFIX}/{key}", str(value), qos=0, retain=True)


def main() -> None:
    signal.signal(signal.SIGTERM, request_stop)
    signal.signal(signal.SIGINT, request_stop)
    client = make_client()
    frame: dict[str, Any] = {}
    last_publish = 0.0

    try:
        with serial.Serial(SERIAL_DEVICE, SERIAL_BAUD, timeout=2) as port:
            while not stop:
                raw = port.readline()
                if not raw:
                    continue
                # Checksum lines may contain non-UTF8 bytes; text fields remain usable.
                line = raw.decode("utf-8", errors="ignore").strip("\r\n")
                if "\t" not in line:
                    continue
                key, value = line.split("\t", 1)
                if key == "Checksum":
                    now = time.monotonic()
                    if frame and now - last_publish >= PUBLISH_INTERVAL:
                        publish(client, frame.copy())
                        last_publish = now
                    frame.clear()
                    continue
                if key:
                    frame[key] = normalize(key, value)
    finally:
        client.publish(f"{MQTT_PREFIX}/availability", "offline", retain=True)
        client.disconnect()
        client.loop_stop()


if __name__ == "__main__":
    main()
