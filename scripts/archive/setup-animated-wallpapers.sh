#!/usr/bin/env bash
# =============================================================================
# DEPRECATED - This script has been superseded by Nix-native implementation
# =============================================================================
#
# This script is OBSOLETE and has been replaced by:
#   platforms/nixos/modules/hyprland-animated-wallpaper.nix
#
# Migration Date: 2026-01-13
# Reason: Nix-native module provides declarative wallpaper management
#
# New Implementation:
#   - Fully declarative via Home Manager
#   - Integrates with Hyprland via exec-once and keybindings
#   - Provides scripts: swww-anim-wallpaper, swww-next, swww-prev
#   - Managed by Nix (no manual setup needed)
#
# To use new implementation:
#   1. Enable in platforms/nixos/users/home.nix:
#      programs.hyprland-animated-wallpaper.enable = true;
#   2. Run: sudo nixos-rebuild switch
#   3. Wallpapers auto-start and cycle automatically
#
# DO NOT USE THIS SCRIPT - Use Nix module instead
# =============================================================================
#
# Animated wallpapers setup script (OBSOLETE - see above)
# This script sets up the wallpaper management system with swww

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should be run as a regular user, not as root."
    exit 1
fi

# Check if we're in a Wayland session
if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
    print_warning "This script is designed for Wayland sessions (Hyprland)."
    print_warning "Current session type: $XDG_SESSION_TYPE"
fi

# Setup wallpaper directories
setup_directories() {
    print_info "Creating wallpaper directories..."

    local wallpaper_dir="$HOME/.config/wallpapers"
    local static_dir="$wallpaper_dir/static"
    local animated_dir="$wallpaper_dir/animated"
    local gifs_dir="$wallpaper_dir/gifs"

    # Create directories
    mkdir -p "$static_dir" "$animated_dir" "$gifs_dir"

    # Create gitkeep files to ensure directories are tracked
    touch "$static_dir/.gitkeep" "$animated_dir/.gitkeep" "$gifs_dir/.gitkeep"

    print_info "Wallpaper directories created at $wallpaper_dir"
}

# Generate sample wallpapers
generate_wallpapers() {
    print_info "Generating sample wallpapers..."

    local wallpaper_dir="$HOME/.config/wallpapers"

    # Generate default static wallpaper if it doesn't exist
    if [[ ! -f "$wallpaper_dir/static/default-nix.png" ]]; then
        if command -v magick &> /dev/null; then
            print_info "Creating default static wallpaper..."
            magick -size 1920x1080 gradient:"#1a1a2e-#16213e" "$wallpaper_dir/static/default-nix.png"
        else
            print_warning "ImageMagick not found. Skipping default wallpaper generation."
        fi
    fi

    # Generate sample animated wallpapers
    if command -v magick &> /dev/null; then
        for i in {1..3}; do
            local color
            case $i in
                1) color="hsl(0),100%,50%" ;;  # Red
                2) color="hsl(120),100%,50%" ;; # Green
                3) color="hsl(240),100%,50%" ;; # Blue
            esac

            local file="$wallpaper_dir/animated/sample-$i.png"
            if [[ ! -f "$file" ]]; then
                print_info "Creating animated wallpaper sample $i..."
                magick -size 1920x1080 gradient:"$color" "$file"
            fi
        done
    fi

    print_info "Sample wallpapers generated."
}

# Create wallpaper switcher script
create_wallpaper_script() {
    print_info "Installing wallpaper switcher script..."

    local script_dir="$HOME/.config/scripts"
    local script_file="$script_dir/wallpaper-switcher"

    # Create scripts directory
    mkdir -p "$script_dir"

    # Create the wallpaper switcher script
    cat > "$script_file" << 'EOF'
#!/usr/bin/env bash
# Automated wallpaper management script

WALLPAPER_DIR="$HOME/.config/wallpapers"
STATIC_DIR="$WALLPAPER_DIR/static"
ANIMATED_DIR="$WALLPAPER_DIR/animated"

# Start swww if not running
if ! pgrep -x "swww" > /dev/null; then
    swww init
    sleep 1
fi

case "$1" in
    --animate)
        echo "Enabling animated wallpaper mode"
        if [ -d "$ANIMATED_DIR" ] && [ "$(ls -A $ANIMATED_DIR)" ]; then
            find "$ANIMATED_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -1 | xargs swww img \
              --transition-type any --transition-fps 60 --transition-duration 1.5
        else
            echo "No animated wallpapers found in $ANIMATED_DIR"
        fi
        ;;
    --clear)
        swww clear
        ;;
    --cycle)
        CYCLE_DELAY="${2:-300}"  # Default 5 minutes
        while true; do
            if [ -d "$STATIC_DIR" ] && [ "$(ls -A $STATIC_DIR)" ]; then
                find "$STATIC_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | shuf -n 1 | xargs swww img \
                    --transition-type any --transition-fps 60 --transition-duration 1.5
            fi
            sleep "$CYCLE_DELAY"
        done
        ;;
    "")
        # Default: random static wallpaper
        if [ -d "$STATIC_DIR" ] && [ "$(ls -A $STATIC_DIR)" ]; then
            find "$STATIC_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | shuf -n 1 | xargs swww img \
                --transition-type any --transition-fps 60 --transition-duration 1.5
        else
            echo "No wallpapers found in $STATIC_DIR"
        fi
        ;;
    *)
        if [ -f "$1" ]; then
            swww img "$1" --transition-type any --transition-fps 60 --transition-duration 1.5
        elif [ -d "$1" ]; then
            find "$1" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | shuf -n 1 | xargs swww img \
                --transition-type any --transition-fps 60 --transition-duration 1.5
        else
            echo "Usage: $0 [image|directory] [--animate|--clear|--cycle]"
            exit 1
        fi
        ;;
esac
EOF

    # Make script executable
    chmod +x "$script_file"

    print_info "Wallpaper switcher script installed at $script_file"
}

# Setup swww
setup_swww() {
    print_info "Setting up swww..."

    # Check if swww is available
    if ! command -v swww &> /dev/null; then
        print_error "swww not found. Make sure it's installed via NixOS configuration."
        return 1
    fi

    # Initialize swww if not already running
    if ! pgrep -x "swww" > /dev/null; then
        print_info "Starting swww daemon..."
        swww init
        sleep 1
    fi

    print_info "swww is running. Check with 'swww query' for current status."
}

# Verify Hyprland configuration
verify_config() {
    print_info "Checking Hyprland configuration..."

    local config_file="$HOME/.config/hypr/hyprland.conf"

    if [[ -f "$config_file" ]]; then
        # Check if wallpaper script is in exec-once
        if grep -q "wallpaper-switcher" "$config_file"; then
            print_info "Wallpaper switcher script found in Hyprland configuration."
        else
            print_warning "Consider adding wallpaper-switcher to exec-once in Hyprland config."
        fi

        # Check for keybindings
        if grep -q "W, exec.*wallpaper-switcher" "$config_file"; then
            print_info "Wallpaper keybindings found in Hyprland configuration."
        else
            print_warning "Consider adding wallpaper keybindings to Hyprland config."
        fi
    else
        print_warning "Hyprland configuration not found at $config_file"
    fi
}

# Main execution
main() {
    print_info "Setting up animated wallpapers with swww..."

    setup_directories
    generate_wallpapers
    create_wallpaper_script
    setup_swww
    verify_config

    print_info "Animated wallpapers setup complete!"
    print_info ""
    print_info "Usage:"
    print_info "  ~/.config/scripts/wallpaper-switcher          # Random wallpaper"
    print_info "  ~/.config/scripts/wallpaper-switcher --animate  # Animated wallpaper"
    print_info "  ~/.config/scripts/wallpaper-switcher --clear    # Clear wallpaper"
    print_info ""
    print_info "For more information, see ANIMATED-WALLPAPERS-GUIDE.md"
}

# Run main function
main "$@"