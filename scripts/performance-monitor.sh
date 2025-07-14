#!/bin/bash

# Performance Monitoring System
# Tracks shell startup times, monitors regressions, and manages caching

set -e

# Configuration
MONITOR_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/performance-monitor"
METRICS_FILE="$MONITOR_DIR/metrics.json"
CACHE_DIR="$MONITOR_DIR/cache"
ALERTS_FILE="$MONITOR_DIR/alerts.log"
CONFIG_FILE="$MONITOR_DIR/config.json"

# Performance thresholds (in seconds)
DEFAULT_WARN_THRESHOLD=1.0
DEFAULT_CRITICAL_THRESHOLD=3.0
DEFAULT_REGRESSION_THRESHOLD=50  # 50% increase

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$MONITOR_DIR" "$CACHE_DIR"

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        WARN_THRESHOLD=$(jq -r '.thresholds.warn' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_WARN_THRESHOLD")
        CRITICAL_THRESHOLD=$(jq -r '.thresholds.critical' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_CRITICAL_THRESHOLD")
        REGRESSION_THRESHOLD=$(jq -r '.thresholds.regression_percent' "$CONFIG_FILE" 2>/dev/null || echo "$DEFAULT_REGRESSION_THRESHOLD")
    else
        WARN_THRESHOLD="$DEFAULT_WARN_THRESHOLD"
        CRITICAL_THRESHOLD="$DEFAULT_CRITICAL_THRESHOLD"
        REGRESSION_THRESHOLD="$DEFAULT_REGRESSION_THRESHOLD"
        create_default_config
    fi
}

# Create default configuration
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
{
    "thresholds": {
        "warn": $DEFAULT_WARN_THRESHOLD,
        "critical": $DEFAULT_CRITICAL_THRESHOLD,
        "regression_percent": $DEFAULT_REGRESSION_THRESHOLD
    },
    "monitoring": {
        "enabled": true,
        "auto_benchmark": true,
        "cache_enabled": true,
        "cache_ttl_hours": 24
    },
    "alerts": {
        "enabled": true,
        "log_warnings": true,
        "log_critical": true,
        "log_regressions": true
    }
}
EOF
}

# Log performance metric
log_metric() {
    local metric_type="$1"
    local metric_name="$2"
    local value="$3"
    local context="$4"
    local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    local metric_entry=$(cat << EOF
{
    "timestamp": "$timestamp",
    "type": "$metric_type",
    "name": "$metric_name",
    "value": $value,
    "context": $context,
    "hostname": "$HOSTNAME",
    "user": "$USER"
}
EOF
    )

    echo "$metric_entry" >> "$METRICS_FILE"

    # Keep only last 10000 entries
    if [[ $(wc -l < "$METRICS_FILE") -gt 10000 ]]; then
        tail -10000 "$METRICS_FILE" > "${METRICS_FILE}.tmp"
        mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
    fi
}

# Get baseline performance for comparison
get_baseline() {
    local metric_type="$1"
    local metric_name="$2"
    local days_back="${3:-7}"

    local cutoff_date=$(date -u -d "$days_back days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-${days_back}d +"%Y-%m-%dT%H:%M:%SZ")

    jq -r --arg type "$metric_type" --arg name "$metric_name" --arg cutoff "$cutoff_date" '
        select(.type == $type and .name == $name and .timestamp >= $cutoff) | .value
    ' "$METRICS_FILE" 2>/dev/null | awk '
        { sum += $1; count++ }
        END {
            if (count > 0) print sum/count
            else print "null"
        }
    '
}

# Check for performance regressions
check_regression() {
    local metric_type="$1"
    local metric_name="$2"
    local current_value="$3"

    local baseline=$(get_baseline "$metric_type" "$metric_name" 7)

    if [[ "$baseline" == "null" ]] || [[ "$baseline" == "0" ]]; then
        echo "no_baseline"
        return 0
    fi

    local increase_percent=$(echo "scale=2; (($current_value - $baseline) * 100) / $baseline" | bc -l 2>/dev/null || echo "0")

    if (( $(echo "$increase_percent > $REGRESSION_THRESHOLD" | bc -l) )); then
        echo "regression:$increase_percent"
        return 1
    else
        echo "ok:$increase_percent"
        return 0
    fi
}

# Log alert
log_alert() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    echo "[$timestamp] [$level] $message" >> "$ALERTS_FILE"
    echo -e "${YELLOW}ALERT [$level]: $message${NC}" >&2
}

# Benchmark shell startup and log results
benchmark_startup() {
    local shell="${1:-zsh}"
    local runs="${2:-5}"

    echo -e "${BLUE}Benchmarking $shell startup ($runs runs)...${NC}"

    # Create temporary file for hyperfine output
    local temp_json="/tmp/perf_monitor_$$.json"

    if hyperfine --runs "$runs" --warmup 2 \
        --export-json "$temp_json" \
        "$shell -i -c exit" >/dev/null 2>&1; then

        local mean_time=$(jq -r '.results[0].mean' "$temp_json" 2>/dev/null || echo "0")
        local min_time=$(jq -r '.results[0].min' "$temp_json" 2>/dev/null || echo "0")
        local max_time=$(jq -r '.results[0].max' "$temp_json" 2>/dev/null || echo "0")

        # Log metrics
        log_metric "startup" "$shell" "$mean_time" '{"runs":'$runs',"min":'$min_time',"max":'$max_time'}'

        # Check thresholds
        if (( $(echo "$mean_time > $CRITICAL_THRESHOLD" | bc -l) )); then
            log_alert "CRITICAL" "Shell $shell startup time $mean_time s exceeds critical threshold $CRITICAL_THRESHOLD s"
        elif (( $(echo "$mean_time > $WARN_THRESHOLD" | bc -l) )); then
            log_alert "WARNING" "Shell $shell startup time $mean_time s exceeds warning threshold $WARN_THRESHOLD s"
        fi

        # Check for regression
        local regression_status=$(check_regression "startup" "$shell" "$mean_time")
        if [[ "$regression_status" =~ ^regression: ]]; then
            local percent="${regression_status#regression:}"
            log_alert "REGRESSION" "Shell $shell startup time increased by $percent% (baseline vs current: $(get_baseline "startup" "$shell" 7)s vs ${mean_time}s)"
        fi

        echo -e "${GREEN}✅ $shell: ${mean_time}s (min: ${min_time}s, max: ${max_time}s)${NC}"

        rm -f "$temp_json"
        return 0
    else
        echo -e "${RED}❌ Failed to benchmark $shell${NC}"
        rm -f "$temp_json"
        return 1
    fi
}

# Benchmark multiple shells
benchmark_all_shells() {
    local shells=("zsh" "bash")
    if command -v nu >/dev/null 2>&1; then
        shells+=("nu")
    fi

    echo -e "${CYAN}🏃 Benchmarking all available shells...${NC}"

    for shell in "${shells[@]}"; do
        if command -v "$shell" >/dev/null 2>&1; then
            benchmark_startup "$shell" 5
        else
            echo -e "${YELLOW}⚠️  $shell not available${NC}"
        fi
    done
}

# Cache management functions
cache_get() {
    local key="$1"
    local cache_file="$CACHE_DIR/$key"

    if [[ -f "$cache_file" ]]; then
        local cache_time=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)
        local current_time=$(date +%s)
        local cache_ttl_seconds=$((24 * 3600))  # 24 hours default

        if [[ $((current_time - cache_time)) -lt $cache_ttl_seconds ]]; then
            cat "$cache_file"
            return 0
        else
            rm -f "$cache_file"
        fi
    fi

    return 1
}

cache_set() {
    local key="$1"
    local value="$2"
    local cache_file="$CACHE_DIR/$key"

    echo "$value" > "$cache_file"
}

cache_invalidate() {
    local pattern="${1:-*}"
    find "$CACHE_DIR" -name "$pattern" -delete 2>/dev/null
    echo -e "${GREEN}✅ Cache entries matching '$pattern' invalidated${NC}"
}

# Generate performance report
generate_report() {
    local days="${1:-7}"

    echo -e "${CYAN}📊 Performance Report (last $days days)${NC}"
    echo

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo -e "${RED}No performance data found${NC}"
        return 1
    fi

    local cutoff_date=$(date -u -d "$days days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ")

    # Shell startup times
    echo -e "${PURPLE}Shell Startup Performance:${NC}"
    local shells=($(jq -r --arg cutoff "$cutoff_date" 'select(.type == "startup" and .timestamp >= $cutoff) | .name' "$METRICS_FILE" 2>/dev/null | sort -u))

    for shell in "${shells[@]}"; do
        local avg_time=$(jq -r --arg shell "$shell" --arg cutoff "$cutoff_date" '
            select(.type == "startup" and .name == $shell and .timestamp >= $cutoff) | .value
        ' "$METRICS_FILE" 2>/dev/null | awk '{ sum += $1; count++ } END { if (count > 0) print sum/count; else print "0" }')

        local count=$(jq -r --arg shell "$shell" --arg cutoff "$cutoff_date" '
            select(.type == "startup" and .name == $shell and .timestamp >= $cutoff)
        ' "$METRICS_FILE" 2>/dev/null | wc -l)

        if [[ "$count" -gt 0 ]]; then
            printf "  %-10s: %.3fs (avg of %d measurements)\n" "$shell" "$avg_time" "$count"

            # Check current status
            if (( $(echo "$avg_time > $CRITICAL_THRESHOLD" | bc -l) )); then
                echo "               🔴 CRITICAL - exceeds threshold"
            elif (( $(echo "$avg_time > $WARN_THRESHOLD" | bc -l) )); then
                echo "               🟡 WARNING - exceeds threshold"
            else
                echo "               🟢 OK"
            fi
        fi
    done

    # Recent alerts
    echo -e "\n${PURPLE}Recent Alerts:${NC}"
    if [[ -f "$ALERTS_FILE" ]]; then
        tail -10 "$ALERTS_FILE" | while read -r line; do
            echo "  $line"
        done
    else
        echo "  No alerts"
    fi

    # Cache statistics
    echo -e "\n${PURPLE}Cache Statistics:${NC}"
    local cache_files=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l)
    local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
    echo "  Cached entries: $cache_files"
    echo "  Cache size: $cache_size"
}

# Automated monitoring setup
setup_monitoring() {
    echo -e "${CYAN}🔧 Setting up performance monitoring...${NC}"

    # Create monitoring hook for zsh
    local hook_file="$MONITOR_DIR/monitoring-hook.zsh"
    cat > "$hook_file" << 'EOF'
# Performance monitoring hook for zsh
# Automatically tracks shell startup times

if [[ -n "$ZSH_PERF_MONITOR" ]] && [[ $- == *i* ]]; then
    _perf_monitor_startup_time=${_perf_monitor_startup_time:-$(date +%s%3N)}

    # Log startup time after shell is fully loaded
    _perf_monitor_log_startup() {
        local end_time=$(date +%s%3N)
        local startup_duration=$(( (end_time - _perf_monitor_startup_time) / 1000 ))

        # Log to performance monitor (async to avoid impacting startup)
        (
            echo "{\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",\"type\":\"startup\",\"name\":\"zsh\",\"value\":$startup_duration,\"context\":{\"auto\":true},\"hostname\":\"$HOSTNAME\",\"user\":\"$USER\"}" >> "${XDG_CACHE_HOME:-$HOME/.cache}/performance-monitor/metrics.json"
        ) &
    }

    # Schedule logging after prompt is ready
    autoload -U add-zsh-hook
    add-zsh-hook precmd _perf_monitor_log_startup
fi
EOF

    echo -e "${GREEN}✅ Monitoring hook created: $hook_file${NC}"
    echo "Add this to your .zshrc to enable automatic monitoring:"
    echo "  export ZSH_PERF_MONITOR=1"
    echo "  source \"$hook_file\""
}

# Show help
show_help() {
    echo "Performance Monitoring System"
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  benchmark [SHELL] [RUNS]    Benchmark shell startup (default: zsh, 5 runs)"
    echo "  benchmark-all               Benchmark all available shells"
    echo "  report [DAYS]               Generate performance report (default: 7 days)"
    echo "  setup-monitoring            Setup automatic monitoring"
    echo "  cache-clear [PATTERN]       Clear cache entries (default: all)"
    echo "  config                      Show current configuration"
    echo "  alerts                      Show recent alerts"
    echo "  help                        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 benchmark zsh 10         # Benchmark zsh with 10 runs"
    echo "  $0 benchmark-all             # Benchmark all shells"
    echo "  $0 report 14                 # 14-day performance report"
    echo "  $0 cache-clear 'startup_*'   # Clear startup cache entries"
}

# Load configuration
load_config

# Main execution
case "${1:-help}" in
    "benchmark")
        benchmark_startup "${2:-zsh}" "${3:-5}"
        ;;
    "benchmark-all")
        benchmark_all_shells
        ;;
    "report")
        generate_report "${2:-7}"
        ;;
    "setup-monitoring"|"setup")
        setup_monitoring
        ;;
    "cache-clear"|"cache-clean")
        cache_invalidate "${2:-*}"
        ;;
    "config")
        echo -e "${CYAN}Current Configuration:${NC}"
        cat "$CONFIG_FILE" | jq . 2>/dev/null || cat "$CONFIG_FILE"
        ;;
    "alerts")
        echo -e "${CYAN}Recent Alerts:${NC}"
        if [[ -f "$ALERTS_FILE" ]]; then
            tail -20 "$ALERTS_FILE"
        else
            echo "No alerts found"
        fi
        ;;
    "help"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac