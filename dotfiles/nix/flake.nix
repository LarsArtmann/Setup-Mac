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
    colmena.url = "github:zhaofengli/colmena";
  };

  #TODO: Configure standard apps (e.g. what program is used when I open a .json file) for my mac in Nix config.

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, ... }:
  let
    configuration = { pkgs, lib, overlays, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep <PACKAGE_NAME>
      environment.systemPackages = with pkgs; [
        age
        awscli2
        aws-iam-authenticator
        aws-vault
        bat # Cat(1) clone with syntax highlighting and Git integration.
        bun # JavaScript runtime, bundler, transpiler and package manager – all in one.
        fd # Simple, fast and user-friendly alternative to find.
        comma
        colmena # Simple, stateless NixOS deployment tool
        go
        git
        git-lfs
        gradle
        ffmpeg
        fzf
        htop
        graphviz
        unbound
        pre-commit
        ncdu # Disk usage analyzer with an ncurses interface.
        maven
        hyperfine # Command-line benchmarking tool
        kotlin
        terraformer # CLI tool to generate terraform files from existing infrastructure (reverse Terraform). Infrastructure to Code.
        exiftool # Tool to read, write and edit EXIF meta information
        redis
        ruby
        # rust
        rustup # Rust toolchain installer.
        openapi-generator-cli # Allows generation of API client libraries (SDK generation), server stubs and documentation automatically given an OpenAPI Spec.
        yamllint
        tree # Command to produce a depth indented directory listing
        nmap # Free and open source utility for network discovery and security auditing.
        jq
        kubernetes-helm # Package manager for kubernetes
        kubectl # Kubernetes cluster's control plane
        jqp # TUI playground to experiment with jq
        sqlc # Generate type-safe code from SQL for golang
        nh # For nix clean
        ollama # Get up and running with large language models locally
        #ONLY PROBLEMS: sublime4 # Sophisticated text editor for code, markup and prose
        #DO NOT move before backup!: signal-desktop # Signal Desktop is an Electron application that links with your “Signal Android” or “Signal iOS” app.
        wget
        #NO aarch64-apple-darwin support: cloudflare-warp # Replaces the connection between your device and the Internet with a modern, optimized, protocol
        zsh
        nushell # Modern shell written in Rust
        zip
        stripe-cli # Command-line tool for Stripe.
        vault # Tool for managing secrets.
        terraform # Tool for building, changing, and versioning infrastructure.
        turso-cli # This is the command line interface (CLI) to Turso.
        zlib # Lossless data-compression library.
        zstd # Zstandard - Fast real-time compression algorithm
      ];

       nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
         "vault" # ‘bsl11’ licence
         "terraform" # ‘bsl11’ licence
         #"cloudflare-warp" # ‘unfree’ licence
       ];

      environment.shellAliases = {
        l = "ls -laSh";
        nixup = "darwin-rebuild switch";
        mkdir = "mkdir -p";
      };

      homebrew = {
        enable = true;
        taps = [
          "homebrew/bundle"
          "buildpacks/tap"
          "depot/tap"
          "hashicorp/tap"
          "humansignal/tap"
          "lightbend/brew"
          "omissis/go-jsonschema"
          "tursodatabase/tap"
        ];
        brews = [
            "dasel"
            "docker-buildx"
            "dotnet"
            "node"
            "firebase-cli"
            "fswatch"
            "gnupg"
            "golangci-lint"
            "gource"
            "grpcurl"
            "hadolint"
            "huggingface-cli" # No nix package found - 2025-02-15
            "libheif"
            "imagemagick"
            "openjdk@11"
            "ki" # Kotlin Language Interactive Shell | No nix package found - 2025-02-15
            "kubernetes-cli" # No nix package found - 2025-02-15
            "lsusb"
            "mas"
            "mozjpeg"
            "openjdk@17"
            "openssl@1.1" # Most likely not needed, for Sublime Text
            "parallel"
            "pinentry-mac"
            "rename"
            "sevenzip" # nix only has p7zip
            "virtualenv"
            "buildpacks/tap/pack"
            "depot/tap/depot"
            "humansignal/tap/label-studio"
            "lightbend/brew/kalix"
            "omissis/go-jsonschema/go-jsonschema"
        ];
        casks = [
            "android-commandlinetools"
            "android-platform-tools"
            "anydesk"
            "cloudflare-warp"
            "deepl" # No nix package found - 2025-02-15
            "discord"
            "docker"
            "firefox"
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
        controlcenter.BatteryShowPercentage = true;
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.controlcenter
        # TODO: ADD https://mynixos.com/nix-darwin/options/system.defaults.dock
        finder.AppleShowAllExtensions = true;
        finder.AppleShowAllFiles = true;
        finder.FXEnableExtensionChangeWarning = true;
        finder.FXRemoveOldTrashItems = false; # Remove items from the Trash after 30 days
        finder.ShowPathbar = true;
        finder.ShowStatusBar = true;
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
        NSGlobalDomain.AppleShowAllFiles = true;
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.AppleTemperatureUnit = "Celsius";
        NSGlobalDomain.AppleMeasurementUnits = "Centimeters";
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

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        l = "ls -laSh";
        rm = "rm -i";
        nixup = "darwin-rebuild switch";
        mkdir = "mkdir -p";
      };
      histSize = 10000;
      oh-my-zsh = {
          enable = true;
          plugins = [
            "aliases"
          ];
          theme = "robbyrussell";
        };
    };

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = " /etc/nix-darwin/";
    };

    programs.git = {
      enable = true;
      lfs.enable = true;
      userName = "Lars Artmann";
      userEmail = "git@lars.softare";
    };
  };
}
