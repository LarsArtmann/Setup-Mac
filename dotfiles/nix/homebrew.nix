{
  homebrew = {
    enable = true;
    greedyCasks = true;
    taps = [
      # only needed for buildpacks/tap/pack: "buildpacks/tap"
      # only needed for depot/tap/depot: "depot/tap"
      "fastrepl/hyprnote" # needed for hyprnote
      "humansignal/tap" # needed for label-studio
      # only needed for lightbend/brew/kalix": "lightbend/brew"
      "omissis/go-jsonschema" # Needed for my CV project
      "terrastruct/tap" # needed for tala
      "tursodatabase/tap" # needed for turso
    ];
    brews = [
      # rarely used: "dasel"
      # rarely used: "fswatch"
      # rarely used: "golangci-lint"
      # rarely used: "gource"
      # rarely used: "grpcurl"
      # rarely used: "hadolint"
      "huggingface-cli" # No nix package found - 2025-02-15
      "gh" # GitHub CLI - essential for development workflow
      # Using JDK from Nixpkgs instead
      # "openjdk@11"
      "ki" # Kotlin Language Interactive Shell | No nix package found - 2025-02-15
      # rarely used: "lsusb"
      "mas"
      # "openssl@1.1" # REMOVED: Deprecated upstream since 2024-10-24, breaks deployment
      # rarely used: "parallel"
      # rarely used: "rename"
      # rarely used: "sevenzip" # nix only has p7zip
      # rarely used: "virtualenv"
      # rarely used: "buildpacks/tap/pack"
      # rarely used: "depot/tap/depot"
      "humansignal/tap/label-studio"
      # rarely used: "lightbend/brew/kalix"
      "omissis/go-jsonschema/go-jsonschema" # Needed for my CV project
      "terrastruct/tap/tala" # Terrastruct layout engine
    ];
    casks = [
      # rarely used: "android-commandlinetools"
      # rarely used: "android-platform-tools"
      # rarely used: "anydesk"
      # "discord" # replaced by legcord
      # "docker" # switched to OrbStack - better performance and resource usage
      # Moved to Nixpkgs: "firefox"
      # rarely used: "ghidra"
      # Moved to Nixpkgs: "google-chrome"
      # Replaced with Nix package: "google-cloud-sdk"
      "google-drive"
      # rarely used since I switched to open-webui: "jan"
      "jetbrains-toolbox"
      # Fonts that require complex compilation in Nix
      "font-jetbrains-mono"
      "legcord" # lightweight Discord - nix package exist, but does not work on my MacOS version - 2025-04-28
      # "little-snitch" # REMOVED: Proprietary network monitoring tool
      "lulu" # Open source firewall to block unknown outgoing connections - https://objective-see.org/products/lulu.html
      # Security tools from Objective-See
      "blockblock" # Monitors persistence locations for malware
      "oversight" # Monitors microphone and webcam access
      "knockknock" # Shows what's persistently installed on your Mac
      # "dnd" # REMOVED: Cask no longer exists in Homebrew, breaks deployment
      "macfuse"
      "macpass"
      # rarely used: "multimc"
      "notion"
      "obs"
      # "obs-virtualcam" # REMOVED: Discontinued upstream on 2024-12-16 - OBS has built-in virtual camera support since v26.0
      "obsidian"
      "openaudible"
      "raycast"
      "responsively"
      "secretive"
      "spotify" # Music streaming service
      "sublime-text"
      # rarely used since it's not worth +96€ a year: "timing"
      "whatsapp"
      "openzfs" # Nixpkgs not available for darwin
      "headlamp" # Kubernetes dashboard; Nixpkgs not available 2025-03-26
      "hyprnote" # Note-taking app from fastrepl
      "orbstack" # A better Docker runner for macOS; Nixpkgs not available 2025-04-14
      "rustdesk" # Remote desktop and screen sharing
      "activitywatch" # Activity tracking
      "comfyui" # Node-based image, video and audio generator
      "godot" # Free and open source 2D and 3D game engine
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
