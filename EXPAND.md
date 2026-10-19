# Expand later—second-host parking lot

Do not add these roles until Pi 1 has passed its 72-hour observation and inverter-off tests. Pi 1 remains the flexible low-power application host; expansion must not turn it into a single point of failure for internet access.

## Full Victron GX/VRM

Trigger: remote VRM/GX appliance behavior, supported Victron control, or a richer integrated power view is worth dedicated hardware.

Preferred choices:

1. Cerbo GX for the supported appliance path.
2. A second compatible Pi running Venus OS Large for an experimental/lower-cost dedicated host.

Keep Venus OS off Pi 1 because it displaces Docker, Discord, Scrypted bridge, Tailscale, MQTT, and HA. Inventory supported hardware and interfaces against current Victron documentation before purchase. Orion-Tr Smart still has no VE.Direct port; a GX host does not create one.

## OpenWrt guest captive portal

Trigger: a real requirement for guest terms/splash/authentication beyond the Starlink/router guest network.

Use a **second** Pi or dedicated OpenWrt router with:

- Two well-understood network interfaces (built-in Ethernet plus a supported USB NIC, or managed VLANs).
- OpenWrt and openNDS.
- A dedicated guest SSID/VLAN.
- Starlink/router remaining the upstream gateway.
- A documented bypass/recovery route and fail-open/fail-closed decision.

Do not place Pi 1 inline as the only gateway. If it crashes, core internet must continue. Test captive-portal behavior across iOS, Android, DNS failure, WAN loss, reboot, and power loss before inviting users.

## Mesh, Meshtastic/MeshCore, and SDR

Trigger: the core host is stable and a specific radio use case has been selected.

Default placement is a second host or powered USB hub. Before attaching to Pi 1:

- Budget USB current and total DC power.
- Confirm serial device identities and stable `/dev/serial/by-id` names.
- Check RF placement, antenna separation, grounding, and enclosure heat.
- Measure whether USB 2/3 interference affects RTL-SDR or cameras.
- Ensure a radio crash/re-enumeration cannot block SSD or VE.Direct.
- Add one device at a time and repeat the 48-hour stability test.

Do not introduce MeshCore, RTL-SDR, NVR, and multiple VE.Direct adapters simultaneously.

## NUC for real NVR

Trigger: any criterion in `NVR-LAZY.md`, more than three cameras, or sustained detection/transcoding needs.

Use the NUC with a regulated 12 V to 19 V DC-DC converter sized from the adapter label plus headroom. Fuse and cool it appropriately. Keep MQTT, HA, Discord, and Victron on Pi 1; move only NVR-heavy work unless measurements justify more.

## Readiness gate for any expansion

- [ ] Pi 1 passed 72 hours and inverter-off test.
- [ ] Current backups restore successfully.
- [ ] Added idle and peak watts fit the DC/battery budget.
- [ ] Failure of the new host cannot take down internet or Pi 1.
- [ ] Cabling, labels, DHCP reservations, Tailscale ACLs, and recovery steps are documented.
- [ ] A rollback test exists.
- [ ] `INVENTORY.md` has model, firmware, power, and serial details.
