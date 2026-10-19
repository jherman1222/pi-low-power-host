# Bounded Scrypted NVR trial

Pi 4 is not the long-term NVR design. This optional trial starts only after the bridge stack has been stable for 48–72 hours and only with local RTSP cameras that provide native H.264 and a low-resolution substream.

**Arlo remains bridge/live-view only. Do not use Arlo as an NVR recording target.**

## Lazy Pi 4 profiles

| Stage | Cameras | Main recording stream | Analysis stream | Motion/detection | Storage | Gate to next stage |
| --- | ---: | --- | --- | --- | --- | --- |
| Baseline | 0 | None | None | None | USB SSD | Measure idle CPU, RAM, temperature, disk I/O, USB errors for 24 h. |
| Profile A | 1 | Direct H.264, camera-native resolution/FPS; no transcode | H.264 substream, about 640×360, 5–10 FPS, low bitrate | Camera hardware motion with tight zones; no software motion if avoidable | Dedicated SSD NVR directory with quota/retention | 24–48 h with no abort criterion. |
| Profile B | 2 | Same direct-record policy | Same low substream per camera | Hardware motion; conservative detections | USB SSD | 48 h including simultaneous streams/events and WAN interruption. |
| Profile C (hard ceiling) | 3 max | Direct H.264 only | Lowest usable H.264 substreams | Hardware motion and tight zones; minimal object detection | USB SSD | Keep only if the full 72 h and inverter-off tests pass comfortably. |

Camera setup rules:

- Disable H.265/H.265+, “smart codec,” and vendor bandwidth modes that force decoding/transcoding.
- Record the main stream directly; never decode/re-encode merely to save space.
- Analyze only the substream. Lower resolution/FPS before adding another camera.
- Prefer camera-side motion. Use tight inclusion/exclusion zones and longer cooldowns.
- Start with short retention and an explicit storage limit. Leave SSD free-space headroom.
- Add one camera at a time. Re-establish the baseline after every change.
- Do not add Coral, SDR, mesh radios, or other USB-heavy workloads during the trial.

## Measurements

Capture baseline and event-load observations:

```bash
docker stats --no-stream
uptime
free -h
df -h /srv/pi-data
sudo smartctl -a /dev/sda
vcgencmd measure_temp 2>/dev/null || cat /sys/class/thermal/thermal_zone0/temp
vcgencmd get_throttled 2>/dev/null || true
dmesg --ctime | grep -Ei 'usb|reset|under-voltage|voltage|uas|I/O error'
```

Log 5-minute and 1-hour CPU/load, peak temperature, dropped frames, stream-start delay, detection latency, SSD utilization, free space, and any USB errors. Test simultaneous recording plus two live views.

## Immediate abort to NUC

Stop expanding—or move NVR only to the NUC—if any of these recur under representative load:

- Sustained CPU saturation/high load that impairs Discord, MQTT, HA, or bridge streams.
- Dropped/corrupt frames, recordings with gaps, or unacceptable live-view latency.
- Thermal throttling or recurring temperature near the configured throttle range.
- USB resets, UAS/I/O errors, SSD disconnects, filesystem errors, or undervoltage.
- Required transcoding because cameras cannot supply usable native H.264 streams.
- Storage cannot meet retention without unsafe free-space pressure.
- More than three cameras, serious object detection, or multi-stream decoding is required.

A single unexplained USB reset or filesystem error pauses the trial until power/cabling/storage is diagnosed. Service degradation to core workloads is a failed trial even if Scrypted itself stays running.

## NUC escape hatch

Record the NUC model and original 19 V adapter current/wattage first. Use a regulated 12 V to 19 V DC-DC converter sized above measured peak demand with appropriate wiring, fuse, cooling, and headroom. Never feed raw nominal “12 V” into a 19 V NUC.

Move only NVR recording/detection to the NUC; the Pi can remain the low-power MQTT/HA/Discord/Victron host. Prefer the NUC iGPU for useful work per watt over forcing the Pi CPU into continuous decode/detection.

## Trial decision

- **Keep on Pi:** all core services remain responsive, no throttle/USB errors/drops, retention fits, and Profile A/B (at most C) passes 72 hours plus inverter-off.
- **Move to NUC:** any abort criterion, more demanding cameras/detection, more than three cameras, or operational babysitting is needed.
- **Stay bridge-only:** no suitable local H.264 RTSP cameras are available.

Record the date, profile, camera models/firmware, stream settings, metrics, incidents, and final decision in this file or an operations log. Use Tailscale for remote viewing; never port-forward the NVR through Starlink.
