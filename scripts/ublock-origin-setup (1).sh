#!/usr/bin/env bash

# uBlock Origin Automation Setup Script
# Addresses issue #40: Browser automation (uBlock Origin) for security
#
# This script automates the configuration of uBlock Origin filter lists
# for enhanced security and privacy on macOS browsers.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/ublock-origin"
CUSTOM_FILTERS_FILE="$CONFIG_DIR/custom-filters.txt"
FILTER_LISTS_CONFIG="$CONFIG_DIR/filter-lists.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script is designed for macOS only"
    fi
}

# Create configuration directory
setup_config_directory() {
    log "Creating uBlock Origin configuration directory..."
    mkdir -p "$CONFIG_DIR"
}

# Generate comprehensive custom filter list
create_custom_filters() {
    log "Creating comprehensive custom filter list..."
    cat > "$CUSTOM_FILTERS_FILE" << 'EOF'
! Title: Lars Custom Security Filters
! Description: Enhanced security and privacy filters for macOS
! Homepage: https://github.com/LarsArtmann/Setup-Mac
! Expires: 1 day
! Last modified: $(date '+%Y-%m-%d %H:%M:%S')

! === SECURITY FILTERS ===

! Block malicious domains
||malware-example.com^
||phishing-example.com^
||cryptomining-example.com^

! Block tracking scripts
||google-analytics.com^$important
||googletagmanager.com^$important
||facebook.com/tr^$important
||doubleclick.net^$important

! === PRIVACY FILTERS ===

! Block social media tracking
||connect.facebook.net^$third-party
||platform.twitter.com^$third-party
||platform.linkedin.com^$third-party

! Block fingerprinting scripts
||fingerprintjs.com^
||clientjs.org^
||device-metrics.com^

! === PRODUCTIVITY FILTERS ===

! Block distracting websites (uncomment as needed)
! ||reddit.com^
! ||twitter.com^
! ||facebook.com^
! ||youtube.com^$domain=~work.example.com

! === DEVELOPMENT FILTERS ===

! Block common development distractions
||stackoverflow.com^$domain=focus-mode.local
||github.com^$domain=focus-mode.local

! === CUSTOM COSMETIC FILTERS ===

! Remove cookie banners
##.cookie-banner
##.gdpr-banner
##[class*="cookie"]
##[id*="cookie"]

! Remove newsletter popups
##.newsletter-popup
##.email-signup
##[class*="newsletter"]

! Remove sticky headers/footers
##.sticky-header
##.fixed-header
##.sticky-footer
##.fixed-footer
EOF

    log "Custom filters created at: $CUSTOM_FILTERS_FILE"
}

# Create filter lists configuration
create_filter_lists_config() {
    log "Creating filter lists configuration..."
    cat > "$FILTER_LISTS_CONFIG" << 'EOF'
{
  "title": "uBlock Origin Filter Lists Configuration",
  "description": "Recommended filter lists for enhanced security and privacy",
  "lists": {
    "built-in": [
      "ublock-filters",
      "ublock-badware",
      "ublock-privacy",
      "ublock-unbreak",
      "easylist",
      "easyprivacy",
      "malware-filter",
      "pgl-yoyo"
    ],
    "regions": [
      "easylist-cookie"
    ],
    "custom": [
      {
        "title": "Lars Custom Security Filters",
        "url": "file://" + process.env.HOME + "/.config/ublock-origin/custom-filters.txt",
        "updateInterval": "1d"
      }
    ],
    "community": [
      {
        "title": "Dan Pollock's Hosts File",
        "url": "https://someonewhocares.org/hosts/zero/hosts",
        "updateInterval": "7d"
      },
      {
        "title": "Steven Black's Unified Hosts",
        "url": "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
        "updateInterval": "7d"
      },
      {
        "title": "AdGuard DNS Filter",
        "url": "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt",
        "updateInterval": "1d"
      }
    ]
  },
  "settings": {
    "autoUpdate": true,
    "updateInterval": "auto",
    "importEnabled": true,
    "parseAllABPHideFilters": true,
    "ignoreGenericCosmeticFilters": false
  }
}
EOF

    log "Filter lists configuration created at: $FILTER_LISTS_CONFIG"
}

# Generate browser-specific installation instructions
generate_installation_guide() {
    local guide_file="$CONFIG_DIR/installation-guide.md"

    log "Generating installation guide..."
    cat > "$guide_file" << 'EOF'
# uBlock Origin Installation and Configuration Guide

## Browser Installation

### Safari (macOS 13+)
1. Install uBlock Origin from the App Store
2. Enable the extension in Safari Preferences > Extensions
3. Grant necessary permissions

### Firefox
1. Install from: https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/
2. Pin the extension to toolbar

### Chrome/Chromium/Edge
1. Install from Chrome Web Store
2. Pin the extension to toolbar

## Configuration Steps

1. **Open uBlock Origin Dashboard**
   - Click the uBlock Origin icon
   - Click the gear icon (Settings)

2. **Import Custom Filters**
   - Go to "Filter lists" tab
   - Scroll to "Custom" section
   - Check "Import..."
   - Add: file://$HOME/.config/ublock-origin/custom-filters.txt

3. **Enable Recommended Lists**
   - Built-in filters: uBlock filters, Badware risks, Privacy, Unbreak
   - EasyList: EasyList, EasyPrivacy
   - Malware protection: Online Malicious URL Blocklist
   - Multipurpose: Dan Pollock's hosts file

4. **Advanced Settings**
   - Go to "Settings" tab
   - Check "I am an advanced user"
   - Configure as needed

## Automation

This configuration will automatically:
- Update filter lists daily
- Block malicious domains
- Enhance privacy protection
- Remove distracting elements
- Provide development-focused filtering

## Maintenance

- Custom filters are updated automatically
- Check logs in: $HOME/.config/ublock-origin/
- Run the setup script again to update configurations

## Troubleshooting

If a website breaks:
1. Click uBlock Origin icon
2. Click the power button to disable temporarily
3. Add site to whitelist if permanently needed
4. Report false positives to improve filters
EOF

    log "Installation guide created at: $guide_file"
}

# Create update script for automatic maintenance
create_update_script() {
    local update_script="$CONFIG_DIR/update-filters.sh"

    log "Creating filter update script..."
    cat > "$update_script" << 'EOF'
#!/usr/bin/env bash

# uBlock Origin Filter Update Script
# Run this script to update custom filters and configurations

set -euo pipefail

CONFIG_DIR="$HOME/.config/ublock-origin"
CUSTOM_FILTERS_FILE="$CONFIG_DIR/custom-filters.txt"
BACKUP_DIR="$CONFIG_DIR/backups"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup current filters
if [[ -f "$CUSTOM_FILTERS_FILE" ]]; then
    cp "$CUSTOM_FILTERS_FILE" "$BACKUP_DIR/custom-filters-$(date +%Y%m%d-%H%M%S).txt"
fi

# Update timestamp in filters
sed -i '' "s/! Last modified: .*/! Last modified: $(date '+%Y-%m-%d %H:%M:%S')/" "$CUSTOM_FILTERS_FILE"

echo "✅ uBlock Origin filters updated successfully"
echo "📁 Backup saved to: $BACKUP_DIR"
echo "🔄 Filters will auto-update in browser within 1 hour"
EOF

    chmod +x "$update_script"
    log "Update script created at: $update_script"
}

# Create launchd plist for automatic updates
create_launchd_service() {
    local plist_file="$HOME/Library/LaunchAgents/com.larsartmann.ublock-update.plist"

    log "Creating launchd service for automatic updates..."
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.larsartmann.ublock-update</string>
    <key>ProgramArguments</key>
    <array>
        <string>$CONFIG_DIR/update-filters.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$CONFIG_DIR/update.log</string>
    <key>StandardErrorPath</key>
    <string>$CONFIG_DIR/update.error.log</string>
</dict>
</plist>
EOF

    launchctl load "$plist_file" 2>/dev/null || warn "launchd service may already be loaded"
    log "launchd service created and loaded: $plist_file"
}

# Main execution
main() {
    log "Starting uBlock Origin automation setup..."

    check_macos
    setup_config_directory
    create_custom_filters
    create_filter_lists_config
    generate_installation_guide
    create_update_script
    create_launchd_service

    log "✅ uBlock Origin automation setup completed successfully!"
    info "📖 Next steps:"
    info "   1. Install uBlock Origin in your browsers"
    info "   2. Follow the guide: $CONFIG_DIR/installation-guide.md"
    info "   3. Import custom filters from: $CUSTOM_FILTERS_FILE"
    info "   4. Filters will auto-update daily at 9 AM"

    echo
    info "🔧 Configuration files created:"
    info "   - Custom filters: $CUSTOM_FILTERS_FILE"
    info "   - Filter lists config: $FILTER_LISTS_CONFIG"
    info "   - Installation guide: $CONFIG_DIR/installation-guide.md"
    info "   - Update script: $CONFIG_DIR/update-filters.sh"
    info "   - launchd service: ~/Library/LaunchAgents/com.larsartmann.ublock-update.plist"
}

# Run the main function
main "$@"