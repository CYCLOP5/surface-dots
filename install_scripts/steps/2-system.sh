# System Configuration

log "Enabling Services..."

# SDDM
if [ ! -L /etc/systemd/system/display-manager.service ]; then
    log "Enabling SDDM..."
    execute sudo systemctl enable sddm
fi

# NetworkManager
log "Enabling NetworkManager..."
execute sudo systemctl enable --now NetworkManager

# Bluetooth
log "Enabling Bluetooth..."
execute sudo systemctl enable --now bluetooth

# Auto-cpufreq (good for laptops)
log "Enabling auto-cpufreq..."
execute sudo systemctl enable --now auto-cpufreq

# Add user to groups
log "Adding user $USER to groups (video, input, storage)..."
execute sudo usermod -aG video,input,storage "$USER"

# --- NVIDIA Configuration ---
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq "nvidia"; then
    log "Configuring Nvidia modules in mkinitcpio..."
    
    # 1. Add nvidia modules to mkinitcpio to enable DRM modesetting early
    # This avoids generic "black screen" issues on sddm start
    if ! grep -q "nvidia_drm" /etc/mkinitcpio.conf; then
        execute sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
        log "Regenerating initramfs..."
        execute sudo mkinitcpio -P
    fi

    # 2. Add Kernel Parameter for modeset via a file in modprobe.d (safer than bootloader edit)
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        echo "[DRY-RUN] echo 'options nvidia_drm modeset=1' | sudo tee /etc/modprobe.d/nvidia.conf"
    else
        echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null
    fi
    
    # 3. Add Environment variables for Hyprland
    # We will append check logic to hyprland.conf in step 3 or here.
    # Let's create a global env file for hyprland that we can source
    execute mkdir -p "$HOME/.config/hypr"
    
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log "[DRY-RUN] Would write to $HOME/.config/hypr/nvidia.conf"
    else
        cat > "$HOME/.config/hypr/nvidia.conf" <<EOF
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
cursor {
    no_hardware_cursors = true
}
EOF
    fi

    # Ensure owner is correct
    execute chown "$USER:$USER" "$HOME/.config/hypr/nvidia.conf"
    log "Created Nvidia environment config at ~/.config/hypr/nvidia.conf"
fi
