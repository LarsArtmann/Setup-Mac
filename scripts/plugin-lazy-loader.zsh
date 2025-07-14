# Plugin Lazy Loading System for Zsh
# Implements context-aware and on-demand loading of shell plugins and tools

# Configuration
export ZSH_LAZY_LOADER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-lazy-loader"
export ZSH_LAZY_LOADER_LOG="$ZSH_LAZY_LOADER_DIR/loader.log"

# Create directories
mkdir -p "$ZSH_LAZY_LOADER_DIR"

# Debug logging function
_lazy_log() {
    [[ -n "$ZSH_LAZY_DEBUG" ]] && echo "[LAZY] $*" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$ZSH_LAZY_LOADER_LOG"
}

# Performance tracking
_lazy_timer_start() {
    _LAZY_TIMER_START=$(date +%s%3N)
}

_lazy_timer_end() {
    local end_time=$(date +%s%3N)
    local duration=$((end_time - _LAZY_TIMER_START))
    _lazy_log "Loaded $1 in ${duration}ms"
}

# Plugin registry - holds information about available plugins
declare -A ZSH_LAZY_PLUGINS
declare -A ZSH_LAZY_LOADED

# Register a plugin for lazy loading
lazy_register() {
    local name="$1"
    local load_cmd="$2"
    local triggers="$3"
    local conditions="$4"
    
    ZSH_LAZY_PLUGINS[$name]="$load_cmd|$triggers|$conditions"
    _lazy_log "Registered plugin: $name"
}

# Check if plugin loading conditions are met
_lazy_check_conditions() {
    local conditions="$1"
    
    [[ -z "$conditions" ]] && return 0
    
    # Parse conditions (comma-separated)
    IFS=',' read -ra COND_ARRAY <<< "$conditions"
    
    for condition in "${COND_ARRAY[@]}"; do
        case "$condition" in
            "interactive")
                [[ $- == *i* ]] || return 1
                ;;
            "git_repo")
                git rev-parse --git-dir >/dev/null 2>&1 || return 1
                ;;
            "nodejs_project")
                [[ -f "package.json" ]] || return 1
                ;;
            "golang_project")
                [[ -f "go.mod" ]] || return 1
                ;;
            "rust_project")
                [[ -f "Cargo.toml" ]] || return 1
                ;;
            "python_project")
                [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || return 1
                ;;
            "nix_project")
                [[ -f "flake.nix" ]] || [[ -f "default.nix" ]] || [[ -f "shell.nix" ]] || return 1
                ;;
            "fast_mode_disabled")
                [[ -z "$SHELL_FAST_MODE" ]] || return 1
                ;;
            "minimal_mode_disabled")
                [[ -z "$SHELL_MINIMAL_MODE" ]] || return 1
                ;;
            "command_exists:"*)
                local cmd="${condition#command_exists:}"
                command -v "$cmd" >/dev/null 2>&1 || return 1
                ;;
            "env_var:"*)
                local var="${condition#env_var:}"
                [[ -n "${(P)var}" ]] || return 1
                ;;
            "file_exists:"*)
                local file="${condition#file_exists:}"
                [[ -f "$file" ]] || return 1
                ;;
        esac
    done
    
    return 0
}

# Load a specific plugin
lazy_load() {
    local name="$1"
    local force="${2:-false}"
    
    # Skip if already loaded
    if [[ -n "${ZSH_LAZY_LOADED[$name]}" ]] && [[ "$force" != "true" ]]; then
        _lazy_log "Plugin $name already loaded, skipping"
        return 0
    fi
    
    # Check if plugin is registered
    if [[ -z "${ZSH_LAZY_PLUGINS[$name]}" ]]; then
        _lazy_log "Plugin $name not registered"
        return 1
    fi
    
    # Parse plugin info
    local plugin_info="${ZSH_LAZY_PLUGINS[$name]}"
    local load_cmd="${plugin_info%%|*}"
    local remaining="${plugin_info#*|}"
    local triggers="${remaining%%|*}"
    local conditions="${remaining#*|}"
    
    # Check conditions
    if ! _lazy_check_conditions "$conditions"; then
        _lazy_log "Conditions not met for plugin: $name"
        return 1
    fi
    
    _lazy_log "Loading plugin: $name"
    _lazy_timer_start
    
    # Execute load command
    eval "$load_cmd"
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        ZSH_LAZY_LOADED[$name]="$(date +%s)"
        _lazy_timer_end "$name"
        _lazy_log "Successfully loaded plugin: $name"
    else
        _lazy_log "Failed to load plugin: $name (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Create command wrappers for triggered loading
_lazy_create_wrapper() {
    local trigger="$1"
    local plugin_name="$2"
    
    # Skip if command already exists and is not a function
    if command -v "$trigger" >/dev/null 2>&1 && [[ "$(type -t "$trigger")" != "function" ]]; then
        return 0
    fi
    
    eval "
    $trigger() {
        unfunction $trigger 2>/dev/null || true
        lazy_load \"$plugin_name\"
        if command -v \"$trigger\" >/dev/null 2>&1; then
            \"$trigger\" \"\$@\"
        else
            echo \"Error: Command '$trigger' not available after loading plugin '$plugin_name'\" >&2
            return 1
        fi
    }
    "
}

# Load plugins based on triggers
lazy_setup_triggers() {
    for plugin_name in "${(@k)ZSH_LAZY_PLUGINS}"; do
        local plugin_info="${ZSH_LAZY_PLUGINS[$plugin_name]}"
        local load_cmd="${plugin_info%%|*}"
        local remaining="${plugin_info#*|}"
        local triggers="${remaining%%|*}"
        local conditions="${remaining#*|}"
        
        # Skip if no triggers
        [[ -z "$triggers" ]] && continue
        
        # Create wrappers for each trigger
        IFS=',' read -ra TRIGGER_ARRAY <<< "$triggers"
        for trigger in "${TRIGGER_ARRAY[@]}"; do
            _lazy_create_wrapper "$trigger" "$plugin_name"
        done
    done
}

# Load plugins immediately (bypass lazy loading)
lazy_load_immediate() {
    local plugins=("$@")
    
    if [[ ${#plugins[@]} -eq 0 ]]; then
        # Load all registered plugins
        plugins=("${(@k)ZSH_LAZY_PLUGINS}")
    fi
    
    for plugin in "${plugins[@]}"; do
        lazy_load "$plugin" "true"
    done
}

# Load plugins based on current context
lazy_load_context() {
    _lazy_log "Loading context-appropriate plugins"
    
    # Load based on environment variables set by context detector
    if [[ -n "$LOAD_NODE_TOOLS" ]]; then
        lazy_load "bun" "true"
        lazy_load "node_completions" "true"
    fi
    
    if [[ -n "$LOAD_GO_TOOLS" ]]; then
        lazy_load "go_completions" "true"
    fi
    
    if [[ -n "$LOAD_PYTHON_TOOLS" ]]; then
        lazy_load "python_tools" "true"
    fi
    
    if [[ -n "$LOAD_RUST_TOOLS" ]]; then
        lazy_load "rust_tools" "true"
    fi
    
    if [[ -n "$LOAD_NIX_TOOLS" ]]; then
        lazy_load "nix_tools" "true"
    fi
    
    # Load based on directory context
    if [[ -f "package.json" ]] && [[ -z "$SHELL_FAST_MODE" ]]; then
        lazy_load "bun" "true"
    fi
    
    if [[ -f "go.mod" ]] && [[ -z "$SHELL_FAST_MODE" ]]; then
        lazy_load "go_completions" "true"
    fi
    
    # Always load essential tools in interactive mode
    if [[ $- == *i* ]] && [[ -z "$SHELL_FAST_MODE" ]]; then
        lazy_load "fzf" "true"
        lazy_load "git_tools" "true"
    fi
}

# Directory change hook
lazy_chpwd() {
    # Load context-specific plugins when entering project directories
    lazy_load_context
}

# Add directory change hook
if [[ -z "$ZSH_LAZY_CHPWD_HOOKED" ]]; then
    autoload -U add-zsh-hook
    add-zsh-hook chpwd lazy_chpwd
    export ZSH_LAZY_CHPWD_HOOKED=1
fi

# Show loading status
lazy_status() {
    echo "Lazy Loading Status:"
    echo "==================="
    
    echo "\nRegistered plugins:"
    for plugin in "${(@k)ZSH_LAZY_PLUGINS}"; do
        local loaded_time="${ZSH_LAZY_LOADED[$plugin]}"
        if [[ -n "$loaded_time" ]]; then
            echo "  ✅ $plugin (loaded at $(date -r "$loaded_time" '+%H:%M:%S'))"
        else
            echo "  ⏳ $plugin (not loaded)"
        fi
    done
    
    echo "\nLoading log (last 10 entries):"
    tail -10 "$ZSH_LAZY_LOADER_LOG" 2>/dev/null | sed 's/^/  /'
}

# Clean up old logs
lazy_cleanup() {
    # Keep only last 1000 lines of log
    if [[ -f "$ZSH_LAZY_LOADER_LOG" ]]; then
        tail -1000 "$ZSH_LAZY_LOADER_LOG" > "${ZSH_LAZY_LOADER_LOG}.tmp"
        mv "${ZSH_LAZY_LOADER_LOG}.tmp" "$ZSH_LAZY_LOADER_LOG"
    fi
}

# Register common plugins with their loading strategies
_lazy_register_common_plugins() {
    # Bun completions - load on first bun command or in Node.js projects
    lazy_register "bun" \
        '[ -s "/Users/larsartmann/.bun/_bun" ] && source "/Users/larsartmann/.bun/_bun"' \
        'bun' \
        'command_exists:bun,fast_mode_disabled'
    
    # FZF - load on first fzf command or when needed
    lazy_register "fzf" \
        '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh' \
        'fzf' \
        'interactive,command_exists:fzf,fast_mode_disabled'
    
    # Git tools - load in git repositories
    lazy_register "git_tools" \
        'autoload -Uz vcs_info && zstyle ":vcs_info:*" enable git' \
        '' \
        'interactive,git_repo,fast_mode_disabled'
    
    # Node.js completions
    lazy_register "node_completions" \
        'source <(npm completion) 2>/dev/null || true' \
        'npm,npx,node' \
        'nodejs_project,command_exists:npm,minimal_mode_disabled'
    
    # Go completions
    lazy_register "go_completions" \
        'autoload -Uz compinit && compinit -C' \
        'go' \
        'golang_project,command_exists:go,minimal_mode_disabled'
    
    # Python tools
    lazy_register "python_tools" \
        'command -v pyenv >/dev/null && eval "$(pyenv init -)" 2>/dev/null || true' \
        'python,pip,pyenv' \
        'python_project,command_exists:python,minimal_mode_disabled'
    
    # Rust tools
    lazy_register "rust_tools" \
        'source "$HOME/.cargo/env" 2>/dev/null || true' \
        'cargo,rustc,rustup' \
        'rust_project,file_exists:~/.cargo/env,minimal_mode_disabled'
    
    # Nix tools
    lazy_register "nix_tools" \
        'source ~/.nix-profile/share/zsh/site-functions/_nix 2>/dev/null || true' \
        'nix,nix-shell,nix-build' \
        'nix_project,command_exists:nix,minimal_mode_disabled'
}

# Initialize common plugins
_lazy_register_common_plugins

# Setup triggers for registered plugins
lazy_setup_triggers

# Initial context-based loading
if [[ -z "$ZSH_LAZY_INITIALIZED" ]]; then
    lazy_load_context
    export ZSH_LAZY_INITIALIZED=1
fi

# Cleanup old logs on shell exit
trap lazy_cleanup EXIT

_lazy_log "Lazy loader initialized with ${#ZSH_LAZY_PLUGINS[@]} plugins"