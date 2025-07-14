#!/bin/bash

# Shell Context Detection and Performance Analysis
# Detects shell usage patterns and provides context-based loading recommendations

# Configuration
CONTEXT_DATA_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/shell-context"
USAGE_LOG="$CONTEXT_DATA_DIR/usage.log"
PATTERNS_FILE="$CONTEXT_DATA_DIR/patterns.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure directory exists
mkdir -p "$CONTEXT_DATA_DIR"

# Function to detect current shell context
detect_shell_context() {
    local context="unknown"
    local startup_reason="unknown"
    local performance_class="normal"

    # Check if running interactively
    if [[ $- == *i* ]]; then
        context="interactive"

        # Detect why shell was started
        if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
            startup_reason="ssh"
        elif [[ "$TERM_PROGRAM" == "vscode" ]]; then
            startup_reason="vscode"
        elif [[ "$TERM_PROGRAM" == "Terminal" ]]; then
            startup_reason="terminal_app"
        elif [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
            startup_reason="iterm"
        elif [[ -n "$TMUX" ]]; then
            startup_reason="tmux"
        elif [[ "$SHLVL" -gt 1 ]]; then
            startup_reason="subshell"
        else
            startup_reason="terminal"
        fi
    else
        context="non_interactive"

        # Check for common non-interactive uses
        if [[ -n "$CI" ]]; then
            startup_reason="ci"
            performance_class="critical"
        elif [[ -n "$BUILD_PIPELINE" ]]; then
            startup_reason="build"
            performance_class="critical"
        elif [[ "$0" == *"cron"* ]]; then
            startup_reason="cron"
            performance_class="critical"
        elif [[ -n "$AUTOMATION" ]]; then
            startup_reason="automation"
            performance_class="critical"
        else
            startup_reason="script"
            performance_class="important"
        fi
    fi

    # Detect development context
    local dev_context="none"
    if [[ -f "package.json" ]]; then
        dev_context="nodejs"
    elif [[ -f "go.mod" ]]; then
        dev_context="golang"
    elif [[ -f "Cargo.toml" ]]; then
        dev_context="rust"
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        dev_context="python"
    elif [[ -f "flake.nix" ]]; then
        dev_context="nix"
    fi

    # Return context information
    cat << EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "context": "$context",
    "startup_reason": "$startup_reason",
    "performance_class": "$performance_class",
    "dev_context": "$dev_context",
    "shell": "$SHELL",
    "shlvl": "$SHLVL",
    "pwd": "$PWD",
    "user": "$USER",
    "hostname": "$HOSTNAME",
    "terminal": "$TERM_PROGRAM",
    "session_id": "$SESSION_ID"
}
EOF
}

# Function to log shell usage
log_shell_usage() {
    local context_info="$1"
    echo "$context_info" >> "$USAGE_LOG"

    # Keep only last 1000 entries
    if [[ $(wc -l < "$USAGE_LOG") -gt 1000 ]]; then
        tail -1000 "$USAGE_LOG" > "${USAGE_LOG}.tmp"
        mv "${USAGE_LOG}.tmp" "$USAGE_LOG"
    fi
}

# Function to analyze usage patterns
analyze_usage_patterns() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo -e "${RED}No usage data found. Run some shell sessions first.${NC}"
        return 1
    fi

    echo -e "${CYAN}🔍 Analyzing shell usage patterns...${NC}"
    echo

    # Basic statistics
    local total_sessions=$(wc -l < "$USAGE_LOG")
    echo -e "${BLUE}Total sessions analyzed: $total_sessions${NC}"

    # Context breakdown
    echo -e "\n${PURPLE}Context Breakdown:${NC}"
    jq -r '.context' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -nr | while read count context; do
        echo "  $context: $count sessions"
    done

    # Startup reason breakdown
    echo -e "\n${PURPLE}Startup Reasons:${NC}"
    jq -r '.startup_reason' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -nr | while read count reason; do
        echo "  $reason: $count sessions"
    done

    # Performance class breakdown
    echo -e "\n${PURPLE}Performance Requirements:${NC}"
    jq -r '.performance_class' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -nr | while read count class; do
        echo "  $class: $count sessions"
    done

    # Development context breakdown
    echo -e "\n${PURPLE}Development Contexts:${NC}"
    jq -r '.dev_context' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -nr | while read count context; do
        if [[ "$context" != "none" ]]; then
            echo "  $context: $count sessions"
        fi
    done

    # Terminal usage
    echo -e "\n${PURPLE}Terminal Applications:${NC}"
    jq -r '.terminal' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -nr | while read count terminal; do
        if [[ "$terminal" != "null" ]] && [[ -n "$terminal" ]]; then
            echo "  $terminal: $count sessions"
        fi
    done

    # Time analysis (last 24 hours)
    echo -e "\n${PURPLE}Recent Activity (last 24 hours):${NC}"
    local yesterday=$(date -u -d '24 hours ago' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-1d +"%Y-%m-%dT%H:%M:%SZ")
    local recent_count=$(jq -r --arg since "$yesterday" 'select(.timestamp >= $since)' "$USAGE_LOG" 2>/dev/null | wc -l)
    echo "  Recent sessions: $recent_count"
}

# Function to generate loading recommendations
generate_loading_recommendations() {
    if [[ ! -f "$USAGE_LOG" ]]; then
        echo -e "${RED}No usage data found. Run some shell sessions first.${NC}"
        return 1
    fi

    echo -e "${CYAN}💡 Loading Optimization Recommendations${NC}"
    echo

    # Analyze performance-critical sessions
    local critical_sessions=$(jq -r 'select(.performance_class == "critical")' "$USAGE_LOG" 2>/dev/null | wc -l)
    local total_sessions=$(wc -l < "$USAGE_LOG")
    local critical_percentage=$((critical_sessions * 100 / total_sessions))

    echo -e "${BLUE}Performance Analysis:${NC}"
    echo "  Critical performance sessions: $critical_sessions ($critical_percentage%)"

    if [[ $critical_percentage -gt 20 ]]; then
        echo -e "${YELLOW}⚠️  High percentage of performance-critical sessions detected${NC}"
        echo "  Recommendation: Implement aggressive lazy loading"
    fi

    # Interactive vs non-interactive analysis
    local interactive_sessions=$(jq -r 'select(.context == "interactive")' "$USAGE_LOG" 2>/dev/null | wc -l)
    local interactive_percentage=$((interactive_sessions * 100 / total_sessions))

    echo -e "\n${BLUE}Context Analysis:${NC}"
    echo "  Interactive sessions: $interactive_sessions ($interactive_percentage%)"

    if [[ $interactive_percentage -gt 80 ]]; then
        echo -e "${GREEN}✅ Mostly interactive usage - UX optimizations recommended${NC}"
        echo "  Recommendation: Focus on perceived performance, async loading"
    elif [[ $interactive_percentage -lt 50 ]]; then
        echo -e "${YELLOW}⚠️  High non-interactive usage detected${NC}"
        echo "  Recommendation: Minimize all startup overhead"
    fi

    # Development context recommendations
    local dev_sessions=$(jq -r 'select(.dev_context != "none")' "$USAGE_LOG" 2>/dev/null | wc -l)
    if [[ $dev_sessions -gt $((total_sessions / 4)) ]]; then
        echo -e "\n${BLUE}Development Context Detected:${NC}"

        # Most common dev contexts
        local top_dev_context=$(jq -r 'select(.dev_context != "none") | .dev_context' "$USAGE_LOG" 2>/dev/null | sort | uniq -c | sort -nr | head -1 | awk '{print $2}')
        echo "  Primary development context: $top_dev_context"

        case "$top_dev_context" in
            "nodejs")
                echo "  Recommendation: Lazy load bun/npm completions"
                ;;
            "golang")
                echo "  Recommendation: Lazy load Go tools and completions"
                ;;
            "python")
                echo "  Recommendation: Lazy load pyenv and Python tools"
                ;;
            "rust")
                echo "  Recommendation: Lazy load cargo completions"
                ;;
            "nix")
                echo "  Recommendation: Optimize Nix-related tools loading"
                ;;
        esac
    fi

    # Generate specific loading strategy
    echo -e "\n${GREEN}Recommended Loading Strategy:${NC}"

    if [[ $critical_percentage -gt 15 ]]; then
        echo "  1. Use context detection to skip unnecessary tools"
        echo "  2. Implement conditional loading based on directory"
        echo "  3. Cache expensive operations"
    fi

    if [[ $interactive_percentage -gt 70 ]]; then
        echo "  4. Use async loading for non-essential tools"
        echo "  5. Optimize prompt initialization"
        echo "  6. Enable instant prompt for immediate feedback"
    fi

    echo "  7. Profile startup regularly with benchmarks"
    echo "  8. Monitor performance regressions"
}

# Function to create context-aware loading hook
create_loading_hook() {
    local hook_file="$CONTEXT_DATA_DIR/loading-hook.zsh"

    cat > "$hook_file" << 'EOF'
# Context-aware loading hook for zsh
# Source this from your .zshrc to enable context detection

# Detect and log current shell context
_shell_context_info=$(detect_shell_context 2>/dev/null || echo '{"context":"unknown"}')
_shell_context=$(echo "$_shell_context_info" | jq -r '.context' 2>/dev/null || echo "unknown")
_performance_class=$(echo "$_shell_context_info" | jq -r '.performance_class' 2>/dev/null || echo "normal")
_dev_context=$(echo "$_shell_context_info" | jq -r '.dev_context' 2>/dev/null || echo "none")

# Log usage for analysis
echo "$_shell_context_info" >> "${XDG_CACHE_HOME:-$HOME/.cache}/shell-context/usage.log" 2>/dev/null

# Context-based loading decisions
case "$_performance_class" in
    "critical")
        # Skip all non-essential loading for critical performance
        export SHELL_FAST_MODE=1
        ;;
    "important")
        # Load only essential tools
        export SHELL_MINIMAL_MODE=1
        ;;
    "normal")
        # Normal loading with optimizations
        export SHELL_OPTIMIZED_MODE=1
        ;;
esac

# Development-context-specific loading
case "$_dev_context" in
    "nodejs")
        export LOAD_NODE_TOOLS=1
        ;;
    "golang")
        export LOAD_GO_TOOLS=1
        ;;
    "python")
        export LOAD_PYTHON_TOOLS=1
        ;;
    "rust")
        export LOAD_RUST_TOOLS=1
        ;;
    "nix")
        export LOAD_NIX_TOOLS=1
        ;;
esac

# Cleanup
unset _shell_context_info _shell_context _performance_class _dev_context
EOF

    echo -e "${GREEN}✅ Loading hook created: $hook_file${NC}"
    echo "Add this to your .zshrc:"
    echo "  source \"$hook_file\""
}

# Function to show current context
show_current_context() {
    local context_info=$(detect_shell_context)
    echo -e "${CYAN}Current Shell Context:${NC}"
    echo "$context_info" | jq -r '
        "Context: \(.context)",
        "Startup Reason: \(.startup_reason)",
        "Performance Class: \(.performance_class)",
        "Development Context: \(.dev_context)",
        "Shell: \(.shell)",
        "Level: \(.shlvl)",
        "Directory: \(.pwd)",
        "Terminal: \(.terminal)"
    ' 2>/dev/null || echo "$context_info"
}

# Function to show help
show_help() {
    echo "Shell Context Detection and Analysis Tool"
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  detect          Show current shell context"
    echo "  log             Log current session (for analysis)"
    echo "  analyze         Analyze usage patterns"
    echo "  recommend       Generate loading recommendations"
    echo "  create-hook     Create context-aware loading hook"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 detect                    # Show current context"
    echo "  $0 log                       # Log current session"
    echo "  $0 analyze                   # Analyze usage patterns"
    echo "  $0 recommend                 # Get optimization recommendations"
}

# Main execution
case "${1:-detect}" in
    "detect"|"current")
        show_current_context
        ;;
    "log")
        context_info=$(detect_shell_context)
        log_shell_usage "$context_info"
        echo -e "${GREEN}✅ Session logged${NC}"
        ;;
    "analyze"|"analysis")
        analyze_usage_patterns
        ;;
    "recommend"|"recommendations")
        generate_loading_recommendations
        ;;
    "create-hook"|"hook")
        create_loading_hook
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