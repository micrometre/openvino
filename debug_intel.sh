#!/bin/bash
####################################
#
# Intel Iris Xe GPU Debug Script
# For Ubuntu 24.04 on Dell Latitude 7340
#
####################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Intel Iris Xe GPU Debug Script${NC}"
echo -e "${BLUE}Ubuntu 24.04 - Dell Latitude 7340${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. System Information
echo -e "${YELLOW}[1] System Information${NC}"
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d | cut -d':' -f2 | sed 's/^ *//')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""

# 2. GPU Detection
echo -e "${YELLOW}[2] GPU Hardware Detection${NC}"
lspci | grep -i "vga\|3d\|display"
echo ""

# 3. Check Intel Graphics Driver
echo -e "${YELLOW}[3] Intel Graphics Driver Status${NC}"
if lsmod | grep -q i915; then
    echo -e "${GREEN}✓ Intel i915 driver loaded${NC}"
    echo "Driver details:"
    modinfo i915 | grep -E "version|description"
else
    echo -e "${RED}✗ Intel i915 driver not loaded${NC}"
fi
echo ""

# 4. OpenCL Support Check
echo -e "${YELLOW}[4] OpenCL Support${NC}"
if command_exists clinfo; then
    echo "OpenCL platforms and devices:"
    clinfo -l
    echo ""
    echo "Intel GPU OpenCL details:"
    clinfo | grep -A 5 -B 5 "Intel"
else
    echo -e "${RED}✗ clinfo not installed${NC}"
    echo "Install with: sudo apt install clinfo"
fi
echo ""

# 5. Level Zero Support
echo -e "${YELLOW}[5] Intel Level Zero Support${NC}"
if [ -d "/usr/lib/x86_64-linux-gnu" ]; then
    if ls /usr/lib/x86_64-linux-gnu/libze_loader.so* >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Level Zero library found${NC}"
        ls -la /usr/lib/x86_64-linux-gnu/libze_loader.so*
    else
        echo -e "${RED}✗ Level Zero library not found${NC}"
    fi
else
    echo -e "${RED}✗ Standard library directory not found${NC}"
fi
echo ""

# 6. Check User Groups
echo -e "${YELLOW}[6] User Group Membership${NC}"
echo "Current user: $USER"
echo "Groups: $(groups $USER)"
if groups $USER | grep -q render; then
    echo -e "${GREEN}✓ User in 'render' group${NC}"
else
    echo -e "${RED}✗ User not in 'render' group${NC}"
    echo "Add with: sudo usermod -a -G render $USER"
fi

if groups $USER | grep -q video; then
    echo -e "${GREEN}✓ User in 'video' group${NC}"
else
    echo -e "${RED}✗ User not in 'video' group${NC}"
    echo "Add with: sudo usermod -a -G video $USER"
fi
echo ""

# 7. Device Permissions
echo -e "${YELLOW}[7] GPU Device Permissions${NC}"
if [ -d "/dev/dri" ]; then
    echo "DRI devices:"
    ls -la /dev/dri/
    if ls /dev/dri/render* >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Render nodes found${NC}"
    else
        echo -e "${RED}✗ No render nodes found${NC}"
    fi
else
    echo -e "${RED}✗ /dev/dri directory not found${NC}"
fi
echo ""


# 9. GPU Memory Information
echo -e "${YELLOW}[9] GPU Memory Information${NC}"
if [ -f "/sys/class/drm/card0/device/local_memory/total" ]; then
    echo "GPU memory: $(cat /sys/class/drm/card0/device/local_memory/total)"
else
    echo "GPU memory info not available at standard location"
fi

# Check system memory
echo "System RAM: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo ""

# 10. Recommended Actions
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Recommended Actions for Intel Iris Xe${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

echo -e "${YELLOW}1. Install Intel GPU Runtime (if not already installed):${NC}"
echo "   sudo apt update"
echo "   sudo apt install intel-opencl-icd ocl-icd-opencl-dev clinfo"
echo "   sudo apt install intel-level-zero-gpu level-zero level-zero-dev"
echo ""

echo -e "${YELLOW}2. Add user to required groups:${NC}"
echo "   sudo usermod -a -G render,video $USER"
echo "   # Log out and back in after adding groups"
echo ""


echo -e "${GREEN}For Dell Latitude 7340 specific notes:${NC}"
echo "- Iris Xe graphics should work with Level Zero backend"
echo "- Make sure you're running on AC power for better performance"
echo "- Some models may need BIOS settings for GPU memory allocation"
echo ""

exit 0