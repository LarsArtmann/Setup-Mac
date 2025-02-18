{
  homebrew = {
    enable = true;
    taps = [
      "homebrew/bundle"
      # only needed for buildpacks/tap/pack: "buildpacks/tap"
      # only needed for depot/tap/depot: "depot/tap"
      "humansignal/tap" # needed for lable-studio
      # only needed for lightbend/brew/kalix": "lightbend/brew"
      # only needed for omissis/go-jsonschema/go-jsonschema: "omissis/go-jsonschema"
      "tursodatabase/tap" # needed for turso
    ];
    brews = [
      # rarely used: "dasel"
      "docker-buildx"
      "dotnet"
      "node"
      "firebase-cli"
      # rarely used: "fswatch"
      "gnupg" # needed for GPG (e.g. git)
      "pinentry-mac" # needed for GPG (e.g. git)
      # rarely used: "golangci-lint"
      # rarely used: "gource"
      # rarely used: "grpcurl"
      # rarely used: "hadolint"
      "huggingface-cli" # No nix package found - 2025-02-15
      "openjdk@11"
      "ki" # Kotlin Language Interactive Shell | No nix package found - 2025-02-15
      "kubernetes-cli" # No nix package found - 2025-02-15
      # rarely used: "lsusb"
      "mas"
      "openjdk@17"
      "openssl@1.1" # Most likely not needed, for Sublime Text
      # rarely used: "parallel"
      # rarely used: "rename"
      # rarely used: "sevenzip" # nix only has p7zip
      # rarely used: "virtualenv"
      # rarely used: "buildpacks/tap/pack"
      # rarely used: "depot/tap/depot"
      "humansignal/tap/label-studio"
      # rarely used: "lightbend/brew/kalix"
      # rarely used: "omissis/go-jsonschema/go-jsonschema"
    ];
    casks = [
      # rarely used: "android-commandlinetools"
      # rarely used: "android-platform-tools"
      # rarely used: "anydesk"
      "cloudflare-warp"
      "deepl" # No nix package found - 2025-02-15
      "discord"
      "docker"
      "firefox"
      # rarely used: "ghidra"
      "google-chrome"
      "google-cloud-sdk"
      "google-drive"
      "intellij-idea"
      # rarely used since I switched to open-webui: "jan"
      "jetbrains-toolbox"
      "little-snitch"
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
      "signal"
      "sublime-text"
      "tailscale"
      "telegram"
      # rarely used since it's not worth +96€ a year: "timing"
      "tor-browser"
      "vlc"
      "whatsapp"
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
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";
  };
}
