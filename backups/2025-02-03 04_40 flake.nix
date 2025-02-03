{
  description = "Lars nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, ... }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
        wget
      ];

      homebrew = {
        enable = true;
        brews = [
            "zstd"
            "libtiff"
            "webp"
            "aws-iam-authenticator"
            "aws-vault"
            "awscli"
            "libssh2"
            "bat"
            "freetype"
            "colima"
            "dasel"
            "docker-buildx"
            "dotnet"
            "exiftool"
            "fd"
            "unbound"
            "ffmpeg"
            "node"
            "firebase-cli"
            "fswatch"
            "fzf"
            "ghostscript"
            "git"
            "git-lfs"
            "gnupg"
            "go"
            "golangci-lint"
            "gource"
            "gradle"
            "graphviz"
            "grpcurl"
            "hadolint"
            "htop"
            "hyperfine"
            "libheif"
            "imagemagick"
            "jenv"
            "jpeg"
            "jpegoptim"
            "jq"
            "openjdk@11"
            "ki"
            "kotlin"
            "kubernetes-cli"
            "lsusb"
            "mas"
            "maven"
            "mozjpeg"
            "ncdu"
            "nmap"
            "node@20"
            "ollama"
            "openapi-generator"
            "openjdk@17"
            "openssl@1.1"
            "parallel"
            "pinentry-mac"
            "pipx"
            "pre-commit"
            "python@3.10"
            "python@3.11"
            "redis"
            "rename"
            "ruby"
            "rust"
            "rustup"
            "sevenzip"
            "sqlc"
            "terraformer"
            "tree"
            "vercel-cli"
            "virtualenv"
            "wget"
            "yamllint"
            "zip"
            "zlib"
            "buildpacks/tap/pack"
            "depot/tap/depot"
            "hashicorp/tap/terraform"
            "hashicorp/tap/vault"
            "humansignal/tap/label-studio"
            "lightbend/brew/kalix"
            "omissis/go-jsonschema/go-jsonschema"
            "oven-sh/bun/bun"
            "stripe/stripe-cli/stripe"
            "surrealdb/tap/surreal"
            "tursodatabase/tap/turso"
        ];
        casks = [
            "android-commandlinetools"
            "android-platform-tools"
            "anydesk"
            "betterdiscord-installer"
            "chrome-remote-desktop-host"
            "cloudflare-warp"
            "deepl"
            "discord"
            "docker"
            "firefox"
            "frappe-books"
            "ghidra"
            "google-chrome"
            "google-cloud-sdk"
            "google-drive"
            "intellij-idea"
            "iterm2"
            "jan"
            "jetbrains-toolbox"
            "little-snitch"
            "macfuse"
            "macpass"
            "multimc"
            "notion"
            "obs"
            "obs-virtualcam"
            "obsidian"
            "openaudible"
            "postman"
            "raycast"
            "responsively"
            "secretive"
            "signal"
            "sublime-text"
            "tailscale"
            "telegram"
            "timing"
            "tor-browser"
            "vlc"
            "warp"
            "whatsapp"
        ];
        masApps = {
            "Amphetamine" = 937984704;
            "AusweisApp" = 948660805;
            "Boop" = 1518425043;
            "Color Picker" = 1545870783;
            "Day Progress" = 6450280202;
            "Dice" = 1501716820;
            "Numbers" = 409203825;
            "Outbank" = 1094255754;
            "Pages" = 409201541;
            "Pastebot" = 1179623856;
            "Photo Anonymizator" = 1624700848;
            "Quick Camera" = 598853070;
            "Scaler" = 1612708557;
            "Sticky Notes" = 1150887374;
            "TripMode" = 1513400665;
            "WireGuard" = 1451685025;
        };
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
        onActivation.cleanup = "zap";
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # MacOS
      security.pam.enableSudoTouchIdAuth = true;
      system.defaults = {
        ActivityMonitor.IconType = null;
        ActivityMonitor.OpenMainWindow = true;
        ActivityMonitor.ShowCategory = null;
        ActivityMonitor.SortColumn = "CPUUsage";
        ActivityMonitor.SortDirection = 0;
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.controlcenter
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.dock
        finder.AppleShowAllExtensions = true;
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.finder
        hitoolbox.AppleFnUsageType = "Change Input Source";
        loginwindow.GuestEnabled = false;
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.loginwindow
        menuExtraClock.FlashDateSeparators = false;
        menuExtraClock.IsAnalog = null;
        menuExtraClock.Show24Hour = true;
        menuExtraClock.ShowDate = 0;
        menuExtraClock.ShowDayOfMonth = null;
        menuExtraClock.ShowDayOfWeek = null;
        menuExtraClock.ShowSeconds = true;
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.NSGlobalDomain
        screencapture.location = "~/Desktop";
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.screencapture
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.screensaver
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.smb
        SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
        spaces.spans-displays = null;
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.trackpad
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.universalaccess
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.WindowManager
      };
      # TODO: ADD https://mynixos.com/nix-darwin/options/system
      # TODO: ADD https://mynixos.com/nix-darwin/options/programs
      # TODO: ADD https://mynixos.com/nix-darwin/options/security
      # TODO: ADD https://mynixos.com/nix-darwin/options/services.tailscale

      time.timeZone = null;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Lars-MacBook-Air
    darwinConfigurations."Lars-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "larsartmann";

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;
          };
        }
      ];
    };
  };
}
