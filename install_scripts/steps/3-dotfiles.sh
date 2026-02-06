# Dotfiles Installation

log "Backing up existing configurations..."
execute mkdir -p "$HOME/.config_backup_$(date +%Y%m%d)"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d)"

backup_if_exists() {
    if [ -d "$HOME/.config/$1" ] || [ -f "$HOME/.config/$1" ]; then
        execute mv "$HOME/.config/$1" "$BACKUP_DIR/"
        log "Backed up $1"
    fi
}

# List of configs to link/copy
# Based on workspace structure, we likely have these folders to map:
CONFIGS=(
    ags
    firefox
    khal
    mako
    rofi
    vdirsyncer
    color-schemes
    gtk-3.0
    kitty
    qt6ct
    spicetify
    zathura
    fastfetch
    hypr
    kvantum
    quickshell
)

log "Installing dotfiles to ~/.config/..."

for cfg in "${CONFIGS[@]}"; do
    if [ -d "$INSTALL_DIR/.config/$cfg" ]; then
        log "Processing $cfg..."
        backup_if_exists "$cfg"
        execute cp -r "$INSTALL_DIR/.config/$cfg" "$HOME/.config/"
    fi
done

# Handle individual files
if [ -f "$INSTALL_DIR/.config/starship.toml" ]; then
    log "Processing starship.toml..."
    backup_if_exists "starship.toml"
    execute cp "$INSTALL_DIR/.config/starship.toml" "$HOME/.config/"
fi

# Patch Hyprland for Nvidia if needed
if [ -f "$HOME/.config/hypr/nvidia.conf" ]; then
    log "Patching hyprland.conf to include Nvidia settings..."
    if ! grep -q "source = ~/.config/hypr/nvidia.conf" "$HOME/.config/hypr/hyprland.conf"; then
        # Append to the start of the file or after monitors
        execute sed -i '1i source = ~/.config/hypr/nvidia.conf' "$HOME/.config/hypr/hyprland.conf"
    fi
fi

# Fix monitors for generic resolution if previously hardcoded
# This is a basic patch to disable the surface hardcoding if not on surface
if ! grep -iq "Surface" /sys/devices/virtual/dmi/id/product_name 2>/dev/null; then
    log "Detecting non-Surface device. Disabling specific eDP-1 config..."
    execute sed -i 's/^monitor = eDP-1,2256x1504/#monitor = eDP-1,2256x1504/g' "$HOME/.config/hypr/hyprland.conf"
    execute sed -i 's/^monitor = eDP-1, 2256x1504/#monitor = eDP-1, 2256x1504/g' "$HOME/.config/hypr/hyprland.conf"
    # Enable auto match
    if ! grep -q "monitor = eDP-1, preferred, auto, 1" "$HOME/.config/hypr/hyprland.conf"; then
        if [ "${DRY_RUN:-0}" -eq 1 ]; then
             log "[DRY-RUN] echo 'monitor = , preferred, auto, 1' >> $HOME/.config/hypr/hyprland.conf"
        else
             echo "monitor = , preferred, auto, 1" >> "$HOME/.config/hypr/hyprland.conf"
        fi
    fi
fi

# Installing SDDM Theme
log "Installing SDDM Pixel Theme..."
# Use the preserved script for the specific sddm logic
if [ -f "$SCRIPTS_DIR/install-sddm-standalone.sh" ]; then
    # Pass --dry-run if enabled
    SDDM_ARGS="--yes"
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        SDDM_ARGS+=" --dry-run"
    fi
    execute sudo "$SCRIPTS_DIR/install-sddm-standalone.sh" $SDDM_ARGS
else
    log_err "SDDM installer script missing!"
fi


# Build Flutter App (Now Playing) if flutter is active
# (Skipped for barebone to keep it simple, unless requested)
