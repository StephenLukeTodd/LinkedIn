# Network Shares

Folder: `Network Shares/`

This folder holds helper scripts for mounting/unmounting/testing network shares.

Files:

- `network_shares.sh` — helper to mount or configure network shares (review the script for the exact mount points and placeholders).
- `network_removes.sh` — helper to remove network mounts or cleanup stale entries.
- `network_test.sh` — diagnostic script to validate connectivity and permissions to network shares.

Suggested talking points:

- Use of idempotent mount/removal operations and test-driven diagnostics for troubleshooting.
- How to adapt scripts for different OSes and authentication methods (Kerberos, SMB credentials).
