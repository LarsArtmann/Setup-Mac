# Using PATH and environment variables from nix-darwin instead of setting them here
# This ensures consistency across shells

# Set JAVA_HOME explicitly since it's not being set by nix-darwin
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"
export GOPRIVATE=github.com/LarsArtmann/*
