#!/usr/bin/env bash

# Hyprland + AMD GPU Optimization Verification Script
# This script checks that all optimizations are properly configured

echo "🔍 Checking Hyprland + AMD GPU Configuration..."
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} $2"
    else
        echo -e "  ${RED}✗${NC} $2"
        return 1
    fi
}

warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

info() {
    echo -e "  ℹ️  $1"
}

# Check if running on NixOS
if [ ! -f /etc/nixos/configuration.nix ]; then
    echo -e "${RED}Error: This script must be run on NixOS${NC}"
    exit 1
fi

echo -e "\n${YELLOW}1. Checking AMD GPU Driver${NC}"
# Check if amdgpu driver is loaded
if lsmod | grep -q "amdgpu"; then
    check_status 0 "AMD GPU driver (amdgpu) is loaded"
else
    check_status 1 "AMD GPU driver (amdgpu) is not loaded"
fi

# Check GPU device
if [ -d /sys/class/drm/card0/device ]; then
    GPU_MODEL=$(cat /sys/class/drm/card0/device/model 2>/dev/null || echo "Unknown")
    check_status 0 "GPU detected: $GPU_MODEL"
else
    warning "GPU device not found in /sys/class/drm/card0/device"
fi

echo -e "\n${YELLOW}2. Checking OpenGL/Vulkan Support${NC}"
# Check OpenGL support
if glxinfo | grep -q "OpenGL renderer"; then
    GL_RENDERER=$(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs)
    check_status 0 "OpenGL renderer: $GL_RENDERER"
else
    check_status 1 "OpenGL support not detected"
fi

# Check Vulkan support
if vulkaninfo --summary 2>/dev/null | grep -q "driverName"; then
    VULKAN_DRIVER=$(vulkaninfo --summary 2>/dev/null | grep "driverName" | head -1 | awk '{print $3}')
    check_status 0 "Vulkan driver: $VULKAN_DRIVER"
else
    warning "Vulkan support may not be properly configured"
fi

echo -e "\n${YELLOW}3. Checking Kernel Parameters${NC}"
# Check if AMD optimization parameters are loaded
for param in "amdgpu.ppfeaturemask=0xfffd7fff" "amdgpu.deepfl=1" "amd_pstate=guided"; do
    if grep -q "$param" /proc/cmdline; then
        check_status 0 "Kernel parameter found: $param"
    else
        warning "Kernel parameter missing: $param"
    fi
done

echo -e "\n${YELLOW}4. Checking Environment Variables${NC}"
# Check important environment variables
for var in "LIBVA_DRIVER_NAME=radeonsi" "AMD_VULKAN_ICD=RADV" "MESA_VK_WSI_PRESENT_MODE=fifo"; do
    var_name=$(echo $var | cut -d= -f1)
    var_value=$(echo $var | cut -d= -f2)

    if [ "${!var_name}" = "$var_value" ]; then
        check_status 0 "Environment variable set: $var"
    else
        warning "Environment variable not set: $var (current: ${!var_name:-unset})"
    fi
done

echo -e "\n${YELLOW}5. Checking Hyprland Configuration${NC}"
# Check if Hyprland is installed
if command -v Hyprland &> /dev/null; then
    check_status 0 "Hyprland package is installed"

    # Check Hyprland version
    HYPRLAND_VERSION=$(Hyprland -v 2>/dev/null | head -1)
    info "Hyprland version: $HYPRLAND_VERSION"
else
    check_status 1 "Hyprland package not found"
fi

# Check if Cachix binary cache is configured
if grep -q "hyprland.cachix.org" /etc/nix/nix.conf 2>/dev/null; then
    check_status 0 "Hyprland Cachix binary cache configured"
else
    warning "Hyprland Cachix binary cache not configured - builds will be slow"
fi

# Check if Home Manager configuration includes Hyprland
if [ -d ~/.config/hypr ]; then
    check_status 0 "Hyprland user configuration found in ~/.config/hypr"
else
    warning "Hyprland user configuration not found in ~/.config/hypr"
fi

# Check for UWSM configuration
if systemctl --user is-active uwsm@wayland.service &>/dev/null; then
    check_status 0 "UWSM service is active (recommended)"
else
    info "UWSM service not active - checking at system boot"
fi

echo -e "\n${YELLOW}6. Checking Monitoring Tools${NC}"
# Check if monitoring tools are available
tools=("amdgpu_top" "nvtop" "corectrl" "vulkaninfo" "glxinfo")
for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        check_status 0 "Monitoring tool available: $tool"
    else
        warning "Monitoring tool not found: $tool"
    fi
done

echo -e "\n${YELLOW}7. Performance Recommendations${NC}"
# Provide performance tips
info "To monitor GPU performance in real-time, run: amdgpu_top"
info "To control AMD CPU settings, run: corectrl"
info "To check OpenGL info, run: glxinfo"
info "To check Vulkan info, run: vulkaninfo"

# Check if user is in required groups
if groups | grep -q "video"; then
    check_status 0 "User is in 'video' group"
else
    warning "Add user to 'video' group: sudo usermod -aG video \$USER"
fi

if groups | grep -q "input"; then
    check_status 0 "User is in 'input' group"
else
    warning "Add user to 'input' group: sudo usermod -aG input \$USER"
fi

echo -e "\n${YELLOW}8. Testing GPU Performance${NC}"
# Offer to run GPU benchmarks
read -p "Would you like to run GPU benchmark tests? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running glmark2 (OpenGL benchmark)..."
    if command -v glmark2 &> /dev/null; then
        glmark2 --validate
    else
        warning "glmark2 not available. Install with: nix-shell -p mesa-demos"
    fi

    echo "Running vkcube (Vulkan test)..."
    if command -v vkcube &> /dev/null; then
        vkcube &
        VKCUBE_PID=$!
        sleep 3
        if kill -0 $VKCUBE_PID 2>/dev/null; then
            check_status 0 "vkcube (Vulkan) is running successfully"
            kill $VKCUBE_PID
        else
            check_status 1 "vkcube (Vulkan) failed to run"
        fi
    else
        warning "vkcube not available. Install with: nix-shell -p vulkan-tools"
    fi
fi

echo -e "\n${GREEN}Hyprland + AMD GPU verification complete!${NC}"
echo "=================================================="
echo "If any items show warnings, consider addressing them for optimal performance."