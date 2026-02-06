# Pre-requisites check

if ! command -v git &> /dev/null; then
    log "Git not found. Installing git..."
    sudo pacman -S --noconfirm git
fi

if ! command -v yay &> /dev/null; then
    log "Yay AUR helper not found. Installing..."
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd "$INSTALL_DIR"
else
    log "Yay is already installed."
fi
