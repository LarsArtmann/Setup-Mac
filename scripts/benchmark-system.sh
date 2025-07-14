#!/bin/bash

# Improved System Performance Benchmark Script
# Automated monitoring for shell startup, build tools, and system performance

set -e

# Configuration
BENCHMARK_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/benchmarks"
RESULTS_FILE="$BENCHMARK_DIR/results.json"
LOG_FILE="$BENCHMARK_DIR/benchmark.log"
MAX_HISTORY=50  # Keep last 50 benchmark runs

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure benchmark directory exists
mkdir -p "$BENCHMARK_DIR"

# Function to print section headers
print_header() {
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

# Function to log results
log_result() {
    local category="$1"
    local test="$2"
    local result="$3"
    local timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    echo "{\"timestamp\":\"$timestamp\",\"category\":\"$category\",\"test\":\"$test\",\"result\":$result}" >> "$RESULTS_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to extract numeric value from hyperfine output
extract_time() {
    echo "$1" | grep -o '[0-9.]\+' | head -1
}

# Function to benchmark shell startup
benchmark_shells() {
    print_header "Shell Startup Performance"

    local shells=("zsh" "bash")
    if command_exists "nu"; then
        shells+=("nu")
    fi

    for shell in "${shells[@]}"; do
        if command_exists "$shell"; then
            echo -e "${YELLOW}Benchmarking $shell startup...${NC}"

            # Create temporary hyperfine output file
            local temp_json="/tmp/hyperfine_${shell}_$$.json"

            if hyperfine --runs 5 --warmup 2 \
                --export-json "$temp_json" \
                "$shell -i -c exit" 2>/dev/null; then

                # Extract mean time from JSON
                local mean_time=$(jq -r '.results[0].mean' "$temp_json" 2>/dev/null || echo "0")
                echo -e "${GREEN}✅ $shell: ${mean_time}s${NC}"

                # Log result
                log_result "shell" "$shell" "$mean_time"
            else
                echo -e "${RED}❌ Failed to benchmark $shell${NC}"
                log_result "shell" "$shell" "null"
            fi

            # Cleanup temp file
            rm -f "$temp_json"
        fi
    done
}

# Function to benchmark build tools
benchmark_build_tools() {
    print_header "Build Tools Performance"

    # Test bun vs npm vs yarn if available
    local package_managers=()
    command_exists "bun" && package_managers+=("bun")
    command_exists "npm" && package_managers+=("npm")
    command_exists "yarn" && package_managers+=("yarn")
    command_exists "pnpm" && package_managers+=("pnpm")

    if [ ${#package_managers[@]} -gt 0 ]; then
        echo -e "${YELLOW}Benchmarking package managers (version check)...${NC}"

        # Create commands array for hyperfine
        local commands=()
        for pm in "${package_managers[@]}"; do
            commands+=("$pm --version")
        done

        # Run benchmark if we have multiple package managers to compare
        if [ ${#commands[@]} -gt 1 ]; then
            local temp_json="/tmp/hyperfine_pm_$$.json"
            if hyperfine --runs 3 --warmup 1 \
                --export-json "$temp_json" \
                "${commands[@]}" 2>/dev/null; then

                # Extract results for each package manager
                local i=0
                for pm in "${package_managers[@]}"; do
                    local mean_time=$(jq -r ".results[$i].mean" "$temp_json" 2>/dev/null || echo "0")
                    echo -e "${GREEN}✅ $pm: ${mean_time}s${NC}"
                    log_result "package_manager" "$pm" "$mean_time"
                    ((i++))
                done
            else
                echo -e "${RED}❌ Failed to benchmark package managers${NC}"
            fi
            rm -f "$temp_json"
        fi
    fi

    # Test Go build tools
    if command_exists "go"; then
        echo -e "${YELLOW}Benchmarking Go tools...${NC}"

        # Test go version
        local temp_json="/tmp/hyperfine_go_$$.json"
        if hyperfine --runs 3 --warmup 1 \
            --export-json "$temp_json" \
            "go version" 2>/dev/null; then

            local mean_time=$(jq -r '.results[0].mean' "$temp_json" 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ go version: ${mean_time}s${NC}"
            log_result "go_tools" "version" "$mean_time"
        fi
        rm -f "$temp_json"
    fi
}

# Function to benchmark system commands
benchmark_system_commands() {
    print_header "System Commands Performance"

    local commands=(
        "ls /usr/bin"
        "find /usr/bin -maxdepth 1 -type f | wc -l"
        "git status --porcelain"
    )

    for cmd in "${commands[@]}"; do
        echo -e "${YELLOW}Benchmarking: $cmd${NC}"

        local temp_json="/tmp/hyperfine_sys_$$.json"
        local cmd_name=$(echo "$cmd" | awk '{print $1}')

        if hyperfine --runs 3 --warmup 1 \
            --export-json "$temp_json" \
            "$cmd" 2>/dev/null; then

            local mean_time=$(jq -r '.results[0].mean' "$temp_json" 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ $cmd_name: ${mean_time}s${NC}"
            log_result "system" "$cmd_name" "$mean_time"
        else
            echo -e "${RED}❌ Failed to benchmark: $cmd${NC}"
            log_result "system" "$cmd_name" "null"
        fi

        rm -f "$temp_json"
    done
}

# Function to benchmark file operations
benchmark_file_operations() {
    print_header "File Operations Performance"

    local test_dir="/tmp/benchmark_test_$$"
    mkdir -p "$test_dir"

    # Create test files
    echo -e "${YELLOW}Creating test files...${NC}"
    for i in {1..100}; do
        echo "test file $i" > "$test_dir/file_$i.txt"
    done

    # Benchmark file operations
    local operations=(
        "ls $test_dir"
        "find $test_dir -name '*.txt'"
        "grep -r 'test' $test_dir"
    )

    for op in "${operations[@]}"; do
        echo -e "${YELLOW}Benchmarking: $(echo "$op" | awk '{print $1}')${NC}"

        local temp_json="/tmp/hyperfine_file_$$.json"
        local op_name=$(echo "$op" | awk '{print $1}')

        if hyperfine --runs 5 --warmup 1 \
            --export-json "$temp_json" \
            "$op" 2>/dev/null; then

            local mean_time=$(jq -r '.results[0].mean' "$temp_json" 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ $op_name: ${mean_time}s${NC}"
            log_result "file_ops" "$op_name" "$mean_time"
        else
            echo -e "${RED}❌ Failed to benchmark: $op_name${NC}"
            log_result "file_ops" "$op_name" "null"
        fi

        rm -f "$temp_json"
    done

    # Cleanup test files
    rm -rf "$test_dir"
}

# Function to generate performance report
generate_report() {
    print_header "Performance Summary"

    if [ ! -f "$RESULTS_FILE" ]; then
        echo -e "${RED}No benchmark results found${NC}"
        return 1
    fi

    # Show recent results grouped by category
    echo -e "${CYAN}Recent benchmark results:${NC}"

    local categories=("shell" "package_manager" "go_tools" "system" "file_ops")

    for category in "${categories[@]}"; do
        echo -e "\n${PURPLE}$category:${NC}"

        # Get latest results for this category
        jq -r --arg cat "$category" '
            select(.category == $cat) |
            "\(.test): \(.result)s (\(.timestamp | strftime("%H:%M:%S")))"
        ' "$RESULTS_FILE" 2>/dev/null | tail -5 | while read -r line; do
            echo "  $line"
        done
    done

    # Show trends if we have enough data
    echo -e "\n${CYAN}Performance trends:${NC}"

    # Calculate shell startup trend (last 10 runs)
    local shell_trend=$(jq -r '
        select(.category == "shell" and .test == "zsh") | .result
    ' "$RESULTS_FILE" 2>/dev/null | tail -10 | awk '
        BEGIN { sum=0; count=0; prev=0 }
        {
            if (NR > 1 && prev > 0) {
                diff = $1 - prev
                sum += diff
                count++
            }
            prev = $1
        }
        END {
            if (count > 0) {
                avg_change = sum / count
                if (avg_change > 0.001) print "📈 Getting slower"
                else if (avg_change < -0.001) print "📉 Getting faster"
                else print "➡️  Stable"
            } else {
                print "📊 Need more data"
            }
        }
    ')

    echo "  Shell startup: $shell_trend"
}

# Function to clean old results
cleanup_old_results() {
    if [ -f "$RESULTS_FILE" ]; then
        # Keep only last MAX_HISTORY entries
        local temp_file="/tmp/benchmark_cleanup_$$.json"
        tail -n "$MAX_HISTORY" "$RESULTS_FILE" > "$temp_file"
        mv "$temp_file" "$RESULTS_FILE"
    fi
}

# Function to show help
show_help() {
    echo "System Performance Benchmark Script"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --shells          Benchmark shell startup only"
    echo "  --build-tools     Benchmark build tools only"
    echo "  --system          Benchmark system commands only"
    echo "  --file-ops        Benchmark file operations only"
    echo "  --report          Show performance report only"
    echo "  --cleanup         Clean old benchmark results"
    echo "  --help            Show this help message"
    echo ""
    echo "Without options, runs all benchmarks"
}

# Main execution
main() {
    echo -e "${CYAN}🚀 System Performance Benchmark${NC}"
    echo -e "${CYAN}Results saved to: $RESULTS_FILE${NC}"
    echo ""

    # Parse command line arguments
    case "${1:-all}" in
        "--shells")
            benchmark_shells
            ;;
        "--build-tools")
            benchmark_build_tools
            ;;
        "--system")
            benchmark_system_commands
            ;;
        "--file-ops")
            benchmark_file_operations
            ;;
        "--report")
            generate_report
            ;;
        "--cleanup")
            cleanup_old_results
            echo -e "${GREEN}✅ Old benchmark results cleaned${NC}"
            ;;
        "--help")
            show_help
            ;;
        "all"|*)
            benchmark_shells
            benchmark_build_tools
            benchmark_system_commands
            benchmark_file_operations
            generate_report
            cleanup_old_results
            ;;
    esac

    echo ""
    echo -e "${BLUE}📊 Benchmark complete!${NC}"
    echo -e "${BLUE}View detailed results: cat $RESULTS_FILE${NC}"
    echo -e "${BLUE}View logs: cat $LOG_FILE${NC}"
}

# Check prerequisites
if ! command_exists "hyperfine"; then
    echo -e "${RED}❌ hyperfine is required but not installed${NC}"
    echo "Install with: brew install hyperfine"
    exit 1
fi

if ! command_exists "jq"; then
    echo -e "${RED}❌ jq is required but not installed${NC}"
    echo "Install with: brew install jq"
    exit 1
fi

# Log this run
echo "$(date): Starting benchmark run with args: $*" >> "$LOG_FILE"

# Run main function
main "$@"