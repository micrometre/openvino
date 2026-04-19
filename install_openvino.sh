#!/bin/bash
set -euo pipefail

####################################
# Intel OpenVINO installation script
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

check_command() {
  command -v "$1" >/dev/null 2>&1 || abort "Required command '$1' is not installed."
}

if [[ $(id -u) -ne 0 ]]; then
  abort "This script must be run with sudo or as root."
fi

info "Starting Intel OpenVINO installer..."

if [[ -r /etc/os-release ]]; then
  source /etc/os-release
else
  abort "Cannot read /etc/os-release. Unsupported system."
fi

if [[ "$ID" != "ubuntu" ]]; then
  abort "Unsupported distribution: $ID. This installer supports Ubuntu only."
fi

if [[ "$VERSION_ID" != "24.04" ]]; then
  warn "This script is optimized for Ubuntu 24.04. Detected $VERSION_ID. It may still work, but proceed with caution."
fi

check_command wget
check_command gpg
check_command apt-get

REPO_CODENAME="ubuntu24"
REPO_URL="https://apt.repos.intel.com/openvino"
KEY_URL="https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB"
KEYRING_PATH="/usr/share/keyrings/intel-openvino-archive-keyring.gpg"
LIST_PATH="/etc/apt/sources.list.d/intel-openvino.list"
PACKAGE_NAME="openvino"  # Will auto-detect version if specific version is unavailable

info "Installing prerequisite packages..."
apt-get update -qq 2>/dev/null || true
apt-get install -y --no-install-recommends ca-certificates wget gnupg curl >/dev/null
success "Prerequisites are installed."

info "Downloading Intel OpenVINO GPG key..."
wget -qO /tmp/intel-openvino-key.pub "$KEY_URL"
if [[ ! -s /tmp/intel-openvino-key.pub ]]; then
  abort "Failed to download Intel GPG key from $KEY_URL"
fi

info "Installing key to the system keyring..."
if ! cat /tmp/intel-openvino-key.pub | gpg --dearmor > /tmp/intel-openvino-archive-keyring.gpg 2>&1; then
  abort "Failed to dearmor GPG key."
fi

if ! install -o root -g root -m 644 /tmp/intel-openvino-archive-keyring.gpg "$KEYRING_PATH"; then
  abort "Failed to install GPG key to $KEYRING_PATH"
fi

# Verify the key was installed
if [[ ! -f "$KEYRING_PATH" ]]; then
  abort "GPG key file does not exist at $KEYRING_PATH"
fi

rm -f /tmp/intel-openvino-key.pub /tmp/intel-openvino-archive-keyring.gpg
success "GPG key installed at $KEYRING_PATH."

info "Registering Intel OpenVINO APT repository..."
mkdir -p /etc/apt/sources.list.d
echo "deb [signed-by=${KEYRING_PATH}] ${REPO_URL} ${REPO_CODENAME} main" | tee "$LIST_PATH" >/dev/null
success "Repository added to $LIST_PATH."

info "Refreshing package lists with signed repository..."
apt-get update
success "Package lists refreshed."

info "Detecting available OpenVINO packages..."
available_packages=$(apt-cache search "^openvino" 2>/dev/null | awk '{print $1}' | sort -u)

if [[ -z "$available_packages" ]]; then
  abort "No OpenVINO packages found in the repository. Check repository configuration or internet connectivity."
fi

info "Available OpenVINO packages:"
echo "$available_packages" | sed 's/^/  - /'

# Try to install the latest openvino-runtime or openvino package
package_to_install=""
if echo "$available_packages" | grep -q "^openvino-runtime$"; then
  package_to_install="openvino-runtime"
elif echo "$available_packages" | grep -q "^openvino$"; then
  package_to_install="openvino"
else
  # Use the first available package
  package_to_install=$(echo "$available_packages" | head -1)
fi

success "Will install: $package_to_install"

info "Installing OpenVINO ($package_to_install)..."
if apt-get install -y "$package_to_install"; then
  success "OpenVINO installed successfully."
else
  abort "Failed to install $package_to_install. Check package name or repository access."
fi

info "Installation finished."

echo
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Reboot your system if prompted."
echo "  2. Verify installation with: apt-cache policy $PACKAGE_NAME"
echo "  3. Run OpenVINO demos or use the Python/OpenVINO SDK as needed."

exit 0
