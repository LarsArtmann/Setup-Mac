# Using PATH from nix-darwin instead of setting it with brew shellenv
# This ensures consistency across shells

# Note: OrbStack integration is now handled through nix-darwin PATH configuration

# Set JAVA_HOME explicitly since it's not being set by nix-darwin
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"
