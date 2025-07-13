#!/bin/bash

# Claude Configuration Script with Logging and Conditional Updates
# ==============================================================

set -euo pipefail

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

# Function to get current config value
get_config_value() {
    local key="$1"
    if [[ -f ~/.claude.json ]]; then
        # Use claude config ls -g to get the actual config values
        claude config ls -g 2>/dev/null | jq -r ".${key} // null" 2>/dev/null || echo "null"
    else
        echo "null"
    fi
}

# Function to set config if different
set_config_if_needed() {
    local key="$1"
    local new_value="$2"
    local current_value
    
    current_value=$(get_config_value "$key")
    
    if [[ "$current_value" != "$new_value" && "$current_value" != "\"$new_value\"" ]]; then
        log_info "Setting $key: $current_value -> $new_value"
        claude config set -g "$key" "$new_value"
        log_success "✓ $key updated"
    else
        log_info "✓ $key already set to $new_value (skipping)"
    fi
}

# Update global packages
log_info "Updating global bun packages..."
bun update -g
log_success "✓ Global packages updated"

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
current_env=$(claude config ls -g 2>/dev/null | jq -r '.env // {}' 2>/dev/null || echo '{}')
target_env='{"EDITOR":"nano", "CLAUDE_CODE_ENABLE_TELEMETRY":"1", "OTEL_METRICS_EXPORTER":"otlp", "OTEL_LOGS_EXPORTER":"otlp", "OTEL_EXPORTER_OTLP_PROTOCOL":"grpc", "OTEL_EXPORTER_OTLP_ENDPOINT":"http://localhost:4317", "OTEL_METRIC_EXPORT_INTERVAL":"10000", "OTEL_LOGS_EXPORT_INTERVAL":"5000"}'

# Compare the JSON objects properly
target_env_normalized=$(echo "$target_env" | jq -S .)
current_env_normalized=$(echo "$current_env" | jq -S .)

if [[ "$current_env_normalized" != "$target_env_normalized" ]]; then
    log_info "Updating environment variables (OTEL_METRIC_EXPORT_INTERVAL for debugging)"
    claude config set -g env "$target_env"
    log_success "✓ Environment variables updated"
else
    log_info "✓ Environment variables already configured (skipping)"
fi

# Display final configuration
log_info "Displaying final configuration..."
claude config ls

log_success "Claude configuration complete!"

