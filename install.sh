#!/usr/bin/env bash
#
# Master Installer Script
# Inspired by end-4/dots-hyprland
#

set -e

# --- Configuration ---
INSTALL_DIR="$(dirname "$(readlink -f "$0")")"
export INSTALL_DIR
SCRIPTS_DIR="$INSTALL_DIR/install_scripts"
LOG_FILE="$INSTALL_DIR/install.log"

# --- Import Utils ---
source "$SCRIPTS_DIR/lib/utils.sh"

# --- Header ---
clear
print_header "SURFACE-DOTS INSTALLER"
echo "This script will install the environment for Arch Linux."
echo "It is designed to be idempotent (can be run multiple times)."
echo ""

# --- Usage ---
if [[ "$1" == "--help" ]]; then
    echo "Usage: ./install.sh [option]"
    echo "Options:"
    echo "  --full     Run full installation (packages, system, dots)"
    echo "  --core     Install packages and system config only"
    echo "  --dots     Install dotfiles only"
    echo "  --dry-run  Simulate the installation without making changes"
    echo "  --help     Show this message"
    exit 0
fi

# Dry Run Detection
if [[ "$*" == *"--dry-run"* ]]; then
    export DRY_RUN=1
    echo -e "\033[0;33m[!!!] DRY RUN MODE ACTIVE - No changes will be made [!!!]\033[0m"
    # Remove --dry-run from args so it doesn't mess up other logic
    set -- "${@/--dry-run/}"
fi

# --- Steps ---

# 0. Preparation
source "$SCRIPTS_DIR/steps/0-pre.sh"

run_full() {
    ask_for_sudo
    
    print_section "Phase 1: Packages"
    source "$SCRIPTS_DIR/steps/1-packages.sh"
    
    print_section "Phase 2: System Configuration"
    source "$SCRIPTS_DIR/steps/2-system.sh"
    
    print_section "Phase 3: Dotfiles & UI"
    source "$SCRIPTS_DIR/steps/3-dotfiles.sh"
    
    print_success "Installation Complete! Please reboot your system."
}

run_dots() {
    print_section "Phase 3: Dotfiles & UI (Only)"
    source "$SCRIPTS_DIR/steps/3-dotfiles.sh"
    print_success "Dotfiles installed."
}

# --- Main Logic ---
case "$1" in
    --full)
        run_full
        ;;
    --dots)
        run_dots
        ;;
    *)
        # Default behavior: Ask user
        echo "Select installation mode:"
        echo "1) Full Installation (Packages + System + Dotfiles)"
        echo "2) Dotfiles Only"
        echo "3) Exit"
        read -r -p "Enter choice [1-3]: " choice
        
        case $choice in
            1) run_full ;;
            2) run_dots ;;
            *) exit 0 ;;
        esac
        ;;
esac
