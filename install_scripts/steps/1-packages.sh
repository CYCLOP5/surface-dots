# Install Packages

# Lists derived from README.md
PKGS_HYPR=(
    hyprland
    hypridle
    hyprlock
    hyprshade
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    polkit-gnome
)

PKGS_SYSTEM=(
    sddm
    networkmanager
    bluez
    bluez-utils
    blueman
    lua
    xdg-utils
    curl
    jq
    auto-cpufreq
    brightnessctl
    playerctl
    pamixer
    pipewire
    pipewire-pulse
    wireplumber
    grim
    slurp
    swappy
    grimblast-git
    linux-headers
    base-devel
)

PKGS_UI=(
    mako
    swww
    waypaper
    rofi
    kitty
    firefox
    nwg-look
    qt6ct
    kvantum
    papirus-icon-theme
    ttf-manrope
    ttf-nerd-fonts-symbols
    inter-font
    quickshell
)

PKGS_APPS=(
    thunar
    vdirsyncer
    khal
)

# Extra Apps (User requested)
PKGS_EXTRAS=(
    zen-browser-bin
    visual-studio-code-bin
)

# Nvidia Packages
PKGS_NVIDIA=(
    nvidia-dkms
    nvidia-utils
    egl-wayland
    lib32-nvidia-utils
)

# Combine all base packages
ALL_PKGS=("${PKGS_HYPR[@]}" "${PKGS_SYSTEM[@]}" "${PKGS_UI[@]}" "${PKGS_APPS[@]}")

log "Updating repositories..."
execute yay -Sy

# --- NVIDIA DETECTION ---
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq "nvidia"; then
    log "Nvidia GPU detected! Installing Nvidia drivers (dkms)..."
    ALL_PKGS+=("${PKGS_NVIDIA[@]}")
else
    log "No Nvidia GPU detected. Skipping Nvidia drivers."
fi

# --- EXTRAS Prompt ---
# Check strictly for dry-run before asking for user input if we want to be fully non-interactive?
# But checking "dry run" implies we want to see the flow.
if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log "[DRY-RUN] Would ask: Install extra apps (Zen Browser, VS Code)? Defaulting to YES for simulation."
    install_extras="y"
else
    read -p "Install extra apps (Zen Browser, VS Code)? [Y/n] " install_extras
fi

if [[ ! "$install_extras" =~ ^[Nn]$ ]]; then
   ALL_PKGS+=("${PKGS_EXTRAS[@]}")
fi

log "Installing packages..."
# Install using yay to handle both official and AUR
# --needed skips already installed, --noconfirm for automation
execute yay -S --needed --noconfirm "${ALL_PKGS[@]}"

