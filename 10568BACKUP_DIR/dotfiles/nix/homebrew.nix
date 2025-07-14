{
  homebrew = {
    enable = true;
    taps = [
      "humansignal/tap" # needed for label-studio
      "omissis/go-jsonschema" # Needed for my CV project
      "tursodatabase/tap" # needed for turso
    ];
    brews = [
      "huggingface-cli" # No nix package found - 2025-02-15
      "ki" # Kotlin Language Interactive Shell | No nix package found - 2025-02-15
      "mas"
      "openssl@1.1" # Most likely not needed, for Sublime Text
      "humansignal/tap/label-studio"
      "omissis/go-jsonschema/go-jsonschema" # Needed for my CV project
    ];
    casks = [
      "cloudflare-warp"
      "deepl" # No nix package found - 2025-02-15
      "google-drive"
      "jetbrains-toolbox"
      "legcord" # lightweight Discord - nix package exist, but does not work on my MacOS version - 2025-04-28
      "little-snitch"
      "lulu" # Open source firewall to block unknown outgoing connections - https://objective-see.org/products/lulu.html
      "macfuse"
      "macpass"
      "notion"
      "obs"
      "obs-virtualcam"
      "obsidian"
      "openaudible"
      "postman"
      "raycast"
      "responsively"
      "secretive"
      "spotify" # Music streaming service
      "sublime-text"
      "franz" # All in one messaging app - Because nixpkgs is BROKEN
      "whatsapp"
      "openzfs" # Nixpkgs not available for darwin
      "headlamp" # Kubernetes dashboard; Nixpkgs not available 2025-03-26
      "orbstack" # A better Docker runner for macOS; Nixpkgs not available 2025-04-14
      "rustdesk" # Remote desktop and screen sharing
      "activitywatch" # Activity tracking
    ];
    masApps = {
      "AusweisApp" = 948660805;
      "Color Picker" = 1545870783;
      "Dice" = 1501716820;
      "Numbers" = 409203825;
      "Outbank" = 1094255754;
      "Pastebot" = 1179623856;
      "Photo Anonymizator" = 1624700848;
      "Quick Camera" = 598853070;
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
