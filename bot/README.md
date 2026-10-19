# Discord bot packaging notes

Canonical Mac source: `/Users/jh/metal-detected-bot` (PM2 name `MetalDetected`).

Do **not** commit the bot source or `.env` into this repo. On the Pi:

1. Rsync or unpack into `$DATA_ROOT/apps/metal-detected-bot` (see [MIGRATION.md](../MIGRATION.md)).
2. Ensure that tree has its own `.env` with `DISCORD_TOKEN` and `GEMINI_API_KEY`.
3. Set `DISCORD_BOT_SOURCE` in the repo `.env`.
4. Run `../scripts/prepare-discord-bot.sh` (copies `docker/discord-bot/Dockerfile.pi`).
5. `docker compose -f ../compose.workloads.yaml up -d --build`.

The `Dockerfile` in this folder is a minimal fallback for local experiments; production builds use `Dockerfile.pi` injected by the prepare script.
