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
        --profile)
            CURRENT_PROFILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --dry-run              Preview changes without applying them"
            echo "  --backup               Create backup before applying changes"
            echo "  --profile PROFILE      Use configuration profile (dev/prod/personal)"
            echo "  --help                 Show this help message"
            echo ""
            echo "Profiles:"
            echo "  dev/development        High performance settings for development"
            echo "  prod/production        Conservative settings for production"
            echo "  personal/default       Balanced settings for personal use"
            echo ""
            echo "Environment Variables:"
            echo "  CLAUDE_PROFILE         Set default profile (overridden by --profile)"
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

# Configuration Schema - Centralized configuration management
# Using space-separated format for bash 3+ compatibility
CLAUDE_CONFIG_KEYS="theme parallelTasksCount preferredNotifChannel messageIdleNotifThresholdMs autoUpdates diffTool"
CLAUDE_CONFIG_VALUES="dark-daltonized 20 iterm2_with_bell 1000 false bat"

# Function to get schema value by key
get_schema_value() {
    local key="$1"
    local keys_array=($CLAUDE_CONFIG_KEYS)
    local values_array=($CLAUDE_CONFIG_VALUES)
    
    for i in "${!keys_array[@]}"; do
        if [[ "${keys_array[i]}" == "$key" ]]; then
            echo "${values_array[i]}"
            return 0
        fi
    done
    echo ""
}

# Environment Variables Schema
CLAUDE_ENV_SCHEMA='{
    "EDITOR": "nano",
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
    "OTEL_METRIC_EXPORT_INTERVAL": "10000",
    "OTEL_LOGS_EXPORT_INTERVAL": "5000"
}'

# Configuration profiles support (dev/prod/personal)
CURRENT_PROFILE="${CLAUDE_PROFILE:-default}"

# ConfigService - Service-oriented configuration management
config_service_load_profile() {
    local profile="${1:-$CURRENT_PROFILE}"
    
    case "$profile" in
        "dev"|"development")
            log_info "Loading development profile..."
            # Development profile: more verbose, faster updates
            CLAUDE_CONFIG_VALUES="dark-daltonized 50 iterm2_with_bell 500 false bat"
            CLAUDE_ENV_SCHEMA='{
                "EDITOR": "nano",
                "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
                "OTEL_METRICS_EXPORTER": "otlp",
                "OTEL_LOGS_EXPORTER": "otlp",
                "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
                "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
                "OTEL_METRIC_EXPORT_INTERVAL": "5000",
                "OTEL_LOGS_EXPORT_INTERVAL": "2500"
            }'
            ;;
        "prod"|"production")
            log_info "Loading production profile..."
            # Production profile: stable, conservative settings
            CLAUDE_CONFIG_VALUES="dark-daltonized 10 iterm2_with_bell 2000 false bat"
            CLAUDE_ENV_SCHEMA='{
                "EDITOR": "nano",
                "CLAUDE_CODE_ENABLE_TELEMETRY": "0",
                "OTEL_METRICS_EXPORTER": "none",
                "OTEL_LOGS_EXPORTER": "none"
            }'
            ;;
        "personal"|"default"|*)
            log_info "Loading personal/default profile..."
            # Personal profile: balanced settings (original)
            CLAUDE_CONFIG_VALUES="dark-daltonized 20 iterm2_with_bell 1000 false bat"
            CLAUDE_ENV_SCHEMA='{
                "EDITOR": "nano",
                "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
                "OTEL_METRICS_EXPORTER": "otlp",
                "OTEL_LOGS_EXPORTER": "otlp",
                "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
                "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
                "OTEL_METRIC_EXPORT_INTERVAL": "10000",
                "OTEL_LOGS_EXPORT_INTERVAL": "5000"
            }'
            ;;
    esac
    
    log_success "✓ Profile '$profile' loaded"
}

# ConfigService - Validate profile configuration
config_service_validate_profile() {
    local profile="${1:-$CURRENT_PROFILE}"
    
    case "$profile" in
        "dev"|"development"|"prod"|"production"|"personal"|"default")
            return 0
            ;;
        *)
            log_error "❌ Invalid profile '$profile'. Valid profiles: dev, prod, personal"
            return 1
            ;;
    esac
}

# ConfigService - Get profile-specific backup name
config_service_get_backup_name() {
    local profile="${1:-$CURRENT_PROFILE}"
    echo "claude-config-${profile}-$(date +%Y%m%d_%H%M%S)"
}

# Function to load config once and cache it from ~/.claude.json directly
load_config_cache() {
    if [[ "$CACHE_LOADED" == "false" ]]; then
        if [[ -f ~/.claude.json ]]; then
            if [[ "$DRY_RUN" != "true" ]]; then
                log_info "Loading claude configuration from ~/.claude.json (one-time)..."
            fi
            # Read FLAT structure directly from ~/.claude.json (NO .global section!)
            CLAUDE_CONFIG_CACHE=$(cat ~/.claude.json 2>/dev/null || echo '{}')
            CACHE_LOADED=true
        else
            CLAUDE_CONFIG_CACHE='{}'
            CACHE_LOADED=true
        fi
    fi
}

# Function to invalidate cache (force reload on next access)
invalidate_config_cache() {
    if [[ "$DRY_RUN" != "true" ]]; then
        log_info "🔄 Cache invalidated - next config read will reload from file"
    fi
    CACHE_LOADED=false
    CLAUDE_CONFIG_CACHE=""
}

# Function to get current config value (uses cached ~/.claude.json data)
get_config_value() {
    local key="$1"
    
    # Ensure config is loaded (silently - no log output during value retrieval)
    if [[ "$CACHE_LOADED" == "false" ]]; then
        load_config_cache >/dev/null 2>&1
    fi
    
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

# Function to set config if different (NO cache invalidation here)
set_config_if_needed() {
    local key="$1"
    local new_value="$2"
    local current_value
    
    current_value=$(get_config_value "$key")
    
    # Handle quoted values properly - remove quotes for comparison
    if [[ "$current_value" == "\"$new_value\"" ]]; then
        current_value="$new_value"
    fi
    
    # Also handle the case where current value has quotes
    current_value=$(echo "$current_value" | sed 's/^"//;s/"$//')
    
    # Debug output to see what's being compared
    # echo "DEBUG: Comparing '$current_value' vs '$new_value'" >&2
    
    if [[ "$current_value" != "$new_value" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would set $key: $current_value -> $new_value"
        else
            log_info "Setting $key: $current_value -> $new_value"
            claude config set -g "$key" "$new_value"
            log_success "✓ $key updated"
        fi
        return 0  # Changed
    else
        log_info "✓ $key already set to $new_value (skipping)"
        return 1  # No change
    fi
}

# Function to create backup of current configuration
create_backup() {
    if [[ "$CREATE_BACKUP" == "true" || "$DRY_RUN" == "true" ]]; then
        local backup_name=$(config_service_get_backup_name "$CURRENT_PROFILE")
        local backup_file="$HOME/.${backup_name}.json"
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "[DRY-RUN] Would create backup: $backup_file"
        else
            log_info "Creating profile-aware backup: $backup_file"
            cp "$HOME/.claude.json" "$backup_file" 2>/dev/null || true
            log_success "✓ Backup created: $backup_file"
        fi
    fi
}

# Function to check if claude-code needs updates
check_claude_updates() {
    if ! command -v bun &> /dev/null; then
        log_warning "bun not found - skipping claude-code update check"
        return 1
    fi
    
    if ! command -v claude &> /dev/null; then
        log_warning "claude command not found - skipping update check"
        return 1
    fi
    
    local current_version
    current_version=$(bun --version 2>/dev/null || echo "unknown")
    log_info "Current bun version: $current_version"
    
    # Always attempt to update claude-code to ensure latest features
    return 0
}

# Function to smart update claude-code specifically
smart_update_claude() {
    if check_claude_updates; then
        execute_command "bun update -g @anthropic-ai/claude-code" "Updating claude-code package..."
        if [[ "$DRY_RUN" != "true" ]]; then
            log_success "✓ claude-code package updated"
        fi
    else
        log_info "✓ Bun or claude not available (skipping claude-code update)"
    fi
}

# Initialize ConfigService and validate profile
if ! config_service_validate_profile "$CURRENT_PROFILE"; then
    exit 1
fi

# Load configuration profile
config_service_load_profile "$CURRENT_PROFILE"

# Display mode information
if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "🔍 DRY-RUN MODE: No changes will be applied"
fi

if [[ "$CURRENT_PROFILE" != "default" && "$CURRENT_PROFILE" != "personal" ]]; then
    log_info "🎯 Using profile: $CURRENT_PROFILE"
fi

# Create backup if requested
create_backup

# Update claude-code package specifically
smart_update_claude

# Configure Claude settings with conditional updates
log_info "Configuring Claude settings..."

# Apply configuration from schema instead of hard-coded values
keys_array=($CLAUDE_CONFIG_KEYS)
config_changes_made=false

for config_key in "${keys_array[@]}"; do
    schema_value=$(get_schema_value "$config_key")
    if set_config_if_needed "$config_key" "$schema_value"; then
        config_changes_made=true
    fi
done

# Handle environment variables separately (more complex JSON structure)
log_info "Configuring environment variables..."
# Use cached config instead of subprocess call
load_config_cache

# Get current environment variables from cache (FLAT structure, not .global.env)
current_env=$(echo "$CLAUDE_CONFIG_CACHE" | jq -r '.env // {}' 2>/dev/null || echo '{}')

# Use environment schema instead of hard-coded JSON
target_env="$CLAUDE_ENV_SCHEMA"

# Efficient JSON comparison using single jq call with conditional
env_needs_update=$(echo "$current_env" "$target_env" | jq -s '.[0] != .[1]' 2>/dev/null || echo 'true')

if [[ "$env_needs_update" == "true" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would update environment variables (OTEL_METRIC_EXPORT_INTERVAL for debugging)"
    else
        log_info "Updating environment variables (OTEL_METRIC_EXPORT_INTERVAL for debugging)"
        claude config set -g env "$target_env"
        config_changes_made=true
        # Note: Environment variables may not persist due to claude config limitations
        log_warning "⚠️  Note: Environment variables may not persist due to claude config limitations"
        log_success "✓ Environment variables command executed"
    fi
else
    log_info "✓ Environment variables already configured (skipping)"
fi

# BATCH INVALIDATION: Reload cache once after ALL changes for validation
if [[ "$config_changes_made" == "true" && "$DRY_RUN" != "true" ]]; then
    log_info "Reloading config cache after batch changes for validation..."
    invalidate_config_cache
    # Load fresh cache once for validation phase
    load_config_cache >/dev/null 2>&1
fi

# Validate configuration after changes
validate_configuration() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would validate configuration"
        return 0
    fi
    
    log_info "Validating configuration..."
    local config_valid=true
    
    # Validate all configuration settings against schema
    local keys_array=($CLAUDE_CONFIG_KEYS)
    for config_key in "${keys_array[@]}"; do
        local current_value=$(get_config_value "$config_key")
        local expected_value=$(get_schema_value "$config_key")
        
        if [[ "$current_value" != "$expected_value" ]]; then
            log_error "❌ $config_key validation failed: expected '$expected_value', got '$current_value'"
            config_valid=false
        fi
    done
    
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

