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

# Initialize starship prompt
[[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Loading starship prompt at $(date '+%T.%3N')"
eval "$(starship init zsh)"

# Load zsh-defer for async plugin loading
[[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Loading zsh-defer at $(date '+%T.%3N')"
source "$(nix-build --no-out-link '<nixpkgs>' -A zsh-defer)/share/zsh-defer/zsh-defer.plugin.zsh" 2>/dev/null || {
  # Fallback if zsh-defer not available
  [[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Using zsh-defer fallback"
  zsh-defer() { "$@"; }
}

# Load completions immediately - we need them working!
[[ -n "$ZSH_DEBUG" ]] && echo "[DEBUG] Loading completions at $(date '+%T.%3N')"
autoload -Uz compinit && compinit -C

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

# Git aliases from your development workflow
alias gs='git town sync'
alias gnpr='git town new-pull-request'
alias gco='git town switch'

# Development shortcuts from CLAUDE.md
alias d='bun dev'
alias t='bun test'
alias l='bun lint'
alias tc='bun typecheck'

# Navigation shortcuts
alias proj='cd ~/WebstormProjects'
alias dots='cd ~/.dotfiles'

# Debug mode completion and cleanup
if [[ -n "$ZSH_DEBUG" ]]; then
  echo "[DEBUG] Completed .zshrc initialization at $(date '+%T.%3N')"
  echo "[DEBUG] Total startup time: $(($(date +%s%3N) - ZSH_DEBUG_START))ms" 2>/dev/null || true
  set +x  # Disable command tracing
fi