#!/bin/bash
####################################
#
# Intel Iris Xe GPU Installation Script
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

echo -e "${GREEN}Intel Iris Xe GPU support${NC}"
echo -e "${BLUE}Dell Latitude 7340 - Ubuntu 24.04${NC}"
echo ""

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Install Intel GPU runtime packages for Ubuntu 24.04
echo -e "${YELLOW}Installing Intel GPU runtime...${NC}"

# Core OpenCL packages
sudo apt install -y intel-opencl-icd ocl-icd-opencl-dev clinfo

# Try to install Intel compute runtime packages
echo -e "${YELLOW}Installing Intel Level Zero runtime...${NC}"

# For Ubuntu 24.04, try the package from repos first
if apt-cache search intel-level-zero | grep -q level-zero; then
    sudo apt install -y intel-level-zero-gpu level-zero level-zero-dev
    echo -e "${GREEN}✓ Installed Level Zero from repository${NC}"
else
    echo -e "${YELLOW}Adding Intel's compute runtime repository...${NC}"
    
    # Add Intel's repository for newer packages
    wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | sudo gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg
    echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu noble client" | sudo tee /etc/apt/sources.list.d/intel-graphics.list
    
    sudo apt update
    
    # Install from Intel's repository
    sudo apt install -y intel-level-zero-gpu level-zero level-zero-dev intel-opencl-icd || {
        echo -e "${RED}Warning: Could not install all Intel packages${NC}"
        echo -e "${YELLOW}Continuing with basic OpenCL support${NC}"
    }
fi




# Install GPU monitoring tools
echo -e "${YELLOW}Installing GPU monitoring tools...${NC}"
sudo apt install -y intel-gpu-tools


# Install Vulkan support for better performance
echo -e "${YELLOW}Installing Vulkan support...${NC}"

# Check if Vulkan is already installed
if command -v vulkaninfo &> /dev/null; then
    echo -e "${GREEN}✓ Vulkan already installed${NC}"
else
    # Add Lunarg Vulkan repository
    echo -e "${YELLOW}Adding Lunarg Vulkan repository...${NC}"
    wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo gpg --dearmor --output /usr/share/keyrings/lunarg-graphics.gpg || {
        echo -e "${RED}Warning: Failed to add Lunarg signing key${NC}"
    }
    
    # Add repository source for Ubuntu 24.04 (noble)
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/lunarg-graphics.gpg] https://packages.lunarg.com/vulkan noble main" | \
        sudo tee /etc/apt/sources.list.d/lunarg-vulkan-noble.list > /dev/null || {
        echo -e "${RED}Warning: Failed to add Vulkan repository${NC}"
    }
    
    # Update package list
    sudo apt update -qq
    
    # Install Vulkan SDK
    if sudo apt install -y vulkan-sdk > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Vulkan SDK installed successfully${NC}"
        
        # Verify installation
        if vulkaninfo &> /dev/null | grep -q "apiVersion"; then
            echo -e "${GREEN}✓ Vulkan verified and working${NC}"
        else
            echo -e "${YELLOW}Warning: Vulkan installed but verification inconclusive${NC}"
        fi
    else
        echo -e "${RED}Warning: Failed to install Vulkan SDK${NC}"
        echo -e "${YELLOW}Continuing without Vulkan (system can still use other GPU acceleration)${NC}"
    fi
fi

# Add user to required groups
echo -e "${YELLOW}Adding user to render and video groups...${NC}"
sudo usermod -a -G render $USER
sudo usermod -a -G video $USER

echo -e "${YELLOW}Verifying OpenCL installation...${NC}"
clinfo | grep -i "intel\|device" || echo -e "${RED}Warning: Intel GPU not detected in OpenCL${NC}"

echo ""

echo ""
echo -e "${GREEN}Installation completed!${NC}"
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}1. Log out and back in (to apply group changes)${NC}"
echo ""
echo -e "${GREEN}For Intel Iris Xe optimization:${NC}"
echo "- Use smaller models (3B-7B parameters work best)"
echo "- Ensure laptop is plugged in for better performance"
echo "- Monitor temperature with: sensors"
echo ""

exit 0
