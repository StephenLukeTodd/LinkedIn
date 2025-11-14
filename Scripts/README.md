# scripts/

Collection of bash/shell utilities moved from the repository root for clearer organization.

Notable files:

- `HDD_Backup.sh` — rsync-based backup flows (placeholders for device UUIDs and paths).
- `openwebui_install.sh` — Docker install and container runner for Open WebUI.
- `organize_movies.sh` — organizes movie files into per-movie folders and supports undo/dry-run.
- `MoveAnime.sh` — helper to consolidate files inside directories listed in a CSV.
- `PLEX_MEGA_Setup.sh` — small wrapper for downloading media from MEGA to a destination.

Usage: see individual scripts for flags; many are designed to be idempotent and cron/systemd friendly.
