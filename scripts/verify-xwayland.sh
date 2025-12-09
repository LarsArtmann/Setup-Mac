#!/usr/bin/env bash

# Enhanced verification script including Xwayland and wallpaper management

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

echo -e "\n${YELLOW}1. Checking Xwayland Configuration${NC}"
# Check if Xwayland is enabled at system level
if sudo nix eval --raw .#nixosConfigurations.evo-x2.config.programs.hyprland.xwayland.enable 2>/dev/null | grep -q "true"; then
    check_status 0 "Xwayland enabled at system level (programs.hyprland)"
else
    warning "Xwayland may not be enabled at system level"
fi

# Check if Xwayland processes are running when Hyprland is active
if pgrep -f "Xwayland" > /dev/null 2>&1; then
    check_status 0 "Xwayland process is running"
    info "Xwayland enables X11 application compatibility"
else
    warning "Xwayland process not found (may not be running without X11 apps)"
fi

# Check for Wayland session
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    check_status 0 "Running in Wayland session"
else
    warning "Not running in Wayland session (current: ${XDG_SESSION_TYPE:-unknown})"
fi

echo -e "\n${YELLOW}2. Checking Wallpaper Management${NC}"
# Check if hyprpaper is installed
if command -v hyprpaper &> /dev/null; then
    check_status 0 "hyprpaper is installed (official wallpaper tool)"
    HYPRLAND_PID=$(pgrep -f "Hyprland" 2>/dev/null)
    if [ -n "$HYPRLAND_PID" ]; then
        if pgrep -f "hyprpaper" > /dev/null 2>&1; then
            check_status 0 "hyprpaper is running"
        else
            info "hyprpaper not running (will start with Hyprland)"
        fi
    fi
else
    warning "hyprpaper not installed"
fi

# Check if swww is installed (alternative wallpaper tool)
if command -v swww &> /dev/null; then
    info "swww is installed (alternative wallpaper tool)"
    if pgrep -f "swww" > /dev/null 2>&1; then
        check_status 0 "swww is running"
    fi
else
    info "swww not installed (hyprpaper is recommended)"
fi

echo -e "\n${YELLOW}3. AMD GPU Driver${NC}"
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

echo -e "\n${YELLOW}4. Application Compatibility${NC}"
# Test Wayland/X11 application detection
if command -v gdk-pixbuf-query-loaders &> /dev/null; then
    info "GTK libraries available for Wayland support"
fi

# Check for common applications and their backend
if command -v firefox &> /dev/null; then
    info "Firefox available (supports both Wayland and Xwayland)"
fi

if command -v steam &> /dev/null; then
    info "Steam available (games may use Xwayland)"
fi

echo -e "\n${YELLOW}5. Xwayland Testing${NC}"
read -p "Would you like to test Xwayland with an X11 application? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Testing Xwayland compatibility..."
    if command -v xeyes &> /dev/null; then
        info "Running xeyes (classic X11 test app)..."
        xeyes &
        XEYES_PID=$!
        sleep 2
        if kill -0 $XEYES_PID 2>/dev/null; then
            check_status 0 "X11 application (xeyes) runs successfully via Xwayland"
            kill $XEYES_PID
        else
            warning "xeyes failed to run"
        fi
    else
        info "xeyes not available. Install with: nix-shell -p xorg.xeyes"
    fi
fi

echo -e "\n${YELLOW}6. Performance Tips${NC}"
info "For optimal performance:"
info "- Use native Wayland applications when possible"
info "- Xwayland applications will work but may have slightly higher overhead"
info "- hyprpaper has lower resource usage than swww"
info "- Monitor GPU usage with: amdgpu_top"

echo -e "\n${GREEN}Xwayland and Wallpaper verification complete!${NC}"
echo "==================================================="