# Remote access to the Pi (phone, Mac, tailnet)

Goal: reach the Pi when you are away, and when the **Mac Mini is powered off**.

## Primary: Tailscale (do this first)

1. Install Tailscale on the Pi (`scripts/install-tailscale.sh`).
2. `sudo tailscale up` and approve the node in the admin console.
3. Optional but recommended: enable **Tailscale SSH**:
   ```bash
   sudo tailscale set --ssh
   ```
4. From Mac or phone (Tailscale app + Termius/Blink/Prompt):
   ```bash
   ssh <user>@<pi-magicdns-name>
   # or: ssh <user>@100.x.y.z
   ```
5. Open web UIs over the tailnet (no port-forwarding through Starlink):
   - Home Assistant: `http://<pi>:8123`
   - Scrypted: `https://<pi>:10443` (or your published port)
   - Prefer MagicDNS names over remembering CGNAT IPs

**This alone covers “remote from phone or Mac or any tailnet device” for a headless Docker host.**

### Optional: subnet router later

Only if you need LAN devices (cameras, Shelly at `192.168.1.168`) reachable from the phone without being on Wi‑Fi:

```bash
sudo tailscale set --advertise-routes=192.168.1.0/24
```

Approve routes in the Tailscale admin console. Not required for SSH/UIs on the Pi itself.

## Optional: RustDesk (GUI)

You already run RustDesk on the Mac. Mirror that on the Pi **only if** you want a full desktop GUI.

Trade-offs:

| | Tailscale SSH + web UIs | RustDesk on Pi |
|--|-------------------------|----------------|
| Power / RAM | Minimal | Higher (needs desktop or X) |
| Phone UX | Terminal + browser | Familiar RustDesk app |
| Headless Ubuntu Server | Perfect fit | Extra packages |

### Install sketch

```bash
# On Pi — see scripts/install-rustdesk.sh
sudo apt install -y rustdesk   # or install .deb from rustdesk.com
```

If using Ubuntu Server (no desktop):

1. Install a light DE (e.g. XFCE) **or** run a minimal X stack — expect more idle watts.
2. Enable RustDesk service; note **ID + password**.
3. Prefer connecting **over Tailscale IPs** so you do not open RustDesk ports to the public internet.
4. Keep Mac RustDesk as a **client**; the Pi becomes the **host** you care about when the inverter is off.

### Hardening

- Do not expose TCP 21115–21119 on the Starlink WAN.
- Bind or firewall so only tailnet / LAN can reach RustDesk, **or** use Tailscale IP only.
- Rotate the RustDesk permanent password; store it in your password manager.

## Alternatives

- **Raspberry Pi Connect** — convenient if you flash Pi OS; browser remote without RustDesk.
- **VS Code / Cursor Remote SSH** over Tailscale — great for editing compose files on the Pi.

## Day-1 checklist

- [ ] Tailscale connected; ping Pi from phone off home Wi‑Fi  
- [ ] `tailscale ssh` or normal SSH works  
- [ ] HA + Scrypted open in mobile browser via MagicDNS  
- [ ] (Optional) RustDesk host on Pi; connect from phone using Tailscale IP  
- [ ] Confirm Mac can be powered off without losing remote path  
