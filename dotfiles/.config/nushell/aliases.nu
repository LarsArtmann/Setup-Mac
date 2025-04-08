# aliases.nu - Custom aliases for nushell
# These aliases match those defined in environment.nix

# Define aliases
alias t = echo 'Test :)'
alias l = ls -la
alias nixup = nh darwin switch $env.HOME/Desktop/Setup-Mac/dotfiles/nix/
alias mkdir = mkdir -p
alias c2p = code2prompt . --output=code2prompt.md --tokens
alias firebase-login = firebase login
alias gcloud-init = gcloud init
alias gcloud-components-install = gcloud components install cbt alpha beta
