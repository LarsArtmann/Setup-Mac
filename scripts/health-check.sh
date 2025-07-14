#!/bin/bash

# System Health Check and Alerting Script
# =====================================
# Monitors system performance and configuration health
# Supports alerting and automated reporting

set -euo pipefail

# Configuration
ALERT_MODE=false
COMPREHENSIVE=false
VERBOSE=false
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
ALERT_THRESHOLD_SHELL_MS=2000

# Alert targets
ALERT_EMAIL=""
ALERT_WEBHOOK=""
ALERT_LOG_FILE="$HOME/.health-check-alerts.log"

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

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# Help function
show_help() {
    cat << EOF
System Health Check and Alerting Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --alert                       Enable alerting for issues
    --comprehensive               Run comprehensive health check
    --verbose                     Show detailed information
    --cpu-threshold PCT           CPU usage alert threshold (default: 80%)
    --memory-threshold PCT        Memory usage alert threshold (default: 85%)
    --disk-threshold PCT          Disk usage alert threshold (default: 90%)
    --shell-threshold MS          Shell startup time alert threshold (default: 2000ms)
    --alert-email EMAIL           Send alerts to email address
    --alert-webhook URL           Send alerts to webhook URL
    --help                        Show this help message

EXAMPLES:
    $0                           Basic health check
    $0 --comprehensive           Full system analysis
    $0 --alert --verbose         Alerting mode with details
    $0 --cpu-threshold 70        Alert if CPU usage > 70%

HEALTH CHECKS:
    - System resource usage (CPU, Memory, Disk)
    - Shell startup performance
    - Nix system health
    - Claude configuration status
    - Development tool status
    - Network connectivity
    - Security tool status

ALERTING:
    - Console output with color coding
    - Log file for alert history
    - Email notifications (if configured)
    - Webhook notifications (if configured)
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --alert)
            ALERT_MODE=true
            shift
            ;;
        --comprehensive)
            COMPREHENSIVE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --cpu-threshold)
            ALERT_THRESHOLD_CPU="$2"
            shift 2
            ;;
        --memory-threshold)
            ALERT_THRESHOLD_MEMORY="$2"
            shift 2
            ;;
        --disk-threshold)
            ALERT_THRESHOLD_DISK="$2"
            shift 2
            ;;
        --shell-threshold)
            ALERT_THRESHOLD_SHELL_MS="$2"
            shift 2
            ;;
        --alert-email)
            ALERT_EMAIL="$2"
            shift 2
            ;;
        --alert-webhook)
            ALERT_WEBHOOK="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Alert tracking
ALERTS=()
WARNINGS=()

# Function to add alert
add_alert() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ "$level" == "ERROR" ]]; then
        ALERTS+=("$timestamp: $message")
        log_error "ALERT: $message"
    elif [[ "$level" == "WARNING" ]]; then
        WARNINGS+=("$timestamp: $message")
        log_warning "WARNING: $message"
    fi

    # Log to file if alerting is enabled
    if [[ "$ALERT_MODE" == "true" ]]; then
        echo "$timestamp [$level] $message" >> "$ALERT_LOG_FILE"
    fi
}

# Function to send notifications
send_notifications() {
    if [[ ${#ALERTS[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
        return 0
    fi

    local total_issues=$((${#ALERTS[@]} + ${#WARNINGS[@]}))
    local subject="Health Check Alert: $total_issues issue(s) detected"

    # Create message body
    local message="System health check detected issues:\n\n"

    if [[ ${#ALERTS[@]} -gt 0 ]]; then
        message+="CRITICAL ALERTS:\n"
        for alert in "${ALERTS[@]}"; do
            message+="- $alert\n"
        done
        message+="\n"
    fi

    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        message+="WARNINGS:\n"
        for warning in "${WARNINGS[@]}"; do
            message+="- $warning\n"
        done
        message+="\n"
    fi

    message+="Run './scripts/health-check.sh --comprehensive --verbose' for detailed analysis."

    # Send email notification
    if [[ -n "$ALERT_EMAIL" ]]; then
        if command -v mail >/dev/null 2>&1; then
            echo -e "$message" | mail -s "$subject" "$ALERT_EMAIL" 2>/dev/null || \
                log_warning "Failed to send email alert to $ALERT_EMAIL"
        else
            log_warning "Mail command not available for email alerts"
        fi
    fi

    # Send webhook notification
    if [[ -n "$ALERT_WEBHOOK" ]]; then
        if command -v curl >/dev/null 2>&1; then
            local payload="{\"text\":\"$subject\",\"body\":\"$(echo -e "$message" | sed 's/"/\\"/g')\"}"
            curl -X POST -H "Content-Type: application/json" -d "$payload" "$ALERT_WEBHOOK" >/dev/null 2>&1 || \
                log_warning "Failed to send webhook alert to $ALERT_WEBHOOK"
        else
            log_warning "curl not available for webhook alerts"
        fi
    fi
}

# System resource checks
check_system_resources() {
    log_info "Checking system resources..."

    # CPU usage check
    local cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    if [[ -n "$cpu_usage" ]]; then
        cpu_usage=${cpu_usage%.*}  # Remove decimal part
        log_verbose "CPU usage: ${cpu_usage}%"

        if [[ $cpu_usage -gt $ALERT_THRESHOLD_CPU ]]; then
            add_alert "ERROR" "High CPU usage: ${cpu_usage}% (threshold: ${ALERT_THRESHOLD_CPU}%)"
        elif [[ $cpu_usage -gt $((ALERT_THRESHOLD_CPU - 10)) ]]; then
            add_alert "WARNING" "Elevated CPU usage: ${cpu_usage}%"
        else
            log_success "✓ CPU usage normal: ${cpu_usage}%"
        fi
    else
        add_alert "WARNING" "Could not determine CPU usage"
    fi

    # Memory usage check
    local memory_info=$(vm_stat | grep -E "(free|inactive|active|wired)" | awk '{print $3}' | sed 's/\.//')
    if [[ -n "$memory_info" ]]; then
        # Calculate memory usage (simplified)
        local memory_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//' || echo "unknown")

        if [[ "$memory_pressure" != "unknown" ]]; then
            local memory_used=$((100 - memory_pressure))
            log_verbose "Memory usage: ${memory_used}%"

            if [[ $memory_used -gt $ALERT_THRESHOLD_MEMORY ]]; then
                add_alert "ERROR" "High memory usage: ${memory_used}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
            elif [[ $memory_used -gt $((ALERT_THRESHOLD_MEMORY - 10)) ]]; then
                add_alert "WARNING" "Elevated memory usage: ${memory_used}%"
            else
                log_success "✓ Memory usage normal: ${memory_used}%"
            fi
        else
            # Fallback: check swap usage
            local swap_usage=$(sysctl vm.swapusage | awk '{print $7}' | sed 's/M//' || echo "0")
            if [[ $swap_usage -gt 1000 ]]; then
                add_alert "WARNING" "High swap usage detected: ${swap_usage}MB"
            else
                log_success "✓ Memory status appears normal"
            fi
        fi
    else
        add_alert "WARNING" "Could not determine memory usage"
    fi

    # Disk usage check
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ -n "$disk_usage" ]]; then
        log_verbose "Root disk usage: ${disk_usage}%"

        if [[ $disk_usage -gt $ALERT_THRESHOLD_DISK ]]; then
            add_alert "ERROR" "High disk usage: ${disk_usage}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
        elif [[ $disk_usage -gt $((ALERT_THRESHOLD_DISK - 10)) ]]; then
            add_alert "WARNING" "Elevated disk usage: ${disk_usage}%"
        else
            log_success "✓ Disk usage normal: ${disk_usage}%"
        fi
    else
        add_alert "WARNING" "Could not determine disk usage"
    fi

    # Check Nix store if it exists
    if [[ -d "/nix" ]]; then
        local nix_usage=$(df -h /nix | tail -1 | awk '{print $5}' | sed 's/%//')
        if [[ -n "$nix_usage" ]]; then
            log_verbose "Nix store usage: ${nix_usage}%"

            if [[ $nix_usage -gt $ALERT_THRESHOLD_DISK ]]; then
                add_alert "ERROR" "High Nix store usage: ${nix_usage}%"
            elif [[ $nix_usage -gt $((ALERT_THRESHOLD_DISK - 10)) ]]; then
                add_alert "WARNING" "Elevated Nix store usage: ${nix_usage}%"
            fi
        fi
    fi
}

# Shell performance check
check_shell_performance() {
    log_info "Checking shell performance..."

    local shell_name=$(basename "$SHELL")
    log_verbose "Current shell: $shell_name"

    # Measure shell startup time
    local start_time=$(date +%s%N)
    $SHELL -i -c exit 2>/dev/null || true
    local end_time=$(date +%s%N)

    local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    log_verbose "Shell startup time: ${duration}ms"

    if [[ $duration -gt $ALERT_THRESHOLD_SHELL_MS ]]; then
        add_alert "ERROR" "Slow shell startup: ${duration}ms (threshold: ${ALERT_THRESHOLD_SHELL_MS}ms)"
    elif [[ $duration -gt $((ALERT_THRESHOLD_SHELL_MS / 2)) ]]; then
        add_alert "WARNING" "Elevated shell startup time: ${duration}ms"
    else
        log_success "✓ Shell startup time normal: ${duration}ms"
    fi
}

# Nix system health check
check_nix_health() {
    log_info "Checking Nix system health..."

    if ! command -v nix >/dev/null 2>&1; then
        add_alert "WARNING" "Nix command not found"
        return 1
    fi

    # Check Nix daemon
    if pgrep -f nix-daemon >/dev/null; then
        log_success "✓ Nix daemon running"
    else
        add_alert "ERROR" "Nix daemon not running"
    fi

    # Check Nix configuration
    if nix show-config >/dev/null 2>&1; then
        log_success "✓ Nix configuration valid"
    else
        add_alert "ERROR" "Nix configuration invalid"
    fi

    # Check store integrity (if comprehensive)
    if [[ "$COMPREHENSIVE" == "true" ]]; then
        log_verbose "Running Nix store verification..."
        if timeout 30 nix store verify --all >/dev/null 2>&1; then
            log_success "✓ Nix store integrity verified"
        else
            add_alert "WARNING" "Nix store verification failed or timed out"
        fi
    fi
}

# Claude configuration check
check_claude_health() {
    log_info "Checking Claude configuration..."

    if ! command -v claude >/dev/null 2>&1; then
        add_alert "WARNING" "Claude command not found"
        return 1
    fi

    # Check Claude configuration
    if claude config ls >/dev/null 2>&1; then
        log_success "✓ Claude configuration accessible"
    else
        add_alert "ERROR" "Claude configuration error"
    fi

    # Check configuration file
    if [[ -f "$HOME/.claude.json" ]]; then
        if jq empty "$HOME/.claude.json" >/dev/null 2>&1; then
            log_success "✓ Claude configuration file valid JSON"
        else
            add_alert "ERROR" "Claude configuration file invalid JSON"
        fi
    else
        add_alert "WARNING" "Claude configuration file not found"
    fi
}

# Development tools check
check_dev_tools() {
    log_info "Checking development tools..."

    local tools=("git" "go" "bun" "brew")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_verbose "✓ $tool available"
        else
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        log_success "✓ All expected development tools available"
    else
        add_alert "WARNING" "Missing development tools: ${missing_tools[*]}"
    fi

    # Check Go environment
    if command -v go >/dev/null 2>&1; then
        if go version >/dev/null 2>&1; then
            log_verbose "✓ Go environment functional"
        else
            add_alert "WARNING" "Go environment issue detected"
        fi
    fi

    # Check Homebrew
    if command -v brew >/dev/null 2>&1; then
        if brew --version >/dev/null 2>&1; then
            log_verbose "✓ Homebrew functional"

            # Check for outdated packages (if comprehensive)
            if [[ "$COMPREHENSIVE" == "true" ]]; then
                local outdated_count=$(brew outdated | wc -l | tr -d ' ')
                if [[ $outdated_count -gt 10 ]]; then
                    add_alert "WARNING" "$outdated_count Homebrew packages outdated"
                elif [[ $outdated_count -gt 0 ]]; then
                    log_verbose "$outdated_count Homebrew packages outdated"
                fi
            fi
        else
            add_alert "WARNING" "Homebrew functionality issue detected"
        fi
    fi
}

# Network connectivity check
check_network() {
    if [[ "$COMPREHENSIVE" != "true" ]]; then
        return 0
    fi

    log_info "Checking network connectivity..."

    # Check basic connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "✓ Internet connectivity functional"
    else
        add_alert "ERROR" "No internet connectivity"
    fi

    # Check DNS resolution
    if nslookup github.com >/dev/null 2>&1; then
        log_verbose "✓ DNS resolution working"
    else
        add_alert "WARNING" "DNS resolution issues detected"
    fi

    # Check specific services
    local services=("github.com" "cache.nixos.org" "registry.npmjs.org")
    for service in "${services[@]}"; do
        if curl -s --connect-timeout 5 "https://$service" >/dev/null 2>&1; then
            log_verbose "✓ $service reachable"
        else
            add_alert "WARNING" "$service not reachable"
        fi
    done
}

# Security tools check
check_security_tools() {
    if [[ "$COMPREHENSIVE" != "true" ]]; then
        return 0
    fi

    log_info "Checking security tools..."

    # Check for Little Snitch
    if [[ -d "/Library/Little Snitch" ]]; then
        log_verbose "✓ Little Snitch detected"
    fi

    # Check for Lulu
    if [[ -d "/Applications/LuLu.app" ]]; then
        log_verbose "✓ LuLu detected"
    fi

    # Check for Secretive
    if [[ -d "/Applications/Secretive.app" ]]; then
        log_verbose "✓ Secretive detected"
    fi

    # Check system integrity
    if csrutil status | grep -q "enabled"; then
        log_success "✓ System Integrity Protection enabled"
    else
        add_alert "WARNING" "System Integrity Protection disabled"
    fi
}

# Main health check function
main_health_check() {
    log_info "Starting system health check..."

    if [[ "$ALERT_MODE" == "true" ]]; then
        log_info "Alert mode enabled - issues will be reported"
    fi

    if [[ "$COMPREHENSIVE" == "true" ]]; then
        log_info "Running comprehensive health check..."
    fi

    echo

    # Run health checks
    check_system_resources
    check_shell_performance
    check_nix_health
    check_claude_health
    check_dev_tools
    check_network
    check_security_tools

    echo

    # Summary
    local total_alerts=${#ALERTS[@]}
    local total_warnings=${#WARNINGS[@]}

    if [[ $total_alerts -eq 0 && $total_warnings -eq 0 ]]; then
        log_success "🎉 System health check completed - no issues detected!"
    else
        log_info "Health check completed with $total_alerts alert(s) and $total_warnings warning(s)"

        if [[ "$ALERT_MODE" == "true" ]]; then
            send_notifications
            log_info "Alerts logged to: $ALERT_LOG_FILE"
        fi
    fi

    # Recommendations
    if [[ $total_alerts -gt 0 || $total_warnings -gt 0 ]]; then
        echo
        log_info "Recommendations:"

        if [[ $total_alerts -gt 0 ]]; then
            log_info "  • Address critical alerts immediately"
        fi

        if [[ $total_warnings -gt 0 ]]; then
            log_info "  • Review warnings and consider action"
        fi

        log_info "  • Run './scripts/cleanup.sh' for maintenance"
        log_info "  • Run './scripts/optimize.sh --dry-run' to check optimizations"
        log_info "  • Check troubleshooting guide: docs/troubleshooting/common-issues.md"
    fi
}

# Run main health check
main_health_check "$@"

# Exit with appropriate code
if [[ ${#ALERTS[@]} -gt 0 ]]; then
    exit 1
elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
    exit 2
else
    exit 0
fi