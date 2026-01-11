{lib, ...}: {
  # Common Nix settings (platform-agnostic)
  nix = {
    enable = true;
    settings = {
      # Necessary for using flakes on this system
      experimental-features = "nix-command flakes";

      # Enhanced Nix settings for better performance and reliability
      builders-use-substitutes = true;
      connect-timeout = 60; # Increased to 60s to handle DNS timeouts
      fallback = true;
      http-connections = 10; # Reduced to avoid "Too many open files" errors
      keep-derivations = true;
      keep-outputs = true;
      log-lines = 25;
      max-free = 3000000000; # 3GB
      min-free = 1000000000; # 1GB
      sandbox = true; # Strict sandboxing for security
      # Force IPv4-only binary caches (trailing slashes prevent IPv6 DNS lookups)
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org/"
        "https://hyprland.cachix.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
      warn-dirty = false;
    };

    # Note: Garbage collection and optimization handled via systemd timers
    # Automatic GC: nix-collect-garbage -d
    # Manual optimization: nix-store --optimize
    # These can be automated via systemd timers if needed

    # Additional Nix configuration for robustness
    checkConfig = true;
    extraOptions = ''
      # Additional Nix options for enhanced reliability
      keep-build-log = true
      keep-failed = false
      build-max-jobs = auto
      cores = 0

      # Flake settings
      accept-flake-config = true
      show-trace = true
    '';
  };

  # Common nixpkgs configuration (platform-agnostic except for hostPlatform)
  nixpkgs = {
    config = {
      allowUnsupportedSystem = true;
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "vault" # 'bsl11' licence
          "terraform" # 'bsl11' licence
          "cursor" # 'unfree'
          "idea-ultimate" # 'unfree' licence
          "webstorm" # 'unfree' licence
          "goland" # 'unfree' licence
          "rider" # 'unfree' licence
          "google-chrome" # 'unfree' licence
          "signal-desktop-bin" # 'agpl3Only free unfree'
          "castlabs-electron" # needed for tidal-hifi
          "grayjay" # 'sfl' licence - Cross-platform application to stream and download content
        ];
    };
  };

  # Note: Time zone configuration is platform-specific
  # NixOS: platforms/nixos/system/networking.nix
  # Darwin: Use system location services
  # (Do not set here to avoid conflicts)
}
