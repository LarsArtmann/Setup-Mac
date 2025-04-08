HOME="/Users/larsartmann"
HOME_BREW_BIN="/opt/homebrew/bin"
HOME_BREW_SBIN="/opt/homebrew/sbin"
GOOGLE_CLOUD="/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin"
NIX="$HOME/.nix-profile/bin"
NIX_DARWIN="/run/current-system/sw/bin"
NIX_OTHER="/nix/var/nix/profiles/default/bin"
USER_LOCAL_BIN="/usr/.local/bin"
USER_BIN="/usr/bin"
USER_SBIN="/usr/bin"
BIN="/bin"
SBIN="/sbin"
JET_BRAINS="$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
LOCAL_BIN="$HOME/.local/bin"
GO_HOME="$HOME/go/bin"
BUN_HOME="$HOME/.bun/bin"
TURSO_HOME="$HOME/.turso"

ALL_PATHS=(
  "$HOME_BREW_BIN"
  "$HOME_BREW_SBIN"
  "$GOOGLE_CLOUD"
  "$NIX"
  "$NIX_DARWIN"
  "$NIX_OTHER"
  "$USER_LOCAL_BIN"
  "$USER_BIN"
  "$USER_SBIN"
  "$BIN"
  "$SBIN"
  "$JET_BRAINS"
  "$LOCAL_BIN"
  "$GO_HOME"
  "$BUN_HOME"
  "$TURSO_HOME"
)

export PATH=$(IFS=:; echo "${ALL_PATHS[*]}")
export JAVA_HOME=$(/usr/libexec/java_home -v17)
