#!/bin/bash

# ActivityWatch Nix Auto-Start Setup Script
# This script creates the necessary configuration for ActivityWatch auto-start

set -euo pipefail

LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/net.activitywatch.ActivityWatch.plist"
ACTIVITYWATCH_APP="/Applications/ActivityWatch.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

error() {
    echo -e "${RED}❌ $*${NC}"
}

# Create launch agent
create_launch_agent() {
    log "Creating ActivityWatch launch agent..."

    mkdir -p "$LAUNCH_AGENT_DIR"

    cat > "$LAUNCH_AGENT_PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>net.activitywatch.ActivityWatch</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/ActivityWatch.app/Contents/MacOS/ActivityWatch</string>
        <string>--background</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>
    <key>ProcessType</key>
    <string>Background</string>
    <key>StandardOutPath</key>
    <string>/tmp/net.activitywatch.ActivityWatch.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/net.activitywatch.ActivityWatch.stderr.log</string>
    <key>WorkingDirectory</key>
    <string>/Users/larsartmann</string>
</dict>
</plist>
EOF

    success "Launch agent created at $LAUNCH_AGENT_PLIST"
}

# Add to login items
add_to_login_items() {
    log "Adding ActivityWatch to login items..."

    if osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q "ActivityWatch"; then
        warning "ActivityWatch already in login items"
    else
        osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/ActivityWatch.app", hidden:false}' 2>/dev/null || warning "Could not add to login items (may require permissions)"
        success "ActivityWatch added to login items"
    fi
}

# Load launch agent
load_launch_agent() {
    log "Loading ActivityWatch launch agent..."

    if launchctl list | grep -q "net.activitywatch.ActivityWatch"; then
        log "Unloading existing launch agent..."
        launchctl unload -w "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
    fi

    launchctl load -w "$LAUNCH_AGENT_PLIST" 2>/dev/null || error "Failed to load launch agent"
    success "Launch agent loaded"
}

# Verify setup
verify_setup() {
    log "Verifying ActivityWatch setup..."

    # Check launch agent
    if launchctl list | grep -q "net.activitywatch.ActivityWatch"; then
        success "Launch agent loaded and active"
    else
        warning "Launch agent not found (may need system restart)"
    fi

    # Check login items
    if osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q "ActivityWatch"; then
        success "ActivityWatch in login items"
    else
        warning "ActivityWatch not in login items"
    fi

    # Check process
    if pgrep -f ActivityWatch > /dev/null; then
        success "ActivityWatch process running"
    else
        warning "ActivityWatch process not found (may start on next login)"
    fi

    # Check web interface
    if lsof -i :5600 >/dev/null 2>&1; then
        success "ActivityWatch web interface accessible on port 5600"
    else
        warning "ActivityWatch web interface not accessible (may take time to start)"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 ActivityWatch Nix Auto-Start Setup${NC}"
    echo "========================================"

    # Check ActivityWatch installation
    if [[ ! -d "$ACTIVITYWATCH_APP" ]]; then
        error "ActivityWatch not found at $ACTIVITYWATCH_APP"
        echo "Please install ActivityWatch first: brew install --cask activitywatch"
        exit 1
    fi

    success "ActivityWatch installation found"

    # Setup components
    create_launch_agent
    add_to_login_items
    load_launch_agent
    verify_setup

    echo ""
    echo -e "${GREEN}🎉 ActivityWatch auto-start setup complete!${NC}"
    echo ""
    echo "Configuration details:"
    echo "  • Launch agent: $LAUNCH_AGENT_PLIST"
    echo "  • Login items: Configured"
    echo "  • Web interface: http://localhost:5600"
    echo "  • Logs: /tmp/net.activitywatch.ActivityWatch.*.log"
    echo ""
    echo "ActivityWatch will now automatically start on every login."
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "ActivityWatch Nix Auto-Start Setup"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (none)     Run complete setup"
        echo "  --help     Show this help"
        echo "  --check    Check current status"
        echo "  --cleanup  Remove configuration"
        ;;
    --check)
        verify_setup
        ;;
    --cleanup)
        log "Cleaning up ActivityWatch configuration..."
        launchctl unload -w "$LAUNCH_AGENT_PLIST" 2>/dev/null || true
        rm -f "$LAUNCH_AGENT_PLIST"
        success "Configuration cleaned up"
        ;;
    *)
        main
        ;;
esac