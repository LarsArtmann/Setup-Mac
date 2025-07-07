{
  homebrew = {
    enable = true;
    taps = [
      # only needed for buildpacks/tap/pack: "buildpacks/tap"
      # only needed for depot/tap/depot: "depot/tap"
      "humansignal/tap" # needed for label-studio
      # only needed for lightbend/brew/kalix": "lightbend/brew"
      "omissis/go-jsonschema" # Needed for my CV project
      "tursodatabase/tap" # needed for turso
    ];
    brews = [
      # rarely used: "dasel"
      # Moved to Nixpkgs: "docker-buildx"
      # Moved to Nixpkgs: "dotnet"
      # Moved to Nixpkgs: "node"
      # Moved to Nixpkgs: "firebase-cli"
      # rarely used: "fswatch"
      # Moved to Nixpkgs: "gnupg"
      # Moved to Nixpkgs: "pinentry-mac"
      # rarely used: "golangci-lint"
      # rarely used: "gource"
      # rarely used: "grpcurl"
      # rarely used: "hadolint"
      "huggingface-cli" # No nix package found - 2025-02-15
      # Using JDK from Nixpkgs instead
      # "openjdk@11"
      "ki" # Kotlin Language Interactive Shell | No nix package found - 2025-02-15
      # rarely used: "lsusb"
      "mas"
      # Using JDK from Nixpkgs instead
      # "openjdk@17"
      "openssl@1.1" # Most likely not needed, for Sublime Text
      # rarely used: "parallel"
      # rarely used: "rename"
      # rarely used: "sevenzip" # nix only has p7zip
      # rarely used: "virtualenv"
      # rarely used: "buildpacks/tap/pack"
      # rarely used: "depot/tap/depot"
      "humansignal/tap/label-studio"
      # rarely used: "lightbend/brew/kalix"
      "omissis/go-jsonschema/go-jsonschema" # Needed for my CV project
    ];
    casks = [
      # rarely used: "android-commandlinetools"
      # rarely used: "android-platform-tools"
      # rarely used: "anydesk"
      "cloudflare-warp"
      "deepl" # No nix package found - 2025-02-15
      # "discord" # replaced by legcord
      # "docker" # switched to OrbStack - better performance and resource usage
      # Moved to Nixpkgs: "firefox"
      # rarely used: "ghidra"
      # Moved to Nixpkgs: "google-chrome"
      # Replaced with Nix package: "google-cloud-sdk"
      "google-drive"
      # rarely used since I switched to open-webui: "jan"
      "jetbrains-toolbox"
      "legcord" # lightweight Discord - nix package exist, but does not work on my MacOS version - 2025-04-28
      "little-snitch"
      "lulu" # Open source firewall to block unknown outgoing connections - https://objective-see.org/products/lulu.html
      "macfuse"
      "macpass"
      # rarely used: "multimc"
      "notion"
      "obs"
      "obs-virtualcam"
      "obsidian"
      "openaudible"
      "postman"
      "raycast"
      "responsively"
      "secretive"
      # Moved to Nixpkgs: "signal"
      "spotify" # Music streaming service
      "sublime-text"
      # Moved to Nixpkgs: "tailscale"
      # Moved to Nixpkgs: "telegram"
      # rarely used since it's not worth +96€ a year: "timing"
      # Moved to Nixpkgs: "tor-browser"
      # Moved to Nixpkgs: "vlc"
      "franz" # All in one messaging app - Because nixpkgs is BROKEN
      "whatsapp"
      "openzfs" # Nixpkgs not available for darwin
      "headlamp" # Kubernetes dashboard; Nixpkgs not available 2025-03-26
      "orbstack" # A better Docker runner for macOS; Nixpkgs not available 2025-04-14
      "rustdesk" # Remote desktop and screen sharing
      "activitywatch" # Activity tracking
    ];
    masApps = {
      # rarely used: "Amphetamine" = 937984704;
      "AusweisApp" = 948660805;
      # rarely used: "Boop" = 1518425043;
      "Color Picker" = 1545870783;
      # rarely used, cool but no real value: "Day Progress" = 6450280202;
      "Dice" = 1501716820;
      "Numbers" = 409203825;
      "Outbank" = 1094255754;
      # rarely used: "Pages" = 409201541;
      "Pastebot" = 1179623856;
      "Photo Anonymizator" = 1624700848;
      "Quick Camera" = 598853070;
      # rarely used: "Scaler" = 1612708557;
      # rarely used: "Sticky Notes" = 1150887374;
      "TripMode" = 1513400665;
      "WireGuard" = 1451685025;
    };
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
    };
  };
}
