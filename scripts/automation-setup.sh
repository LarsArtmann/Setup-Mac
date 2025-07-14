#!/bin/bash

# Automation Setup Script
# Sets up all GROUP 4 automation and monitoring tools

set -e

# Configuration
SETUP_DIR="/Users/larsartmann/Desktop/Setup-Mac"
SCRIPTS_DIR="$SETUP_DIR/scripts"
DOTFILES_DIR="$SETUP_DIR/dotfiles"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to print section headers
print_header() {
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing_tools=()

    if ! command_exists "hyperfine"; then
        missing_tools+=("hyperfine")
    fi

    if ! command_exists "jq"; then
        missing_tools+=("jq")
    fi

    if ! command_exists "bc"; then
        missing_tools+=("bc")
    fi

    if ! command_exists "just"; then
        missing_tools+=("just")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
        echo "Install missing tools and run this script again."
        exit 1
    fi

    echo -e "${GREEN}✅ All prerequisites satisfied${NC}"
}

# Function to setup directory structure
setup_directories() {
    print_header "Setting Up Directory Structure"

    local dirs=(
        "${XDG_CACHE_HOME:-$HOME/.cache}/benchmarks"
        "${XDG_CACHE_HOME:-$HOME/.cache}/shell-context"
        "${XDG_CACHE_HOME:-$HOME/.cache}/performance-monitor"
        "${XDG_CACHE_HOME:-$HOME/.cache}/zsh-lazy-loader"
        "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        echo "  Created: $dir"
    done

    echo -e "${GREEN}✅ Directory structure created${NC}"
}

# Function to setup performance monitoring
setup_performance_monitoring() {
    print_header "Setting Up Performance Monitoring"

    # Initialize performance monitoring
    "$SCRIPTS_DIR/performance-monitor.sh" setup-monitoring

    # Create initial configuration
    local config_file="${XDG_CACHE_HOME:-$HOME/.cache}/performance-monitor/config.json"
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << 'EOF'
{
    "thresholds": {
        "warn": 1.0,
        "critical": 3.0,
        "regression_percent": 30
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
        echo "  Created performance monitoring configuration"
    fi

    echo -e "${GREEN}✅ Performance monitoring setup complete${NC}"
}

# Function to setup context detection
setup_context_detection() {
    print_header "Setting Up Context Detection"

    # Create context-aware loading hook
    "$SCRIPTS_DIR/shell-context-detector.sh" create-hook

    # Log initial session for baseline
    "$SCRIPTS_DIR/shell-context-detector.sh" log

    echo -e "${GREEN}✅ Context detection setup complete${NC}"
}

# Function to setup benchmark automation
setup_benchmark_automation() {
    print_header "Setting Up Benchmark Automation"

    # Run initial benchmark to establish baseline
    echo "Running initial benchmarks to establish baseline..."
    "$SCRIPTS_DIR/benchmark-system.sh" --shells

    # Create benchmark schedule reminder
    local schedule_file="${XDG_CACHE_HOME:-$HOME/.cache}/benchmarks/schedule.txt"
    cat > "$schedule_file" << 'EOF'
Benchmark Schedule Recommendations:
===================================

Daily (automated):
- Shell startup monitoring (via performance monitoring hooks)

Weekly (manual):
- just benchmark-all           # Full system benchmark
- just perf-report 7           # Weekly performance report

Monthly (manual):
- just perf-full-analysis      # Comprehensive analysis
- just context-analyze         # Usage pattern analysis
- just context-recommend       # Get optimization recommendations

Emergency (when performance issues):
- just benchmark-shells        # Quick shell startup check
- just perf-alerts            # Check for performance alerts
- just context-detect         # Check current context

Setup automation:
- Add to .zshrc: export ZSH_PERF_MONITOR=1
- Add to .zshrc: source "${XDG_CACHE_HOME:-$HOME/.cache}/performance-monitor/monitoring-hook.zsh"
- Add to .zshrc: source "${XDG_CACHE_HOME:-$HOME/.cache}/shell-context/loading-hook.zsh"
EOF

    echo "  Created benchmark schedule: $schedule_file"
    echo -e "${GREEN}✅ Benchmark automation setup complete${NC}"
}

# Function to integrate with existing shell configuration
integrate_shell_config() {
    print_header "Integrating with Shell Configuration"

    local zshrc_file="$DOTFILES_DIR/.zshrc"
    local optimized_zshrc="$DOTFILES_DIR/.zshrc.optimized"

    # Backup existing .zshrc
    if [[ -f "$zshrc_file" ]] && [[ ! -f "$zshrc_file.pre-automation-backup" ]]; then
        cp "$zshrc_file" "$zshrc_file.pre-automation-backup"
        echo "  Backed up existing .zshrc to .zshrc.pre-automation-backup"
    fi

    # Create integration snippet
    local integration_snippet="$DOTFILES_DIR/.zshrc.automation-integration"
    cat > "$integration_snippet" << 'EOF'
# Automation and Monitoring Integration
# Add this to your .zshrc to enable all GROUP 4 automation features

# Enable performance monitoring
export ZSH_PERF_MONITOR=1

# Load context detection and smart loading
if [[ -f "${XDG_CACHE_HOME:-$HOME/.cache}/shell-context/loading-hook.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/shell-context/loading-hook.zsh"
fi

# Load performance monitoring hooks
if [[ -f "${XDG_CACHE_HOME:-$HOME/.cache}/performance-monitor/monitoring-hook.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/performance-monitor/monitoring-hook.zsh"
fi

# Load lazy loading system (optional - for advanced users)
# if [[ -f "/Users/larsartmann/Desktop/Setup-Mac/scripts/plugin-lazy-loader.zsh" ]]; then
#     source "/Users/larsartmann/Desktop/Setup-Mac/scripts/plugin-lazy-loader.zsh"
# fi
EOF

    echo "  Created integration snippet: $integration_snippet"
    echo -e "${YELLOW}  To enable automation, add this to your .zshrc:${NC}"
    echo -e "${YELLOW}    source \"$integration_snippet\"${NC}"
    echo ""
    echo -e "${YELLOW}  Or for full optimization, replace .zshrc with:${NC}"
    echo -e "${YELLOW}    cp \"$optimized_zshrc\" \"$zshrc_file\"${NC}"

    echo -e "${GREEN}✅ Shell configuration integration ready${NC}"
}

# Function to run initial tests
run_initial_tests() {
    print_header "Running Initial Tests"

    echo "Testing benchmark automation..."
    if just benchmark-shells >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Benchmark automation working${NC}"
    else
        echo -e "  ${RED}❌ Benchmark automation failed${NC}"
    fi

    echo "Testing context detection..."
    if just context-detect >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Context detection working${NC}"
    else
        echo -e "  ${RED}❌ Context detection failed${NC}"
    fi

    echo "Testing performance monitoring..."
    if just perf-benchmark >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Performance monitoring working${NC}"
    else
        echo -e "  ${RED}❌ Performance monitoring failed${NC}"
    fi

    echo -e "${GREEN}✅ Initial tests complete${NC}"
}

# Function to show setup summary
show_setup_summary() {
    print_header "Setup Complete - Summary"

    echo -e "${CYAN}Automation Tools Installed:${NC}"
    echo "  📊 Benchmark System - Advanced hyperfine-based benchmarking"
    echo "  🔍 Context Detection - Smart shell usage pattern analysis"
    echo "  🚀 Performance Monitoring - Continuous startup time tracking"
    echo "  ⚡ Lazy Loading System - Context-aware plugin loading"
    echo "  💾 Result Caching - Smart caching with invalidation"
    echo ""

    echo -e "${CYAN}Available Just Commands:${NC}"
    echo "  just benchmark-all         # Comprehensive system benchmarks"
    echo "  just benchmark-shells      # Shell startup benchmarks"
    echo "  just perf-benchmark        # Performance monitoring benchmark"
    echo "  just perf-report [days]    # Performance report"
    echo "  just context-analyze       # Usage pattern analysis"
    echo "  just context-recommend     # Get optimization recommendations"
    echo "  just perf-full-analysis    # Complete performance analysis"
    echo "  just automation-setup      # Re-run automation setup"
    echo ""

    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. ${YELLOW}Enable monitoring by adding to .zshrc:${NC}"
    echo "   source \"$DOTFILES_DIR/.zshrc.automation-integration\""
    echo ""
    echo "2. ${YELLOW}Or use the fully optimized configuration:${NC}"
    echo "   cp \"$DOTFILES_DIR/.zshrc.optimized\" \"$DOTFILES_DIR/.zshrc\""
    echo ""
    echo "3. ${YELLOW}Run initial analysis:${NC}"
    echo "   just perf-full-analysis"
    echo ""
    echo "4. ${YELLOW}Monitor performance regularly:${NC}"
    echo "   just perf-report 7"
    echo ""

    echo -e "${GREEN}🎉 All automation tools are ready!${NC}"
}

# Main execution
main() {
    echo -e "${CYAN}🤖 GROUP 4 Automation Setup${NC}"
    echo -e "${CYAN}Setting up performance monitoring and optimization tools${NC}"
    echo ""

    check_prerequisites
    setup_directories
    setup_performance_monitoring
    setup_context_detection
    setup_benchmark_automation
    integrate_shell_config
    run_initial_tests
    show_setup_summary
}

# Run main function
main "$@"