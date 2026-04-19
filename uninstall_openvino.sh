#!/bin/bash
set -euo pipefail

####################################
# Intel OpenVINO uninstallation script
# Supported: Ubuntu 24.04
####################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
  echo -e "${BLUE}==>${NC} $1"
}

success() {
  echo -e "${GREEN}✓${NC} $1"
}

warn() {
  echo -e "${YELLOW}!${NC} $1"
}

error() {
  echo -e "${RED}✗${NC} $1"
}

abort() {
  error "$1"
  exit 1
}

if [[ $(id -u) -ne 0 ]]; then
  abort "This script must be run with sudo or as root."
fi

info "Starting Intel OpenVINO uninstaller..."

KEYRING_PATH="/usr/share/keyrings/intel-openvino-archive-keyring.gpg"
LIST_PATH="/etc/apt/sources.list.d/intel-openvino.list"

# Remove OpenVINO packages
info "Removing OpenVINO packages..."
if apt-get remove -y openvino openvino-runtime 2>/dev/null || true; then
  success "OpenVINO packages removed."
else
  warn "No OpenVINO packages found to remove."
fi

# Clean up APT
info "Cleaning up package cache..."
apt-get autoremove -y >/dev/null 2>&1 || true
apt-get clean >/dev/null 2>&1 || true
success "Cache cleaned."

# Remove repository entry
info "Removing Intel OpenVINO repository..."
if [[ -f "$LIST_PATH" ]]; then
  rm -f "$LIST_PATH"
  success "Repository entry removed from $LIST_PATH"
else
  warn "Repository entry not found at $LIST_PATH"
fi

# Remove GPG key
info "Removing Intel OpenVINO GPG key..."
if [[ -f "$KEYRING_PATH" ]]; then
  rm -f "$KEYRING_PATH"
  success "GPG key removed from $KEYRING_PATH"
else
  warn "GPG key not found at $KEYRING_PATH"
fi

# Refresh package lists
info "Refreshing package lists..."
apt-get update >/dev/null 2>&1
success "Package lists refreshed."

echo
echo -e "${GREEN}Uninstallation completed!${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "  • OpenVINO packages removed"
echo "  • APT repository and GPG key removed"
echo "  • Cache cleaned"
echo ""

exit 0
