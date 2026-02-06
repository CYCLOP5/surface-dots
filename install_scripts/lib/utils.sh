# Utility functions

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_err() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}"
    echo "============================================================"
    echo "   $1"
    echo "============================================================"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${GREEN}==> $1${NC}"
    echo "------------------------------------------------------------"
}

print_success() {
    echo ""
    echo -e "${GREEN}OK!${NC} $1"
}

ask_for_sudo() {
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log "[DRY-RUN] Would ask for sudo password here."
        return 0
    fi
    if [ "$EUID" -ne 0 ]; then 
        log "Please enter your password for sudo access."
        sudo -v
        # Keep-alive: update existing sudo time stamp until script has finished
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    fi
}

execute() {
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        log "Running: $*"
        "$@" >> "$LOG_FILE" 2>&1
    fi
}

package_installed() {
    pacman -Qi "$1" &> /dev/null
}
