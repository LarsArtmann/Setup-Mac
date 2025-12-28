{ lib, ... }: {
  # TEMP: Disable common module import to avoid sandbox merging conflicts
  # TODO: Refactor to properly override sandbox setting
  # imports = [../../common/core/nix-settings.nix];

  # Darwin-specific Nix settings
  # NOTE: Common settings from ../../common/core/nix-settings.nix included below
  # but with sandbox disabled to fix build failures
  nix.settings = {
    # Common Nix settings (from nix-settings.nix)
    experimental-features = "nix-command flakes";
    builders-use-substitutes = true;
    connect-timeout = 5;
    fallback = true;
    http-connections = 25;
    keep-derivations = true;
    keep-outputs = true;
    log-lines = 25;
    max-free = 3000000000; # 3GB
    min-free = 1000000000; # 1GB
    sandbox = false; # OVERRIDE: Disabled to match generation 205 working state
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    warn-dirty = false;

    # Allow impure host dependencies for macOS SDK access
    # FIX: Add SDK paths to allow packages to access system headers
    # This is required for packages that need /usr/include but it doesn't exist on modern macOS
    impureHostDeps = [
      "/Library/Developer/CommandLineTools"
      "/Library/Developer/CommandLineTools/SDKs"
      "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
      "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include"
      "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib"
    ];

    # Add Darwin-specific paths to sandbox for compatibility
    # COMPREHENSIVE: Based on research from 50+ nix-darwin configurations
    # Source: docs/troubleshooting/SANDBOX-PATHS-RESEARCH.md
    # FIX: Removed /usr/include (doesn't exist on modern macOS aarch64-darwin)
    # FIX: Added Xcode SDK include path (required for building macOS packages)
    extra-sandbox-paths = [
      # === CORE SYSTEM PATHS (Essential for all builds) ===
      "/System/Library/Frameworks"       # Core frameworks (Cocoa, Foundation, AppKit, etc.)
      "/System/Library/PrivateFrameworks" # Private Apple APIs (often required)
      "/usr/lib"                        # System libraries (libSystem.B.dylib, etc.)
      # "/usr/include"  <-- REMOVED: Doesn't exist on modern macOS (causes build failures)
      "/usr/bin/env"                     # Environment utility (required by many build systems)

      # === TEMPORARY DIRECTORIES (Critical for builds) ===
      "/private/tmp"                     # Temporary build files
      "/private/var/tmp"                 # Persistent temp storage

      # === SHELL INTERPRETERS (Required by build systems) ===
      "/bin/sh"                          # Standard POSIX shell
      "/bin/bash"                        # Bash shell
      "/bin/zsh"                         # Zsh shell (macOS default)

      # === DESKTOP APPLICATIONS (For GUI apps and Electron) ===
      "/System/Library/Fonts"            # System fonts (needed by some GUI apps)
      "/System/Library/ColorSync/Profiles" # Color profiles (needed by graphics apps)

      # === OPTIONAL: Homebrew (For mixed Nix/Homebrew setups) ===
      "/usr/local/lib"                    # Homebrew libraries

      # === XCODE SDK PATHS (Required for macOS package builds) ===
      "/Library/Developer/CommandLineTools" # Xcode Command Line Tools
      "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include" # System headers for C/C++ packages
      "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib" # System libraries
    ];
  };
}
