{ lib, ... }: {
  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # MacOS
  security.pam.services.sudo_local.touchIdAuth = true;
  # TODO: ADD https://mynixos.com/nix-darwin/options/security
  # TODO: ADD https://mynixos.com/nix-darwin/options/services.tailscale

  time.timeZone = null;

  nix = {
    enable = true;
    settings = {
      # Necessary for using flakes on this system.
      experimental-features = "nix-command flakes";
    };
    gc = {
      automatic = true;
      interval = { Hour = 0; Minute = 0; };
      options = "--delete-older-than 3d";
    };
    optimise = {
      automatic = true;
      interval = { Weekday = 0; Hour = 0; Minute = 0; };
    };
  };

  nixpkgs = {
    # The platform the configuration will be used on.
    hostPlatform = "aarch64-darwin";
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "vault" # ‘bsl11’ licence
      "terraform" # ‘bsl11’ licence
      #"cloudflare-warp" # ‘unfree’ licence
      "cursor" # ‘unfree’
    ];
  };
}
