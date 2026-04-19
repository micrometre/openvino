#!/bin/bash
####################################
#
# Intel Iris Xe GPU Uninstallation Script
# Reverses the installation from install_driver.sh
# Optimized for Intel Iris Xe GPU on Ubuntu 24.04
# Dell Latitude 7340 (0C08)
#
####################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Intel Iris Xe GPU Uninstallation${NC}"
echo -e "${BLUE}Dell Latitude 7340 - Ubuntu 24.04${NC}"
echo ""

# Function to remove packages safely
remove_package() {
    local package=$1
    if dpkg -l | grep -q "^ii.*$package"; then
        echo -e "${YELLOW}Removing $package...${NC}"
        sudo apt remove --purge -y $package
    else
        echo -e "${YELLOW}$package not installed, skipping...${NC}"
    fi
}

# Function to remove repository
remove_repository() {
    local repo_file=$1
    local repo_name=$2
    if [ -f "/etc/apt/sources.list.d/$repo_file" ]; then
        echo -e "${YELLOW}Removing $repo_name repository...${NC}"
        sudo rm -f "/etc/apt/sources.list.d/$repo_file"
    else
        echo -e "${YELLOW}$repo_name repository not found, skipping...${NC}"
    fi
}

# Function to remove GPG key
remove_gpg_key() {
    local key_file=$1
    local key_name=$2
    if [ -f "/usr/share/keyrings/$key_file" ]; then
        echo -e "${YELLOW}Removing $key_name GPG key...${NC}"
        sudo rm -f "/usr/share/keyrings/$key_file"
    else
        echo -e "${YELLOW}$key_name GPG key not found, skipping...${NC}"
    fi
}

# Remove Intel GPU runtime packages
echo -e "${YELLOW}Removing Intel GPU runtime packages...${NC}"

# Core OpenCL packages
remove_package "intel-opencl-icd"
remove_package "ocl-icd-opencl-dev"

# Intel Level Zero packages
remove_package "intel-level-zero-gpu"
remove_package "level-zero"
remove_package "level-zero-dev"

# GPU monitoring tools
echo -e "${YELLOW}Removing GPU monitoring tools...${NC}"
remove_package "intel-gpu-tools"

# Remove Vulkan SDK and related packages
echo -e "${YELLOW}Removing Vulkan SDK...${NC}"
remove_package "vulkan-sdk"
remove_package "vulkan-tools"
remove_package "vulkan-validationlayers"
remove_package "vulkan-volk"

# Remove Intel repositories
echo -e "${YELLOW}Removing Intel repositories...${NC}"
remove_repository "intel-graphics.list" "Intel Graphics"
remove_gpg_key "intel-graphics.gpg" "Intel Graphics"

# Remove Vulkan repository
remove_repository "lunarg-vulkan-noble.list" "Lunarg Vulkan"
remove_gpg_key "lunarg-graphics.gpg" "Lunarg Vulkan"

# Update package lists
echo -e "${YELLOW}Updating package lists...${NC}"
sudo apt update

# Clean up any remaining dependencies
echo -e "${YELLOW}Cleaning up unused packages...${NC}"
sudo apt autoremove --purge -y
sudo apt autoclean

# Optional: Remove user from groups (commented out for safety)
echo -e "${YELLOW}Note: User groups (render, video) are preserved for system stability${NC}"
echo -e "${YELLOW}      To remove them manually, run:${NC}"
echo -e "${BLUE}      sudo gpasswd -d $USER render${NC}"
echo -e "${BLUE}      sudo gpasswd -d $USER video${NC}"

# Verify removal
echo ""
echo -e "${YELLOW}Verifying removal...${NC}"

if ! command -v clinfo &> /dev/null; then
    echo -e "${GREEN}✓ OpenCL tools removed${NC}"
else
    echo -e "${YELLOW}⚠ Some OpenCL tools may remain${NC}"
fi

if ! dpkg -l | grep -q "intel.*gpu\|level-zero\|vulkan"; then
    echo -e "${GREEN}✓ Intel GPU packages removed${NC}"
else
    echo -e "${YELLOW}⚠ Some GPU packages may remain${NC}"
fi

# Check for remaining repositories
if [ ! -f "/etc/apt/sources.list.d/intel-graphics.list" ] && [ ! -f "/etc/apt/sources.list.d/lunarg-vulkan-noble.list" ]; then
    echo -e "${GREEN}✓ Repositories removed${NC}"
else
    echo -e "${YELLOW}⚠ Some repositories may remain${NC}"
fi

echo ""
echo -e "${GREEN}Uninstallation completed!${NC}"
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}1. Reboot your system to complete cleanup${NC}"
echo -e "${YELLOW}2. Verify GPU functionality with default drivers${NC}"
echo ""
echo -e "${BLUE}To reinstall Intel GPU support:${NC}"
echo -e "${GREEN}  ./install_driver.sh${NC}"
echo ""

exit 0
