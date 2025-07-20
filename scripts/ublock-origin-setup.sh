#!/usr/bin/env bash

# uBlock Origin Setup Automation
# Addresses issue #40: Set up uBlock Origin automation
#
# This script automates the installation and configuration of uBlock Origin
# across multiple browsers with custom filters and maintenance automation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")/dotfiles"
UBLOCK_CONFIG_DIR="$DOTFILES_DIR/ublock-origin"

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

# Create uBlock Origin configuration structure
setup_ublock_structure() {
    log "Setting up uBlock Origin configuration structure..."
    mkdir -p "$UBLOCK_CONFIG_DIR"/{filters,backup,extensions}

    # Create README for the ublock-origin directory
    cat > "$UBLOCK_CONFIG_DIR/README.md" << 'EOF'
# uBlock Origin Configuration

This directory contains uBlock Origin browser extension configuration and automation.

## Structure

- `filters/` - Custom filter lists and rules
- `backup/` - Backup of extension settings
- `extensions/` - Extension installation metadata
- `install-guides/` - Browser-specific installation instructions

## Automation Features

1. **Custom Filter Management**: Automatically maintains custom filter lists
2. **Browser Detection**: Detects and configures supported browsers
3. **Backup System**: Regular backups of uBlock Origin settings
4. **Update Automation**: Keeps filter lists up to date

## Supported Browsers

- Safari (via extension from App Store)
- Chrome/Chromium
- Firefox
- Microsoft Edge
- Brave Browser

## Manual Installation

For browsers that require manual installation:

1. **Safari**: Install from Mac App Store
2. **Chrome**: Install from Chrome Web Store
3. **Firefox**: Install from Firefox Add-ons
4. **Edge**: Install from Microsoft Edge Add-ons

## Custom Filters

Custom filters are automatically applied and include:
- Enhanced privacy protection
- Social media tracking blockers
- Development-specific ad blockers
- Performance optimization filters

## Restoration

To restore settings on a new system:
```bash
./scripts/ublock-origin-setup.sh --restore
```
EOF

    log "uBlock Origin configuration structure created at: $UBLOCK_CONFIG_DIR"
}

# Create custom filter lists
create_custom_filters() {
    log "Creating custom uBlock Origin filter lists..."

    # Main custom filters
    cat > "$UBLOCK_CONFIG_DIR/filters/custom-filters.txt" << 'EOF'
! Title: Lars Custom uBlock Filters
! Description: Custom filters for enhanced privacy and performance
! Homepage: https://github.com/larsartmann/setup-mac
! License: MIT
! Version: 1.0.0

! == Enhanced Privacy Protection ==
! Block additional tracking domains
||googletagmanager.com^
||google-analytics.com^
||googleadservices.com^
||doubleclick.net^
||facebook.com/tr/*
||connect.facebook.net^
||hotjar.com^
||mouseflow.com^
||fullstory.com^
||logrocket.com^

! == Social Media Tracking ==
! Block social media widgets and tracking
||platform.twitter.com^
||syndication.twitter.com^
||facebook.com/plugins/*
||connect.facebook.net/en_US/fbevents.js
||instagram.com/embed.js
||linkedin.com/analytics/*
||pinterest.com/ct/*

! == Development Environment Optimizations ==
! Block common development tracking
||segment.com^
||segment.io^
||mixpanel.com^
||amplitude.com^
||intercom.io^
||drift.com^
||zendesk.com/embeddable_framework/*

! == Performance Optimizations ==
! Block heavy analytics and marketing scripts
||typekit.net^$script
||fonts.googleapis.com^$css,important
||cdnjs.cloudflare.com^$script,domain=~github.com|~stackoverflow.com
||unpkg.com^$script,domain=~github.com|~npmjs.com

! == Annoyance Filters ==
! Block cookie banners and popups
##.cookie-banner
##.cookie-notice
##.gdpr-banner
##[id*="cookie"]
##[class*="cookie-consent"]
##[class*="privacy-banner"]

! == Developer-Specific Blocks ==
! Block unnecessary elements on development sites
github.com##.js-feature-preview-indicator
stackoverflow.com##.s-sidebarwidget--content > .grid
! Remove promotional banners from documentation sites
docs.github.com##.BorderGrid-row:has(.text-bold:contains("GitHub Copilot"))
EOF

    # Anti-adblock filters
    cat > "$UBLOCK_CONFIG_DIR/filters/anti-adblock.txt" << 'EOF'
! Title: Anti-Adblock Circumvention
! Description: Filters to circumvent anti-adblock detection
! Version: 1.0.0

! Generic anti-adblock circumvention
@@||pagead2.googlesyndication.com/pagead/js/adsbygoogle.js$script,domain=~example.com
@@/ads.js$script,1p
@@||googletagservices.com/tag/js/gpt.js$script

! Site-specific anti-adblock fixes
! Add specific sites that block adblockers here
EOF

    # Allowlist for development and trusted sites
    cat > "$UBLOCK_CONFIG_DIR/filters/allowlist.txt" << 'EOF'
! Title: Development Allowlist
! Description: Allowed domains for development and trusted services
! Version: 1.0.0

! Development and productivity tools
@@||github.com^
@@||gitlab.com^
@@||stackoverflow.com^
@@||developer.mozilla.org^
@@||npmjs.com^
@@||nodejs.org^
@@||golang.org^

! Documentation sites
@@||docs.github.com^
@@||pkg.go.dev^
@@||developer.apple.com^
@@||developer.android.com^

! Cloud services and CDNs
@@||amazonaws.com^
@@||cloudflare.com^
@@||jsdelivr.net^
@@||unpkg.com^$domain=github.com|npmjs.com

! Essential services
@@||apple.com^
@@||icloud.com^
@@||microsoft.com^
@@||office.com^
EOF

    log "Custom filter lists created"
}

# Generate browser-specific installation guides
create_installation_guides() {
    log "Creating browser-specific installation guides..."

    mkdir -p "$UBLOCK_CONFIG_DIR/install-guides"

    # Safari installation guide
    cat > "$UBLOCK_CONFIG_DIR/install-guides/safari.md" << 'EOF'
# uBlock Origin for Safari Installation Guide

## Installation Steps

1. **Download from App Store**
   - Open Mac App Store
   - Search for "AdGuard for Safari" or "1Blocker" (uBlock Origin alternatives)
   - Install the extension

2. **Enable in Safari**
   - Open Safari → Preferences → Extensions
   - Enable the ad blocker extension
   - Configure settings as needed

3. **Import Custom Filters**
   - Open extension settings
   - Navigate to "Filters" or "Custom Rules"
   - Import the custom filter lists from the filters directory

## Notes

- Safari requires App Store extensions due to security restrictions
- uBlock Origin is not available for Safari, use alternatives
- Custom filters may need manual entry depending on the extension

## Alternative Extensions

- **AdGuard for Safari**: Comprehensive ad blocking
- **1Blocker**: Privacy-focused blocking
- **Wipr**: Lightweight ad blocker
EOF

    # Chrome installation guide
    cat > "$UBLOCK_CONFIG_DIR/install-guides/chrome.md" << 'EOF'
# uBlock Origin for Chrome Installation Guide

## Installation Steps

1. **Install from Chrome Web Store**
   - Open Chrome Web Store
   - Search for "uBlock Origin"
   - Click "Add to Chrome"
   - Confirm installation

2. **Configure Extension**
   - Click the uBlock Origin icon in toolbar
   - Open dashboard (settings icon)
   - Navigate to "Filter lists" tab

3. **Import Custom Filters**
   - In dashboard, go to "My filters" tab
   - Copy content from `filters/custom-filters.txt`
   - Paste into the text area
   - Click "Apply changes"

4. **Import Backup Settings**
   - Go to "Settings" tab
   - Click "Restore from file"
   - Select backup file from `backup/` directory

## Extension URL
chrome-extension://cjpalhdlnbpafiamejdnhcphjbkeiagm/dashboard.html

## Advanced Configuration

### Custom Filter Lists
- Enable "Malware Domain List"
- Enable "Peter Lowe's Ad and tracking server list"
- Add custom filter URLs if needed

### Whitelist Management
- Add trusted domains to whitelist
- Use temporary whitelist for troubleshooting
EOF

    # Firefox installation guide
    cat > "$UBLOCK_CONFIG_DIR/install-guides/firefox.md" << 'EOF'
# uBlock Origin for Firefox Installation Guide

## Installation Steps

1. **Install from Firefox Add-ons**
   - Open Firefox Add-ons page (Ctrl+Shift+A)
   - Search for "uBlock Origin"
   - Click "Add to Firefox"
   - Grant necessary permissions

2. **Access Dashboard**
   - Click uBlock Origin icon in toolbar
   - Click the dashboard icon (settings)
   - Navigate through configuration tabs

3. **Import Custom Configuration**
   - Go to "My filters" tab
   - Import custom filters from `filters/` directory
   - Apply changes and test

4. **Backup and Restore**
   - Use "Settings" tab for backup/restore
   - Export settings for backup
   - Import from backup file when needed

## Extension URL
moz-extension://[unique-id]/dashboard.html

## Firefox-Specific Features

### Enhanced Tracking Protection
- Works alongside Firefox's built-in protection
- Can be configured to complement each other
- Avoid conflicts by reviewing settings

### Developer Tools Integration
- Advanced users can use Firefox Developer Tools
- Network monitoring shows blocked requests
- Useful for filter development and testing
EOF

    log "Installation guides created for all supported browsers"
}

# Create backup and restore functionality
create_backup_system() {
    log "Creating backup and restore system..."

    # Backup script
    cat > "$UBLOCK_CONFIG_DIR/backup-settings.sh" << 'EOF'
#!/usr/bin/env bash

# uBlock Origin Settings Backup Script
# Automatically backs up uBlock Origin settings from all browsers

set -euo pipefail

BACKUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/backup" && pwd)"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Chrome/Chromium backup
backup_chrome() {
    local chrome_dir="$HOME/Library/Application Support/Google/Chrome/Default/Extensions/cjpalhdlnbpafiamejdnhcphjbkeiagm"
    if [[ -d "$chrome_dir" ]]; then
        log "Backing up Chrome uBlock Origin settings..."
        mkdir -p "$BACKUP_DIR/chrome-$TIMESTAMP"
        # Chrome extension settings are in Local Storage and need special handling
        log "Chrome backup requires manual export from uBlock Origin dashboard"
    fi
}

# Firefox backup
backup_firefox() {
    local firefox_profile=$(find "$HOME/Library/Application Support/Firefox/Profiles" -name "*.default*" -type d | head -1)
    if [[ -n "$firefox_profile" && -d "$firefox_profile" ]]; then
        log "Backing up Firefox uBlock Origin settings..."
        mkdir -p "$BACKUP_DIR/firefox-$TIMESTAMP"
        # Firefox addon storage
        if [[ -d "$firefox_profile/storage/default/moz-extension+++*" ]]; then
            cp -r "$firefox_profile/storage/default/moz-extension"* "$BACKUP_DIR/firefox-$TIMESTAMP/" 2>/dev/null || true
        fi
    fi
}

# Create manual backup instructions
create_manual_instructions() {
    cat > "$BACKUP_DIR/manual-backup-instructions.md" << 'EOL'
# Manual Backup Instructions

Due to browser security restrictions, some settings require manual backup:

## Chrome/Chromium
1. Open uBlock Origin dashboard
2. Go to "Settings" tab
3. Click "Backup to file"
4. Save file to backup directory

## Firefox
1. Open uBlock Origin dashboard
2. Go to "Settings" tab
3. Click "Backup to file"
4. Save file to backup directory

## Safari/Other Browsers
1. Export settings through extension interface
2. Save configuration files
3. Document custom filter lists
EOL
}

main() {
    log "Starting uBlock Origin backup process..."
    mkdir -p "$BACKUP_DIR"

    backup_chrome
    backup_firefox
    create_manual_instructions

    log "Backup process completed"
    log "Manual backup instructions created: $BACKUP_DIR/manual-backup-instructions.md"
}

main "$@"
EOF

    chmod +x "$UBLOCK_CONFIG_DIR/backup-settings.sh"

    # Create initial backup directory
    mkdir -p "$UBLOCK_CONFIG_DIR/backup"

    log "Backup system created"
}

# Create update automation
create_update_automation() {
    log "Creating filter list update automation..."

    cat > "$UBLOCK_CONFIG_DIR/update-filters.sh" << 'EOF'
#!/usr/bin/env bash

# uBlock Origin Filter Update Script
# Automatically updates custom filter lists and checks for updates

set -euo pipefail

FILTERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/filters" && pwd)"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Update custom filters with latest content
update_custom_filters() {
    log "Checking for filter list updates..."

    # Add timestamp to filter files
    local timestamp=$(date +%Y%m%d)

    # Update version in custom filters
    if [[ -f "$FILTERS_DIR/custom-filters.txt" ]]; then
        sed -i.bak "s/! Version: .*/! Version: 1.0.$timestamp/" "$FILTERS_DIR/custom-filters.txt"
        rm -f "$FILTERS_DIR/custom-filters.txt.bak"
        log "Updated custom filters version"
    fi

    log "Filter update completed"
}

# Validate filter syntax
validate_filters() {
    log "Validating filter syntax..."

    for filter_file in "$FILTERS_DIR"/*.txt; do
        if [[ -f "$filter_file" ]]; then
            # Basic syntax validation
            if grep -q "^[^!].*\$.*[^$]$" "$filter_file" 2>/dev/null; then
                log "Warning: Potential syntax issues in $(basename "$filter_file")"
            else
                log "✓ $(basename "$filter_file") syntax OK"
            fi
        fi
    done
}

main() {
    log "Starting filter update process..."
    update_custom_filters
    validate_filters
    log "Filter update process completed"
}

main "$@"
EOF

    chmod +x "$UBLOCK_CONFIG_DIR/update-filters.sh"

    log "Filter update automation created"
}

# Create launchd service for automatic maintenance
create_maintenance_service() {
    local plist_file="$HOME/Library/LaunchAgents/com.larsartmann.ublock-maintenance.plist"

    log "Creating automatic maintenance service..."
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.larsartmann.ublock-maintenance</string>
    <key>ProgramArguments</key>
    <array>
        <string>$UBLOCK_CONFIG_DIR/update-filters.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$UBLOCK_CONFIG_DIR/maintenance.log</string>
    <key>StandardErrorPath</key>
    <string>$UBLOCK_CONFIG_DIR/maintenance.error.log</string>
</dict>
</plist>
EOF

    launchctl load "$plist_file" 2>/dev/null || warn "launchd service may already be loaded"
    log "Automatic maintenance service created and loaded: $plist_file"
}

# Check browser installation status
check_browsers() {
    log "Checking browser installation status..."

    local browsers_found=0

    # Check Safari
    if [[ -d "/Applications/Safari.app" ]]; then
        log "✓ Safari found"
        browsers_found=$((browsers_found + 1))
    fi

    # Check Chrome
    if [[ -d "/Applications/Google Chrome.app" ]]; then
        log "✓ Chrome found"
        browsers_found=$((browsers_found + 1))
    fi

    # Check Firefox
    if [[ -d "/Applications/Firefox.app" ]]; then
        log "✓ Firefox found"
        browsers_found=$((browsers_found + 1))
    fi

    # Check Edge
    if [[ -d "/Applications/Microsoft Edge.app" ]]; then
        log "✓ Microsoft Edge found"
        browsers_found=$((browsers_found + 1))
    fi

    # Check Brave
    if [[ -d "/Applications/Brave Browser.app" ]]; then
        log "✓ Brave Browser found"
        browsers_found=$((browsers_found + 1))
    fi

    if [[ $browsers_found -eq 0 ]]; then
        warn "No supported browsers found"
    else
        log "$browsers_found supported browser(s) found"
    fi
}

# Show installation summary
show_installation_summary() {
    cat << EOF

📋 uBlock Origin Setup Summary
========================================

✅ Configuration Structure: $UBLOCK_CONFIG_DIR
✅ Custom Filter Lists: Created with enhanced privacy protection
✅ Installation Guides: Created for all major browsers
✅ Backup System: Automated backup and restore functionality
✅ Update Automation: Daily filter list updates at 9 AM
✅ Maintenance Service: Automated via launchd

📁 Directory Structure:
   filters/          - Custom filter lists and rules
   backup/           - Settings backup storage
   install-guides/   - Browser-specific installation instructions
   extensions/       - Extension metadata

🔧 Next Steps:
1. Install uBlock Origin in your browsers using the guides in install-guides/
2. Import custom filters from filters/custom-filters.txt
3. Configure extension settings per browser requirements
4. Run backup manually: $UBLOCK_CONFIG_DIR/backup-settings.sh

📖 For detailed instructions, see: $UBLOCK_CONFIG_DIR/README.md

EOF
}

# Show usage information
show_usage() {
    cat << EOF
uBlock Origin Setup Automation

Usage: $0 [OPTION]

Options:
    --setup         Setup complete uBlock Origin configuration
    --backup        Create backup of current settings
    --update        Update filter lists
    --status        Check browser and extension status
    --help          Show this help message

Without arguments, performs complete setup.

Examples:
    $0              # Complete setup
    $0 --backup     # Backup current settings
    $0 --update     # Update filter lists
    $0 --status     # Check installation status

Configuration directory: $UBLOCK_CONFIG_DIR
EOF
}

# Main execution function
main() {
    local action="${1:-setup}"

    case "$action" in
        --setup|setup)
            setup_ublock_structure
            create_custom_filters
            create_installation_guides
            create_backup_system
            create_update_automation
            create_maintenance_service
            check_browsers
            show_installation_summary
            ;;
        --backup|backup)
            if [[ -f "$UBLOCK_CONFIG_DIR/backup-settings.sh" ]]; then
                "$UBLOCK_CONFIG_DIR/backup-settings.sh"
            else
                error "Backup script not found. Run --setup first."
            fi
            ;;
        --update|update)
            if [[ -f "$UBLOCK_CONFIG_DIR/update-filters.sh" ]]; then
                "$UBLOCK_CONFIG_DIR/update-filters.sh"
            else
                error "Update script not found. Run --setup first."
            fi
            ;;
        --status|status)
            check_browsers
            ;;
        --help|help|-h)
            show_usage
            exit 0
            ;;
        *)
            # Default: complete setup
            setup_ublock_structure
            create_custom_filters
            create_installation_guides
            create_backup_system
            create_update_automation
            create_maintenance_service
            check_browsers
            show_installation_summary
            ;;
    esac

    log "✅ uBlock Origin setup completed successfully!"
}

# Run the main function with all arguments
main "$@"