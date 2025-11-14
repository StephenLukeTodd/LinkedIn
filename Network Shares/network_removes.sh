#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# network_removes.sh
# Purpose: Scan all Proxmox LXC containers and remove any container mount bindings (mpX) that
#          reference host paths backed by network filesystems (CIFS/SMB, NFS, SSHFS, etc.).
#          Optionally unmount those network shares on the host and clean matching /etc/fstab entries.
#
# Usage:
#   sudo bash network_removes.sh [--yes] [--dry-run] [--no-host-unmount] [--purge-credentials]
#
# Behavior:
#   1) Detect network-backed mountpoints on the host by parsing /proc/mounts (types: cifs, nfs, nfs4, fuse.sshfs).
#   2) For each /etc/pve/lxc/<CTID>.conf, remove any mpX lines whose SOURCE path lies under those mountpoints.
#   3) If modified, restart the container.
#   4) Optionally unmount the network mounts on the host and remove associated /etc/fstab lines.
#   5) Optionally remove SMB credentials files referenced in /etc/fstab (and common defaults like /root/.smbcredentials).
#
# Safety:
#   - Backs up each LXC config before editing: <conf>.bak-YYYYmmdd_HHMMSS
#   - Interactive confirmation unless --yes is passed.
#   - --dry-run performs no writes.

YES=no
DRY_RUN=no
HOST_UNMOUNT=yes
PURGE_CREDS=no

for arg in "$@"; do
  case "$arg" in
    --yes|-y) YES=yes ;;
    --dry-run) DRY_RUN=yes ;;
    --no-host-unmount) HOST_UNMOUNT=no ;;
    --purge-credentials) PURGE_CREDS=yes ;;
    -h|--help)
      echo "Usage: sudo bash network_removes.sh [--yes] [--dry-run] [--no-host-unmount] [--purge-credentials]"; exit 0 ;;
    *) echo "Unknown arg: $arg"; exit 1 ;;
  esac
done

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "❌ Please run as root." >&2
  exit 1
fi

if ! command -v pct >/dev/null 2>&1; then
  echo "❌ This script must run on a Proxmox host (pct not found)." >&2
  exit 1
fi

# 1) Identify network-backed mountpoints on the host
NETWORK_TYPES=(cifs nfs nfs4 fuse.sshfs)
NET_MNTS=()
while read -r src mp fstype opts _; do
  for t in "${NETWORK_TYPES[@]}"; do
    if [[ "$fstype" == "$t" ]]; then
      NET_MNTS+=("$mp|$src|$fstype|$opts")
      break
    fi
  done
done < <(awk '{print $1, $2, $3, $4, $5}' /proc/mounts)

if [[ ${#NET_MNTS[@]} -eq 0 ]]; then
  echo "ℹ️  No network-backed mounts (cifs/nfs/sshfs) detected on the host."
else
  echo "🔎 Detected network mounts on host:"
  for m in "${NET_MNTS[@]}"; do
    IFS='|' read -r mp src fstype opts <<<"$m"
    echo "   • $mp  (type=$fstype, src=$src)"
  done
fi

# Helper: does PATH lie under MOUNTPOINT?
under_mount() {
  local path="$1"; local mountpoint="$2"
  [[ "$path" == "$mountpoint"* ]] || [[ "$path" == "$mountpoint/"* ]]
}

TS=$(date +%Y%m%d_%H%M%S)
CHANGED_CTS=()

# 2) Iterate containers and remove matching mpX lines
mapfile -t CTIDS < <(pct list | awk 'NR>1 {print $1}')
if [[ ${#CTIDS[@]} -eq 0 ]]; then
  echo "ℹ️  No LXC containers found."
else
  printf "\n🧰 Scanning LXC configs for network-backed mounts...\n"
fi

for CTID in "${CTIDS[@]:-}"; do
  CONF="/etc/pve/lxc/${CTID}.conf"
  [[ -f "$CONF" ]] || continue

  # Gather mp lines
  mapfile -t MPLINES < <(grep -nE '^mp[0-9]+:' "$CONF" || true)
  [[ ${#MPLINES[@]} -gt 0 ]] || continue

  TO_DELETE_LINES=()
  for L in "${MPLINES[@]}"; do
    LINENO=${L%%:*}
    TEXT=${L#*:}
    # Extract source path (before comma or ",mp=")
    SRC=${TEXT#mp[0-9]: }
    SRC=${SRC%%,mp=*}
    SRC=${SRC%%,*}

    # If no network mounts detected, conservatively consider paths under /mnt or /media as candidates
    CANDIDATE=no
    if [[ ${#NET_MNTS[@]} -gt 0 ]]; then
      for m in "${NET_MNTS[@]}"; do
        IFS='|' read -r mp src fstype opts <<<"$m"
        if under_mount "$SRC" "$mp"; then CANDIDATE=yes; break; fi
      done
    else
      if [[ "$SRC" == /mnt/* || "$SRC" == /media/* ]]; then CANDIDATE=yes; fi
    fi

    if [[ "$CANDIDATE" == yes ]]; then
      TO_DELETE_LINES+=("$LINENO")
    fi
  done

  if [[ ${#TO_DELETE_LINES[@]} -eq 0 ]]; then
    echo "CT $CTID: no network-backed mp entries found."
    continue
  fi

  echo "CT $CTID: will remove mp lines: ${TO_DELETE_LINES[*]} from $CONF"
  if [[ "$DRY_RUN" == yes ]]; then
    continue
  fi

  if [[ "$YES" != yes ]]; then
    read -r -p "Proceed to edit $CONF ? [y/N]: " ans
    [[ $ans =~ ^[Yy]$ ]] || { echo "  ↳ skipped"; continue; }
  fi

  cp -a "$CONF" "${CONF}.bak-${TS}"

  # Build sed script to delete specific lines
  SED_EXPR=()
  for ln in "${TO_DELETE_LINES[@]}"; do
    SED_EXPR+=("${ln}d")
  done
  # shellcheck disable=SC2016
  sed -i.bak-tmp -e "$(IFS=';'; echo "${SED_EXPR[*]}")" "$CONF"
  rm -f "${CONF}.bak-tmp"

  echo "  ✅ Removed ${#TO_DELETE_LINES[@]} mp entries (backup: ${CONF}.bak-${TS})"
  CHANGED_CTS+=("$CTID")

done

# 3) Reboot changed containers (only if running)
if [[ ${#CHANGED_CTS[@]} -gt 0 ]]; then
  printf "\n🔄 Restarting modified containers: %s\n" "${CHANGED_CTS[*]}"
  if [[ "$DRY_RUN" != yes ]]; then
    for CTID in "${CHANGED_CTS[@]}"; do
      if pct status "$CTID" | grep -q running; then
        if ! pct reboot "$CTID"; then
          echo "  ⚠️ Failed to reboot CT $CTID"
        fi
      else
        echo "  ⏩ CT $CTID is not running; skipping reboot."
      fi
    done
  else
    echo "(dry-run) Skipping reboots."
  fi
else
  printf "\nℹ️  No container changes required.\n"
fi

# 4) Optionally unmount network mounts and clean fstab
if [[ "$HOST_UNMOUNT" == yes && ${#NET_MNTS[@]} -gt 0 ]]; then
  printf "\n🧹 Host cleanup: unmount and prune /etc/fstab entries for detected network mounts.\n"
  if [[ "$DRY_RUN" == yes ]]; then
    echo "(dry-run) Would unmount and remove matching /etc/fstab lines for:"
    for m in "${NET_MNTS[@]}"; do IFS='|' read -r mp _ _ _ <<<"$m"; echo "   • $mp"; done
  else
    if [[ "$YES" != yes ]]; then
      read -r -p "Proceed to unmount and clean fstab on host? [y/N]: " ans
      [[ $ans =~ ^[Yy]$ ]] || { echo "  ↳ host cleanup skipped"; exit 0; }
    fi

    for m in "${NET_MNTS[@]}"; do
      IFS='|' read -r mp src fstype opts <<<"$m"
      # Attempt unmount
      umount "$mp" 2>/dev/null || true
      # Remove fstab lines that match the mountpoint or the device and are of these ftypes
      sed -i "/[[:space:]]$(printf '%s' "$mp" | sed 's:/:\\/:g')[[:space:]]/d" /etc/fstab
      sed -i "/^$(printf '%s' "$src" | sed 's:/:\\/:g')[[:space:]]/d" /etc/fstab
      echo "  ✅ Cleaned fstab and unmounted $mp ($fstype)"
    done
  fi
fi

# 5) Optionally remove SMB credentials files
# Collect credentials= paths from /etc/fstab and include common defaults
mapfile -t CREDS_FROM_FSTAB < <(awk '/[[:space:]]cifs[[:space:]]/ && $0 ~ /credentials=/{
  match($0, /credentials=([^,[:space:]]+)/, a); if (a[1] != "") print a[1]
}' /etc/fstab | sort -u)

CANDIDATE_CREDS=()
for c in "${CREDS_FROM_FSTAB[@]}"; do
  [[ -n "$c" ]] && CANDIDATE_CREDS+=("$c")
done
# Add common default if present
[[ -f /root/.smbcredentials ]] && CANDIDATE_CREDS+=("/root/.smbcredentials")

# De-duplicate
UNIQ_CREDS=()
for path in "${CANDIDATE_CREDS[@]}"; do
  skip=no
  for u in "${UNIQ_CREDS[@]}"; do [[ "$u" == "$path" ]] && { skip=yes; break; }; done
  [[ $skip == no ]] && UNIQ_CREDS+=("$path")
done

if [[ ${#UNIQ_CREDS[@]} -gt 0 ]]; then
  printf "\n🗝️  SMB credentials files detected:\n"
  for p in "${UNIQ_CREDS[@]}"; do echo "   • $p"; done

  DO_PURGE=$PURGE_CREDS
  if [[ "$DO_PURGE" != yes ]]; then
    read -r -p "Remove these credentials files now? [y/N]: " ans
    [[ $ans =~ ^[Yy]$ ]] && DO_PURGE=yes || DO_PURGE=no
  fi

  if [[ "$DO_PURGE" == yes ]]; then
    if [[ "$DRY_RUN" == yes ]]; then
      echo "(dry-run) Would securely delete credentials files above."
    else
      for p in "${UNIQ_CREDS[@]}"; do
        if [[ -f "$p" ]]; then
          # Attempt secure delete; fall back to rm
          if command -v shred >/dev/null 2>&1; then
            shred -u -z -n 3 "$p" || rm -f "$p"
          else
            rm -f "$p"
          fi
          echo "  ✅ Removed $p"
        fi
      done
    fi
  else
    echo "ℹ️  Keeping credentials files."
  fi
else
  printf "\nℹ️  No SMB credentials files detected.\n"
fi

printf "\n🎉 Done.\n"
