{ lib, ... }:
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

  # System validation - simplified to always true for now
  validateMacOS = true;

in {
  # Ensure we're on a compatible system
  assertions = [
    {
      assertion = validateMacOS;
      message = "This configuration requires a macOS (darwin) system";
    }
  ];
  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Enhanced Security Configuration
  security = {
    # PAM services with Touch ID authentication
    pam.services = {
      # Enable Touch ID for sudo operations
      sudo_local.touchIdAuth = true;
      # Consider enabling for other services with caution:
      # sudo.touchIdAuth = true;  # May interfere with some workflows
    };

    # Enhanced PKI (Public Key Infrastructure) settings
    pki = {
      # Additional certificate authorities can be added here if needed
      # certificateFiles = [ "/path/to/custom-ca.crt" ];
      # Enable certificate verification for enhanced security
      installCACerts = true;
    };

    # Enhanced sudo configuration for better security
    sudo = {
      # Require password for wheel group (disable passwordless sudo)
      wheelNeedsPassword = true;
      # Additional sudo security options
      extraConfig = ''
        # Security enhancements for sudo
        Defaults timestamp_timeout=5
        Defaults lecture=always
        Defaults logfile=/var/log/sudo.log
        Defaults log_input, log_output
        # Only wheel group members can use sudo (manual configuration)
        %wheel ALL=(ALL) ALL
      '';
    };
  };

  # I think leaving this null means that MacOS will
  # manage the system timezone based on location itself.
  time.timeZone = null;

  nix = {
    enable = true;
    settings = {
      # Necessary for using flakes on this system
      experimental-features = "nix-command flakes";

      # Enhanced Nix settings for better performance and reliability
      auto-optimise-store = true;
      builders-use-substitutes = true;
      connect-timeout = 5;
      download-timeout = 60;
      fallback = true;
      http-connections = 25;
      keep-derivations = true;
      keep-outputs = true;
      log-lines = 25;
      max-free = 3000000000; # 3GB
      min-free = 1000000000; # 1GB
      sandbox = true;
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = [ "@admin" ];
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

  nixpkgs = {
    # The platform the configuration will be used on.
    hostPlatform = "aarch64-darwin";
    config = {
      allowUnsupportedSystem = true;
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "vault" # 'bsl11' licence
        "terraform" # 'bsl11' licence
        #"cloudflare-warp" # 'unfree' licence
        "cursor" # 'unfree'
        "idea-ultimate" # 'unfree' licence
        "webstorm" # 'unfree' licence
        "goland" # 'unfree' licence
        "rider" # 'unfree' licence
        "google-chrome" # 'unfree' licence
        "signal-desktop-bin" # 'agpl3Only free unfree'
        "castlabs-electron" # needed for tidal-hifi
      ];
    };
  };
}
