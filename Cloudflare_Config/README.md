# Cloudflare_Config — Tunnel & TLS Helpers

Folder: `Cloudflare_Config/`

This folder contains small automation scripts to manage Cloudflare tunnel tokens and to toggle/rollback TLS ingress changes. These are designed to speed up repetitive tasks while keeping credentials and backups safe.

Files:

- `insert_cloudflare_token.sh` — interactive helper: paste a Cloudflare tunnel token JSON, saves credentials to `~/.cloudflared/<TUNNEL_ID>.json` and creates a `config-<TUNNEL_ID>.yml` with an ingress rule. Intended for safe local setup.
- `cloudflare_tunnel_ingress_tls_disable.sh` — more complex script that interacts with the Cloudflare API to change ingress/TLS settings for a zone and create a local backup of cloudflared config. Uses `jq` and `curl`.
- `cloudflare_tunnel_ingress_tls_rollback.sh` — finds the most recent backup of a `cloudflared` config and restores it; starts the tunnel if not running.

Usage & safety:

- All scripts either prompt for input or require you to pass credentials interactively. They deliberately avoid hardcoding API tokens in the repo.
- `cloudflare_tunnel_ingress_tls_disable.sh` and rollback create local `.bak` files before making changes — good to point out in interviews when discussing safe change management.

Suggested talking points:

- API automation best practices (minimal privileges, backups, explicit user prompts).
- Error handling and validations before applying changes to DNS or tunnels.
