# Canonical project tree

Use **`/Users/jh/Projects/pi-low-power-host`** as the canonical working tree.

Both trees exist and are useful, but this one is more complete for day-to-day work: split Compose files (`compose.yaml`, `compose.workloads.yaml`, `compose.victron.yaml`), foundation install scripts, `SSD.md` / `REMOTE.md`, HA Victron package stubs, and newer doc revisions.

The parallel tree at **`/Users/jh/pi-low-power-host`** is retained as reference/staging. It is not a pure subset — pull from it deliberately before discarding anything:

- `CHECKLIST.md`
- Mac packaging helper `scripts/03-package-from-mac.sh` and numbered bootstrap scripts
- Packaged `bot/` source (and any local `.env` — keep secrets out of Git)
- `docs/victron.md`, `docs/lazy-nvr.md`, Homebridge compose profile

Do not delete either tree until those uniques are reviewed/merged. Do not commit `.env` files.
