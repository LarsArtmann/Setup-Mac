#!/bin/bash

# ActivityWatch Configuration Management Script
# Automates ActivityWatch configuration backup, restore, and optimization

set -euo pipefail

# Configuration
AW_CONFIG_DIR="$HOME/Library/Application Support/activitywatch"
DOTFILES_AW_DIR="./dotfiles/activitywatch"
BACKUP_DIR="./backups/activitywatch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "${BLUE}📊 $1${NC}"
    echo "----------------------------------------"
}

# Function to log with timestamp
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"
}

# Function to setup directories
setup_directories() {
    mkdir -p "$DOTFILES_AW_DIR"
    mkdir -p "$BACKUP_DIR"
    log "Created configuration directories"
}

# Function to backup current ActivityWatch config
backup_config() {
    print_header "Backing up ActivityWatch Configuration"
    
    if [[ ! -d "$AW_CONFIG_DIR" ]]; then
        echo -e "${RED}ActivityWatch config directory not found${NC}"
        return 1
    fi
    
    local backup_file="$BACKUP_DIR/activitywatch-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    # Create backup excluding database files (too large)
    tar --exclude="*.db" --exclude="*.db-*" --exclude="queued" \
        -czf "$backup_file" -C "$(dirname "$AW_CONFIG_DIR")" "$(basename "$AW_CONFIG_DIR")"
    
    log "Configuration backed up to: $backup_file"
    echo -e "${GREEN}✅ Backup completed${NC}"
}

# Function to extract key configuration files
extract_config() {
    print_header "Extracting Key Configuration Files"
    
    # Key config files to manage
    local config_files=(
        "aw-server/aw-server.toml"
        "aw-watcher-afk/aw-watcher-afk.toml"
        "aw-watcher-window/aw-watcher-window.toml"
        "aw-qt/aw-qt.toml"
        "aw-client/aw-client.toml"
        "aw-server/settings.json"
    )
    
    for config_file in "${config_files[@]}"; do
        local source_file="$AW_CONFIG_DIR/$config_file"
        local dest_file="$DOTFILES_AW_DIR/$config_file"
        
        if [[ -f "$source_file" ]]; then
            mkdir -p "$(dirname "$dest_file")"
            cp "$source_file" "$dest_file"
            log "Extracted: $config_file"
        else
            echo -e "${YELLOW}⚠️  Not found: $config_file${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Configuration extraction completed${NC}"
}

# Function to apply configuration from dotfiles
apply_config() {
    print_header "Applying Configuration from Dotfiles"
    
    if [[ ! -d "$DOTFILES_AW_DIR" ]]; then
        echo -e "${RED}Dotfiles ActivityWatch config not found${NC}"
        return 1
    fi
    
    # Stop ActivityWatch if running
    pkill -f "ActivityWatch" || true
    sleep 2
    
    # Apply configuration files
    find "$DOTFILES_AW_DIR" -type f -name "*.toml" -o -name "*.json" | while read -r config_file; do
        local relative_path="${config_file#$DOTFILES_AW_DIR/}"
        local target_file="$AW_CONFIG_DIR/$relative_path"
        
        mkdir -p "$(dirname "$target_file")"
        cp "$config_file" "$target_file"
        log "Applied: $relative_path"
    done
    
    echo -e "${GREEN}✅ Configuration applied${NC}"
    echo -e "${YELLOW}📝 Note: Restart ActivityWatch to apply changes${NC}"
}

# Function to optimize ActivityWatch settings
optimize_settings() {
    print_header "Optimizing ActivityWatch Settings"
    
    local settings_file="$AW_CONFIG_DIR/aw-server/settings.json"
    
    if [[ -f "$settings_file" ]]; then
        # Create optimized settings
        cat > "$settings_file" << 'EOF'
{
  "database": {
    "type": "sqlite",
    "path": "peewee-sqlite.v2.db"
  },
  "server": {
    "port": 5600,
    "cors_origins": ["http://localhost:5600"]
  },
  "storage": {
    "retention_days": 90,
    "auto_cleanup": true
  }
}
EOF
        log "Applied optimized server settings"
    fi
    
    # Optimize watcher settings for better performance
    local afk_config="$AW_CONFIG_DIR/aw-watcher-afk/aw-watcher-afk.toml"
    if [[ -f "$afk_config" ]]; then
        cat > "$afk_config" << 'EOF'
timeout = 300
poll_time = 5

[client]
commit_interval = 10
EOF
        log "Optimized AFK watcher settings"
    fi
    
    echo -e "${GREEN}✅ Optimization completed${NC}"
}

# Function to check ActivityWatch status
check_status() {
    print_header "ActivityWatch Status"
    
    if pgrep -f "ActivityWatch" > /dev/null; then
        echo -e "${GREEN}✅ ActivityWatch is running${NC}"
        
        # Check if web interface is accessible
        if curl -s "http://localhost:5600" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Web interface accessible at http://localhost:5600${NC}"
        else
            echo -e "${YELLOW}⚠️  Web interface not accessible${NC}"
        fi
    else
        echo -e "${RED}❌ ActivityWatch is not running${NC}"
    fi
    
    # Check config files
    echo ""
    echo "Configuration files:"
    local config_files=(
        "aw-server/aw-server.toml"
        "aw-watcher-afk/aw-watcher-afk.toml"
        "aw-watcher-window/aw-watcher-window.toml"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$AW_CONFIG_DIR/$config_file" ]]; then
            echo -e "${GREEN}✅${NC} $config_file"
        else
            echo -e "${RED}❌${NC} $config_file"
        fi
    done
}

# Function to clean up old data
cleanup_data() {
    print_header "Cleaning up Old Data"
    
    # Clean up excessive queue directories (keep only recent ones)
    local queue_dir="$AW_CONFIG_DIR/aw-client/queued"
    if [[ -d "$queue_dir" ]]; then
        local queue_count=$(find "$queue_dir" -name "get-setting-*.v1.persistqueue" | wc -l)
        echo "Found $queue_count queue directories"
        
        if [[ $queue_count -gt 100 ]]; then
            echo -e "${YELLOW}⚠️  Many queue directories found. Consider manual cleanup.${NC}"
            echo "Directory: $queue_dir"
        fi
    fi
    
    echo -e "${GREEN}✅ Cleanup check completed${NC}"
}

# Function to show usage
show_usage() {
    echo "ActivityWatch Configuration Management"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  backup     - Backup current ActivityWatch configuration"
    echo "  extract    - Extract config files to dotfiles"
    echo "  apply      - Apply configuration from dotfiles"
    echo "  optimize   - Apply performance optimizations"
    echo "  status     - Check ActivityWatch status"
    echo "  cleanup    - Clean up old data"
    echo "  setup      - Setup configuration directories"
    echo ""
}

# Main command handling
case "${1:-}" in
    backup)
        setup_directories
        backup_config
        ;;
    extract)
        setup_directories
        extract_config
        ;;
    apply)
        apply_config
        ;;
    optimize)
        optimize_settings
        ;;
    status)
        check_status
        ;;
    cleanup)
        cleanup_data
        ;;
    setup)
        setup_directories
        ;;
    *)
        show_usage
        exit 1
        ;;
esac