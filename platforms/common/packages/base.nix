{
  pkgs,
  lib,
  llm-agents,
  ...
}: let
  # Import crush from llm-agents packages
  # llm-agents provides CRUSH AI tool through its packages
  inherit (pkgs.stdenv.hostPlatform) system;
  crush = llm-agents.packages.${system}.crush or pkgs.crush or null;

  # Import custom packages

  # Essential CLI tools that work across platforms
  essentialPackages = with pkgs;
    [
      # Version control
      git
      git-town # High-level Git workflow management

      # Essential editors
      micro

      # Terminal emulator
      alacritty-graphics

      # Shells and prompts
      fish
      starship
      carapace

      # File operations and browsing
      curl
      wget
      tree
      ripgrep
      fd
      eza
      bat

      # Data manipulation
      jq
      yq-go

      # Task runner
      just

      # Security tools
      gitleaks
      pre-commit
      openssh

      # Modern CLI productivity tools
      glow # Render markdown on the CLI, with pizzazz

      # System monitoring
      bottom
      procs
      btop

      # File utilities
      sd # Modern find and replace
      dust # Modern du

      # GNU utilities (cross-platform)
      coreutils
      findutils
      gnused

      # Graph visualization
      graphviz

      # Task management
      taskwarrior3
      timewarrior

      # Clipboard management (Linux-only, Wayland)
      # cliphist # Not available on Darwin (Linux-only package)
      # Desktop integration (cross-platform)
      xdg-utils # XDG desktop utilities for both platforms
    ]
    ++ lib.optionals stdenv.isLinux [
      cliphist # Wayland clipboard history for Linux
    ];

  # Development tools (platform-agnostic)
  developmentPackages = with pkgs;
    [
      # JavaScript/TypeScript
      bun # Incredibly fast JavaScript runtime

      # Go development
      go
      gopls
      golangci-lint

      # Infrastructure as Code
      terraform # Infrastructure as Code tool from HashiCorp

      # Nix helper tools
      nh

      # Wallpaper management tools (Linux-only)
      imagemagick # Image manipulation for wallpaper management
    ]
    ++ lib.optionals stdenv.isLinux [
      swww # Simple Wayland Wallpaper for animated wallpapers (Linux-only)
      geekbench_6 # Geekbench 6 includes AI/ML benchmarking capabilities (Linux-only)
    ];

  # Linux-specific utilities
  linuxUtilities = with pkgs;
    lib.optionals stdenv.isLinux [
      # Media streaming
      fcast-client # FCast Client Terminal, media streaming client
      fcast-receiver # FCast Receiver, media streaming receiver
      ffcast # Run commands on rectangular screen regions
      castnow # Command-line Chromecast player for Google Cast devices
    ];

  # GUI Applications (cross-platform)
  guiPackages = with pkgs;
    [
      # Import platform-specific Helium browser
      (
        if stdenv.isDarwin
        then (import ../../darwin/packages/helium.nix {inherit lib pkgs;})
        else (import ./helium-linux.nix {inherit lib pkgs;})
      )
    ]
    ++ lib.optionals stdenv.isDarwin [
      google-chrome
      iterm2
    ];

  # AI tools (conditionally added)
  aiPackages = lib.optional (crush != null) crush;
in {
  # System packages list
  environment.systemPackages = essentialPackages ++ developmentPackages ++ guiPackages ++ aiPackages ++ linuxUtilities;
}
