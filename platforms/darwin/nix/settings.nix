{...}: {
  # Use common Nix settings - eliminate duplication
  imports = [../../common/core/nix-settings.nix];

  # Darwin-specific Nix settings only
  nix.settings = {
    # Enable sandboxing for Darwin builds
    sandbox = true;

    # Add Darwin-specific paths to sandbox for compatibility
    extra-sandbox-paths = [
      "/dev"
      "/System/Library/Frameworks"
      "/System/Library/PrivateFrameworks"
      "/usr/lib"
      "/bin/sh"
      "/bin/bash"
      "/bin/zsh"
    ];
  };
}
