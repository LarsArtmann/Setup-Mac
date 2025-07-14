#!/bin/bash

# Shell Performance Diagnostic and Benchmark Script
# Runs 10 iterations to get reliable performance data

set -e

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

# Function to check if a shell exists
shell_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get shell config file
get_config_file() {
    case "$1" in
        zsh) echo "$HOME/.zshrc" ;;
        bash) echo "$HOME/.bashrc" ;;
        *) echo "unknown" ;;
    esac
}

# Check system info
print_header "System Information"
echo "OS: $(uname -s) $(uname -r)"
echo "Current Shell: $SHELL"
echo "Terminal: $TERM"
echo

# Check available shells
print_header "Available Shells"
SHELLS=()
for shell in zsh bash; do
    if shell_exists "$shell"; then
        version=$($shell --version 2>/dev/null | head -n1 || echo "Unknown version")
        echo "✅ $shell: $version"
        SHELLS+=("$shell")
    else
        echo "❌ $shell: Not available"
    fi
done
echo

# Run hyperfine benchmarks for each available shell
print_header "Hyperfine Benchmarks (10 runs each)"
echo

for shell in "${SHELLS[@]}"; do
    config_file=$(get_config_file "$shell")

    echo -e "${YELLOW}Testing $shell startup time...${NC}"

    if [[ -f "$config_file" ]]; then
        echo "Config file: $config_file ($(wc -l < "$config_file") lines)"
    else
        echo "Config file: $config_file (not found)"
    fi

    # Run hyperfine benchmark
    hyperfine --runs 10 --warmup 2 \
        --export-markdown "/tmp/${shell}_benchmark.md" \
        --export-json "/tmp/${shell}_benchmark.json" \
        "$shell -i -c exit" \
        --show-output || echo -e "${RED}Failed to benchmark $shell${NC}"

    echo
done

# Manual timing tests for comparison
print_header "Manual Timing Tests (for comparison)"
echo

for shell in "${SHELLS[@]}"; do
    echo -e "${YELLOW}Manual timing for $shell (5 runs):${NC}"

    total_time=0
    for i in {1..5}; do
        start_time=$(date +%s%N)
        $shell -i -c exit 2>/dev/null || echo "Error running $shell"
        end_time=$(date +%s%N)

        duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        echo "Run $i: ${duration}ms"
        total_time=$(( total_time + duration ))
    done

    avg_time=$(( total_time / 5 ))
    echo -e "${GREEN}Average: ${avg_time}ms${NC}"
    echo
done

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