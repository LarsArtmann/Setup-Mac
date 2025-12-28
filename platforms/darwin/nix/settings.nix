{...}: {
  # Use common Nix settings - eliminate duplication
  imports = [../../common/core/nix-settings.nix];

  # Darwin-specific Nix settings only
  nix.settings = {
    # Enable sandboxing for Darwin builds
    sandbox = true;

    # Add Darwin-specific paths to sandbox for compatibility
    # COMPREHENSIVE: Based on research from 50+ nix-darwin configurations
    # Source: docs/troubleshooting/SANDBOX-PATHS-RESEARCH.md
    extra-sandbox-paths = [
      # === CORE SYSTEM PATHS (Essential for all builds) ===
      "/System/Library/Frameworks"       # Core frameworks (Cocoa, Foundation, AppKit, etc.)
      "/System/Library/PrivateFrameworks" # Private Apple APIs (often required)
      "/usr/lib"                        # System libraries (libSystem.B.dylib, etc.)
      "/usr/include"                     # System headers for building C/C++ packages
      "/usr/bin/env"                     # Environment utility (required by many build systems)

      # === TEMPORARY DIRECTORIES (Critical for builds) ===
      "/private/tmp"                     # Temporary build files
      "/private/var/tmp"                 # Persistent temp storage

      # === SHELL INTERPRETERS (Required by build systems) ===
      "/bin/sh"                          # Standard POSIX shell
      "/bin/bash"                        # Bash shell
      "/bin/zsh"                         # Zsh shell (macOS default)

      # === DEVELOPMENT TOOLS (Optional but recommended) ===
      "/Library/Developer/CommandLineTools" # Xcode Command Line Tools (required for some native builds)
      "/usr/local/lib"                    # Homebrew libraries (for mixed Nix/Homebrew setups)

      # === DESKTOP APPLICATIONS (For GUI apps and Electron) ===
      "/System/Library/Fonts"            # System fonts (needed by some GUI apps)
      "/System/Library/ColorSync/Profiles" # Color profiles (needed by graphics apps)

      # === OPTIONAL: Device access (Commented out for security) ===
      # "/dev"                           # Hardware access (SECURITY RISK - only enable if needed)
    ];
  };
}
