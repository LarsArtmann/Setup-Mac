# Enable zsh profiling
zmodload zsh/zprof

# Minimal .zshrc with starship prompt and async loading
# Backup of original config saved as ~/.zshrc.backup.*

# Debug mode - set ZSH_DEBUG=1 to enable verbose startup logging
if [[ -n "$ZSH_DEBUG" ]]; then
  ZSH_DEBUG_START=$(date +%s%3N)
  echo "[DEBUG] Starting .zshrc initialization at $(date '+%T.%3N')"
  set -x  # Enable command tracing
fi

# Skip slow security checks for faster startup
ZSH_DISABLE_COMPFIX=true

# PERFORMANCE-OPTIMIZED: Starship with ultra-fast config
[[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Loading optimized starship at $(date '+%T.%3N')"

# Your beautiful starship prompt (27ms overhead)
eval "$(starship init zsh)"

# Load zsh-defer for async plugin loading
[[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Loading zsh-defer at $(date '+%T.%3N')"
source "$(nix-build --no-out-link '<nixpkgs>' -A zsh-defer)/share/zsh-defer/zsh-defer.plugin.zsh" 2>/dev/null || {
  # Fallback if zsh-defer not available
  [[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Using zsh-defer fallback"
  zsh-defer() { "$@"; }
}

# PERFORMANCE BUDGET: Async completions for 500ms 95%tile budget
[[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Using async completions for balanced performance"

# Essential completions loaded asynchronously after prompt appears
# This gives you instant shell + completions loading in background
zsh-defer -c 'autoload -Uz compinit && compinit -C -d ~/.cache/zsh/zcompdump-minimal-5.9 2>/dev/null'

# Async load bun completions after shell startup
[[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Scheduling async bun loading at $(date '+%T.%3N')"
zsh-defer -c '[ -s "/Users/larsartmann/.bun/_bun" ] && source "/Users/larsartmann/.bun/_bun"'

# Async load fzf after shell startup
[[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Scheduling async fzf loading at $(date '+%T.%3N')"
zsh-defer -c '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'

# Environment
export GPG_TTY=$(tty)
export GH_PAGER=""

# Source private environment variables (not tracked in git)
[ -f ~/.env.private ] && source ~/.env.private

# Debug mode completion and cleanup
if [[ -n "$ZSH_DEBUG" ]]; then
  echo "[DEBUG] Completed .zshrc initialization at $(date '+%T.%3N')"
  echo "[DEBUG] Total startup time: $(($(date +%s%3N) - ZSH_DEBUG_START))ms" 2>/dev/null || true
  set +x  # Disable command tracing
fi

# Show zsh profiling information
zprof

echo "Go ROCK!"
