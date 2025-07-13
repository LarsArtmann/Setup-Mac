#!/bin/bash

# Claude Configuration Script with Logging and Conditional Updates
# ==============================================================
# Usage: ./claude-conf.sh [OPTIONS]
# Options:
#   --dry-run    Preview changes without applying them
#   --backup     Create backup before applying changes
#   --help       Show this help message

set -euo pipefail

# Global flags
DRY_RUN=false
CREATE_BACKUP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --backup)
            CREATE_BACKUP=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --dry-run    Preview changes without applying them"
            echo "  --backup     Create backup before applying changes"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if jq is available
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Please install it first."
    exit 1
fi

# Check if claude command is available
if ! command -v claude &> /dev/null; then
    log_error "claude command is not available. Please install claude first."
    exit 1
fi

# Global config cache
CLAUDE_CONFIG_CACHE=""
CACHE_LOADED=false

# Function to load config once and cache it from ~/.claude.json directly
load_config_cache() {
    if [[ "$CACHE_LOADED" == "false" ]]; then
        if [[ -f ~/.claude.json ]]; then
            if [[ "$DRY_RUN" != "true" ]]; then
                log_info "Loading claude configuration from ~/.claude.json (one-time)..."
            fi
            # Read .global section directly from ~/.claude.json using jq
            CLAUDE_CONFIG_CACHE=$(jq -r '.global // {}' ~/.claude.json 2>/dev/null || echo '{}')
            CACHE_LOADED=true
        else
            CLAUDE_CONFIG_CACHE='{}'
            CACHE_LOADED=true
        fi
    fi
}

# Function to get current config value (uses cached ~/.claude.json data)
get_config_value() {
    local key="$1"
    
    # Ensure config is loaded
    load_config_cache
    
    # Use cached config from ~/.claude.json instead of subprocess calls
    echo "$CLAUDE_CONFIG_CACHE" | jq -r ".${key} // null" 2>/dev/null || echo "null"
}

# Function to execute command with dry-run support
execute_command() {
    local cmd="$1"
    local description="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would execute: $cmd"
    else
        log_info "$description"
        eval "$cmd"
    fi
}

# Function to set config if different
set_config_if_needed() {
    local key="$1"
    local new_value="$2"
    local current_value
    
    current_value=$(get_config_value "$key")
    
    if [[ "$current_value" != "$new_value" && "$current_value" != "\"$new_value\"" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would set $key: $current_value -> $new_value"
        else
            log_info "Setting $key: $current_value -> $new_value"
            claude config set -g "$key" "$new_value"
            log_success "✓ $key updated"
        fi
    else
        log_info "✓ $key already set to $new_value (skipping)"
    fi
}

# Function to create backup of current configuration
create_backup() {
    if [[ "$CREATE_BACKUP" == "true" || "$DRY_RUN" == "true" ]]; then
        local backup_file="$HOME/.claude.json.backup.$(date +%Y%m%d_%H%M%S)"
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would create backup: $backup_file"
        else
            log_info "Creating backup: $backup_file"
            cp "$HOME/.claude.json" "$backup_file" 2>/dev/null || true
            log_success "✓ Backup created: $backup_file"
        fi
    fi
}

# Function to check if bun has updates available
check_bun_updates() {
    if ! command -v bun &> /dev/null; then
        log_warning "bun not found - skipping version check"
        return 1
    fi
    
    local current_version
    local latest_version
    
    current_version=$(bun --version 2>/dev/null || echo "unknown")
    log_info "Current bun version: $current_version"
    
    # For now, we'll always suggest running update since checking latest version
    # remotely would require network calls and might slow down the script
    return 0
}

# Function to smart update bun packages
smart_update_bun() {
    if check_bun_updates; then
        execute_command "bun update -g" "Updating global bun packages..."
        if [[ "$DRY_RUN" != "true" ]]; then
            log_success "✓ Global packages updated"
        fi
    else
        log_info "✓ Bun not available or up to date (skipping)"
    fi
}

# Display mode information
if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "🔍 DRY-RUN MODE: No changes will be applied"
fi

# Create backup if requested
create_backup

# Update global packages with smart checking
smart_update_bun

# Configure Claude settings with conditional updates
log_info "Configuring Claude settings..."

set_config_if_needed "theme" "dark-daltonized"
set_config_if_needed "parallelTasksCount" "20"
set_config_if_needed "preferredNotifChannel" "iterm2_with_bell"
set_config_if_needed "messageIdleNotifThresholdMs" "1000"
set_config_if_needed "autoUpdates" "false"
set_config_if_needed "diffTool" "bat"

# Handle environment variables separately (more complex JSON structure)
log_info "Configuring environment variables..."
# Use cached config instead of subprocess call
load_config_cache
current_env=$(echo "$CLAUDE_CONFIG_CACHE" | jq -r '.env // {}' 2>/dev/null || echo '{}')
target_env='{"EDITOR":"nano", "CLAUDE_CODE_ENABLE_TELEMETRY":"1", "OTEL_METRICS_EXPORTER":"otlp", "OTEL_LOGS_EXPORTER":"otlp", "OTEL_EXPORTER_OTLP_PROTOCOL":"grpc", "OTEL_EXPORTER_OTLP_ENDPOINT":"http://localhost:4317", "OTEL_METRIC_EXPORT_INTERVAL":"10000", "OTEL_LOGS_EXPORT_INTERVAL":"5000"}'

# Compare the JSON objects properly
target_env_normalized=$(echo "$target_env" | jq -S .)
current_env_normalized=$(echo "$current_env" | jq -S .)

if [[ "$current_env_normalized" != "$target_env_normalized" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would update environment variables (OTEL_METRIC_EXPORT_INTERVAL for debugging)"
    else
        log_info "Updating environment variables (OTEL_METRIC_EXPORT_INTERVAL for debugging)"
        claude config set -g env "$target_env"
        # Note: Environment variables may not persist due to claude config limitations
        log_warning "⚠️  Note: Environment variables may not persist due to claude config limitations"
        log_success "✓ Environment variables command executed"
    fi
else
    log_info "✓ Environment variables already configured (skipping)"
fi

# Validate configuration after changes
validate_configuration() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would validate configuration"
        return 0
    fi
    
    log_info "Validating configuration..."
    local config_valid=true
    
    # Check critical settings
    local current_theme=$(get_config_value "theme")
    local current_parallel=$(get_config_value "parallelTasksCount")
    local current_diff=$(get_config_value "diffTool")
    
    if [[ "$current_theme" != "dark-daltonized" ]]; then
        log_error "❌ Theme validation failed: expected 'dark-daltonized', got '$current_theme'"
        config_valid=false
    fi
    
    if [[ "$current_parallel" != "20" ]]; then
        log_error "❌ Parallel tasks validation failed: expected '20', got '$current_parallel'"
        config_valid=false
    fi
    
    if [[ "$current_diff" != "bat" ]]; then
        log_error "❌ Diff tool validation failed: expected 'bat', got '$current_diff'"
        config_valid=false
    fi
    
    if [[ "$config_valid" == "true" ]]; then
        log_success "✓ Configuration validation passed"
    else
        log_error "❌ Configuration validation failed - some settings may not have been applied correctly"
        return 1
    fi
}

# Display final configuration
log_info "Displaying final configuration..."
if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "[DRY-RUN] Would display: claude config ls"
else
    claude config ls
fi

# Validate the configuration
validate_configuration

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "🔍 DRY-RUN completed - no changes were made"
else
    log_success "Claude configuration complete!"
fi

