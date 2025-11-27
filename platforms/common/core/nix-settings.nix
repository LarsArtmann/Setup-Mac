{ lib, pkgs, ... }:

let
  # Validation helpers for robust configuration
  validateUser = user:
    if user == null || user == "" then
      throw "User cannot be null or empty"
    else user;

  validatePath = path:
    if path == null || path == "" then
      throw "Path cannot be null or empty"
    else path;

in {
  # Common Nix settings (platform-agnostic)
  nix = {
    enable = true;
    settings = {
      # Necessary for using flakes on this system
      experimental-features = "nix-command flakes";

      # Enhanced Nix settings for better performance and reliability
      builders-use-substitutes = true;
      connect-timeout = 5;
      fallback = true;
      http-connections = 25;
      keep-derivations = true;
      keep-outputs = true;
      log-lines = 25;
      max-free = 3000000000; # 3GB
      min-free = 1000000000; # 1GB
      sandbox = true; # Strict sandboxing for security
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      warn-dirty = false;
    };

    # Enhanced garbage collection
    gc = {
      automatic = true;
      interval = { Hour = 2; Minute = 30; }; # Run at 2:30 AM
      options = "--delete-older-than 7d --max-freed 5G";
    };

    # Enhanced store optimization
    optimise = {
      automatic = true;
      interval = { Weekday = 7; Hour = 3; Minute = 0; }; # Weekly on Sunday at 3 AM
    };

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
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
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

  # Time zone configuration (platform-agnostic)
  time.timeZone = null; # Let system manage based on location
}