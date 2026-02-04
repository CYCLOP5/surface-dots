#!/usr/bin/env bash
# surface-dots installer (Arch-ready, idempotent)
# Usage: sudo ./install.sh [--enable] [--restart] [--dry-run] [--yes]
set -euo pipefail
DRY_RUN=0
ENABLE=0
RESTART=0
ASSUME_YES=0
THEME_NAME="pixel"
SRC_DIR="$(dirname "$0")/sddm/themes/$THEME_NAME"
DST_DIR="/usr/share/sddm/themes/$THEME_NAME"
FONT_SRC="$SRC_DIR/fonts"
FONT_DST="/usr/share/fonts/TTF/$THEME_NAME"
BACKUP_SUFFIX="$(date +%Y%m%dT%H%M%S)"

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift;;
    --enable) ENABLE=1; shift;;
    --restart) RESTART=1; shift;;
    --yes|-y) ASSUME_YES=1; shift;;
    --help|-h) sed -n '1,160p' "$0"; exit 0;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "> DRY-RUN: $*"; return 0
  fi
  echo "> $*"
  bash -c "$*"
}

require_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "This installer requires root. Re-run with sudo." >&2
    exit 1
  fi
}

confirm() {
  if [ "$ASSUME_YES" -eq 1 ]; then return 0; fi
  read -r -p "$1 [y/N]: " ans
  case "$ans" in [Yy]*) return 0;; *) return 1;; esac
}

# Basic checks
if [ ! -d "$SRC_DIR" ]; then
  echo "Cannot find theme source at $SRC_DIR" >&2
  exit 2
fi

if command -v pacman >/dev/null 2>&1; then
  PKG_MANAGER="pacman"
else
  PKG_MANAGER="unknown"
fi

echo "surface-dots installer"
echo "  source: $SRC_DIR"
echo "  target: $DST_DIR"
[ "$DRY_RUN" -eq 1 ] && echo "  mode: DRY-RUN"

require_root

# Backup existing theme if present
if [ -d "$DST_DIR" ]; then
  echo "Found existing theme at $DST_DIR -> creating backup"
  run "mv '$DST_DIR' '${DST_DIR}.bak.$BACKUP_SUFFIX'"
fi

# Copy theme (rsync keeps permissions and makes operation idempotent)
run "rsync -a --delete --exclude='.git' --exclude='*.psd' '$SRC_DIR/' '$DST_DIR/'"

# Install fonts (if present)
if [ -d "$FONT_SRC" ]; then
  run "mkdir -p '$FONT_DST'"
  run "rsync -a '$FONT_SRC/' '$FONT_DST/'"
  run "fc-cache -f"
fi

# Optionally enable theme in SDDM config (safe, creates conf.d file)
if [ "$ENABLE" -eq 1 ]; then
  SDDM_CONF_DIR="/etc/sddm.conf.d"
  SDDM_CONF_FILE="$SDDM_CONF_DIR/99-surface-dots.conf"
  run "mkdir -p '$SDDM_CONF_DIR'"
  echo "Creating $SDDM_CONF_FILE (backing up existing if present)"
  if [ -f "$SDDM_CONF_FILE" ]; then
    run "cp '$SDDM_CONF_FILE' '${SDDM_CONF_FILE}.bak.$BACKUP_SUFFIX'"
  fi
  cat > /tmp/99-surface-dots.conf <<EOF
[Theme]
Current=$THEME_NAME
EOF
  run "mv /tmp/99-surface-dots.conf '$SDDM_CONF_FILE'"
  echo "SDDM theme set to '$THEME_NAME' (file: $SDDM_CONF_FILE)"
  echo "Note: applying the theme will not restart SDDM unless you pass --restart. Restarting will log out graphical sessions."
fi

if [ "$RESTART" -eq 1 ]; then
  if command -v systemctl >/dev/null 2>&1; then
    if confirm "Restart SDDM now? This will end the current graphical session."; then
      run "systemctl restart sddm"
    else
      echo "Skipping restart.";
    fi
  else
    echo "systemctl not available; cannot restart sddm automatically.";
  fi
fi


