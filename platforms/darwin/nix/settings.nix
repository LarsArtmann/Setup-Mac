{...}: {
  # Use common Nix settings - eliminate duplication
  imports = [../../common/core/nix-settings.nix];

  # Darwin-specific Nix settings only
  nix.settings = {
    # Enable sandboxing for Darwin builds
    sandbox = true;

    # Add Darwin-specific paths to sandbox for compatibility
    # FIXED: Added missing critical paths for builds to work correctly
    extra-sandbox-paths = [
      "/dev"                      # Device access (optional but useful)
      "/System/Library/Frameworks"   # Core frameworks (Cocoa, Foundation, etc.)
      "/System/Library/PrivateFrameworks"  # Private frameworks
      "/usr/lib"                 # System libraries
      "/usr/include"              # System headers for building (CRITICAL)
      "/bin/sh"                  # Shell interpreter
      "/bin/bash"                # Bash interpreter
      "/bin/zsh"                 # Zsh interpreter
      "/private/tmp"             # Temporary build files (CRITICAL)
      "/private/var/tmp"         # Persistent temp storage (CRITICAL)
      "/usr/bin/env"             # Environment utility (CRITICAL)
      # TODO: Do we need /var/?
    ];
  };
}
