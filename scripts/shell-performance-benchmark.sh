#!/bin/bash

# Shell Performance Diagnostic and Benchmark Script
# Runs 10 iterations to get reliable performance data
# Enhanced with JSON storage, git tracking, and trend analysis

set -euo pipefail

# Configuration
BENCHMARK_DIR="./performance-data"
BENCHMARK_FILE="${BENCHMARK_DIR}/shell-performance.json"
WARMUP_RUNS=3
TEST_RUNS=10
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

echo "🔍 Shell Performance Diagnostic and Benchmark"
echo "============================================="
echo

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

# Function to setup performance data directory
setup_performance_data() {
    mkdir -p "${BENCHMARK_DIR}"
    log "Performance data directory: ${BENCHMARK_DIR}"
}

# Function to save benchmark result as JSON
save_benchmark_result() {
    local shell_name="$1"
    local shell_path="$2"
    local mean_time="$3"
    local stddev="$4"
    local min_time="$5"
    local max_time="$6"

    # Convert to milliseconds
    local mean_ms=$(echo "$mean_time * 1000" | bc -l)
    local stddev_ms=$(echo "$stddev * 1000" | bc -l)
    local min_ms=$(echo "$min_time * 1000" | bc -l)
    local max_ms=$(echo "$max_time * 1000" | bc -l)

    # Create JSON result
    local result_json=$(cat << EOF
{
  "timestamp": "$TIMESTAMP",
  "git_commit": "$GIT_COMMIT",
  "git_branch": "$GIT_BRANCH",
  "shell": {
    "name": "$shell_name",
    "path": "$shell_path"
  },
  "performance": {
    "mean_seconds": $mean_time,
    "mean_ms": $mean_ms,
    "stddev_seconds": $stddev,
    "stddev_ms": $stddev_ms,
    "min_seconds": $min_time,
    "min_ms": $min_ms,
    "max_seconds": $max_time,
    "max_ms": $max_ms
  },
  "test_config": {
    "warmup_runs": $WARMUP_RUNS,
    "test_runs": $TEST_RUNS
  }
}
EOF
)

    # Save to benchmark file
    if [[ -f "$BENCHMARK_FILE" ]]; then
        # Append to existing results
        local temp_file=$(mktemp)
        if command -v jq &> /dev/null; then
            jq --argjson new_result "$result_json" '. += [$new_result]' "$BENCHMARK_FILE" > "$temp_file"
        else
            # Fallback: manually append to JSON array
            sed '$ s/]/,' "$BENCHMARK_FILE" > "$temp_file"
            echo "$result_json" >> "$temp_file"
            echo "]" >> "$temp_file"
        fi
        mv "$temp_file" "$BENCHMARK_FILE"
    else
        # Create new results file
        echo "[$result_json]" > "$BENCHMARK_FILE"
    fi

    log "Performance data saved for $shell_name"
}

# Function to analyze performance trends
analyze_performance_trends() {
    if [[ ! -f "$BENCHMARK_FILE" ]]; then
        echo "No historical performance data available"
        return
    fi

    print_header "Performance Trend Analysis"

    if command -v jq &> /dev/null; then
        # Show last 5 results for each shell
        local shells
        shells=$(jq -r '.[].shell.name' "$BENCHMARK_FILE" | sort -u)

        for shell in $shells; do
            echo ""
            echo -e "${YELLOW}=== $shell Performance History (Last 5 runs) ===${NC}"
            jq -r --arg shell "$shell" '
                [.[] | select(.shell.name == $shell)] |
                sort_by(.timestamp) |
                .[-5:] |
                .[] |
                "\(.timestamp): \(.performance.mean_ms | tonumber | floor)ms (±\(.performance.stddev_ms | tonumber | floor)ms) [\(.git_commit[0:7])]"
            ' "$BENCHMARK_FILE"

            # Calculate regression/improvement
            local latest_performance
            latest_performance=$(jq -r --arg shell "$shell" '
                [.[] | select(.shell.name == $shell)] |
                sort_by(.timestamp) |
                .[-1].performance.mean_ms
            ' "$BENCHMARK_FILE")

            local previous_performance
            previous_performance=$(jq -r --arg shell "$shell" '
                [.[] | select(.shell.name == $shell)] |
                sort_by(.timestamp) |
                .[-2].performance.mean_ms // null
            ' "$BENCHMARK_FILE")

            if [[ "$previous_performance" != "null" ]] && [[ -n "$previous_performance" ]]; then
                local change_percent
                change_percent=$(echo "scale=1; ($latest_performance - $previous_performance) / $previous_performance * 100" | bc -l)

                if (( $(echo "$change_percent > 20" | bc -l) )); then
                    echo -e "${RED}⚠️  Performance regression: +${change_percent}%${NC}"
                elif (( $(echo "$change_percent < -20" | bc -l) )); then
                    echo -e "${GREEN}🚀 Performance improvement: ${change_percent}%${NC}"
                else
                    echo -e "${GREEN}✅ Performance stable: ${change_percent}%${NC}"
                fi
            fi
        done
    else
        echo "Install jq for detailed trend analysis"
    fi
    echo
}

# Function to check if a shell exists
shell_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get shell config file
get_config_file() {
    case "$1" in
        zsh) echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *) echo "unknown" ;;
    esac
}

# Check system info
print_header "System Information"
echo "OS: $(uname -s) $(uname -r)"
echo "Current Shell: $SHELL"
echo "Terminal: $TERM"
echo

# Setup performance data tracking
setup_performance_data

# Check available shells
print_header "Available Shells"
SHELLS=()
# Shell paths
FISH_PATH="/run/current-system/sw/bin/fish"
ZSH_PATH="/run/current-system/sw/bin/zsh"
BASH_PATH="/bin/bash"

for shell_name in fish zsh bash; do
    case "$shell_name" in
        fish) shell_path="$FISH_PATH" ;;
        zsh) shell_path="$ZSH_PATH" ;;
        bash) shell_path="$BASH_PATH" ;;
    esac
    if [[ -x "$shell_path" ]]; then
        version=$($shell_path --version 2>/dev/null | head -n1 || echo "Unknown version")
        echo "✅ $shell_name: $version (at $shell_path)"
        SHELLS+=("$shell_name")
    else
        echo "❌ $shell_name: Not available at $shell_path"
    fi
done
echo

# Run hyperfine benchmarks for each available shell
print_header "Hyperfine Benchmarks (10 runs each)"
echo

for shell in "${SHELLS[@]}"; do
    case "$shell" in
        fish) shell_path="$FISH_PATH" ;;
        zsh) shell_path="$ZSH_PATH" ;;
        bash) shell_path="$BASH_PATH" ;;
    esac
    config_file=$(get_config_file "$shell")

    echo -e "${YELLOW}Testing $shell startup time...${NC}"

    if [[ -f "$config_file" ]]; then
        echo "Config file: $config_file ($(wc -l < "$config_file") lines)"
    else
        echo "Config file: $config_file (not found)"
    fi

    # Run hyperfine benchmark with JSON output
    json_output_file="/tmp/${shell}_benchmark.json"
    if hyperfine --runs "$TEST_RUNS" --warmup "$WARMUP_RUNS" \
        --export-markdown "/tmp/${shell}_benchmark.md" \
        --export-json "$json_output_file" \
        "$shell_path -c exit" \
        --show-output; then

        # Extract performance metrics and save to our tracking system
        if [[ -f "$json_output_file" ]] && command -v jq &> /dev/null; then
            mean_time=$(jq -r '.results[0].mean' "$json_output_file")
            stddev=$(jq -r '.results[0].stddev' "$json_output_file")
            min_time=$(jq -r '.results[0].min' "$json_output_file")
            max_time=$(jq -r '.results[0].max' "$json_output_file")

            # Save to our performance tracking system
            save_benchmark_result "$shell" "$shell_path" "$mean_time" "$stddev" "$min_time" "$max_time"
        else
            echo -e "${YELLOW}Could not extract performance data for $shell${NC}"
        fi
    else
        echo -e "${RED}Failed to benchmark $shell${NC}"
    fi

    echo
done

# Manual timing tests for comparison
print_header "Manual Timing Tests (for comparison)"
echo

for shell in "${SHELLS[@]}"; do
    case "$shell" in
        fish) shell_path="$FISH_PATH" ;;
        zsh) shell_path="$ZSH_PATH" ;;
        bash) shell_path="$BASH_PATH" ;;
    esac
    echo -e "${YELLOW}Manual timing for $shell (5 runs):${NC}"

    total_time=0
    for i in {1..5}; do
        start_time=$(date +%s%N)
        "$shell_path" -c exit 2>/dev/null || echo "Error running $shell"
        end_time=$(date +%s%N)

        duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        echo "Run $i: ${duration}ms"
        total_time=$(( total_time + duration ))
    done

    avg_time=$(( total_time / 5 ))
    echo -e "${GREEN}Average: ${avg_time}ms${NC}"
    echo
done

# Analyze performance trends
analyze_performance_trends

# Check for common performance issues
print_header "Performance Analysis"
echo

current_shell=$(basename "$SHELL")
config_file=$(get_config_file "$current_shell")

if [[ -f "$config_file" ]]; then
    echo -e "${YELLOW}Analyzing $config_file for common performance issues:${NC}"

    # Check for Oh-My-Zsh
    if grep -q "oh-my-zsh" "$config_file" 2>/dev/null; then
        echo "⚠️  Oh-My-Zsh detected - may impact startup time"

        # Count plugins
        plugin_count=$(grep -o 'plugins=([^)]*)' "$config_file" 2>/dev/null | sed 's/plugins=(\([^)]*\))/\1/' | tr ' ' '\n' | wc -l || echo "0")
        echo "   Plugins found: $plugin_count"
    fi

    # Check for Powerlevel10k
    if grep -q "powerlevel10k" "$config_file" 2>/dev/null; then
        echo "✅ Powerlevel10k detected - generally fast"
    fi

    # Check for Starship
    if grep -q "starship" "$config_file" 2>/dev/null; then
        echo "✅ Starship detected - cross-shell prompt"
    fi

    # Check for nvm
    if grep -q "nvm" "$config_file" 2>/dev/null; then
        echo "⚠️  NVM detected - consider lazy loading"
    fi

    # Check for rbenv/rvm
    if grep -qE "(rbenv|rvm)" "$config_file" 2>/dev/null; then
        echo "⚠️  Ruby version manager detected - consider lazy loading"
    fi

    # Check for pyenv
    if grep -q "pyenv" "$config_file" 2>/dev/null; then
        echo "⚠️  Pyenv detected - consider lazy loading"
    fi

    # Check config file size
    line_count=$(wc -l < "$config_file")
    if [[ $line_count -gt 100 ]]; then
        echo "⚠️  Large config file ($line_count lines) - consider cleanup"
    else
        echo "✅ Config file size is reasonable ($line_count lines)"
    fi
else
    echo "No config file found for $current_shell"
fi

echo

# Recommendations
print_header "Recommendations"
echo -e "${GREEN}To improve startup performance:${NC}"
echo "1. Enable zsh profiling: add 'zmodload zsh/zprof' to top of .zshrc"
echo "2. Use lazy loading for version managers (nvm, rbenv, pyenv)"
echo "3. Minimize Oh-My-Zsh plugins or switch to faster alternatives"
echo "4. Consider Powerlevel10k instant prompt feature"
echo "5. Run 'zprof' command after reloading shell to see detailed timing"
echo

echo -e "${BLUE}Benchmark complete! Check /tmp/*_benchmark.* for detailed results.${NC}"