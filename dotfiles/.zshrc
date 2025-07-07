# Minimal .zshrc with starship prompt
# Backup of original config saved as ~/.zshrc.backup.*

# Skip slow security checks for faster startup
ZSH_DISABLE_COMPFIX=true

# Initialize starship prompt
eval "$(starship init zsh)"

# Lazy load completions - only when needed
autoload -Uz compinit
_comp_loaded=false

# Function to load completions on first tab press
_lazy_comp() {
  if ! $_comp_loaded; then
    compinit -C
    _comp_loaded=true
  fi
  unset -f _lazy_comp
  # Re-trigger completion
  zle expand-or-complete
}

# Override tab to lazy load completions
zle -N _lazy_comp
bindkey '^I' _lazy_comp

# Essential tool integrations
[ -s "/Users/larsartmann/.bun/_bun" ] && source "/Users/larsartmann/.bun/_bun"

# Lazy load fzf - only when first used
_fzf_loaded=false
_load_fzf() {
  if ! $_fzf_loaded && [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
    _fzf_loaded=true
  fi
}

# Create wrapper functions for fzf commands
fzf() { _load_fzf; command fzf "$@"; }
__fzf_select__() { _load_fzf; command __fzf_select__ "$@"; }

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