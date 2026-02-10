{
  pkgs,
  lib,
  llm-agents,
  helium,
  ...
}: let
  # Import custom packages
  crush-patched = import ../../../pkgs/crush-patched.nix {
    inherit pkgs;
  };

  # Import modernize from local pkgs if available
  inherit (pkgs.stdenv.hostPlatform) system;
  modernizePackage = (builtins.tryEval (import ../../../pkgs/modernize.nix {
    inherit pkgs;
  })).value or null;

  # Override gopls to remove modernize binary (we use our custom build)
  goplsWithoutModernize = pkgs.symlinkJoin {
    name = "gopls-without-modernize";
    paths = [ pkgs.gopls ];
    postBuild = ''
      rm -f $out/bin/modernize
    '';
  };

  # Import crush from llm-agents packages (only used as fallback)
  crush = llm-agents.packages.${system}.crush or pkgs.crush or null;
  heliumPackage = if builtins.hasAttr "packages" helium && builtins.hasAttr system helium.packages
    then (helium.packages.${system}.default or helium.packages.${system}.helium or null)
    else null;

  # Essential CLI tools that work across platforms
  essentialPackages = with pkgs;
    [
      # Version control
      git
      gh # GitHub CLI
      git-town # High-level Git workflow management
      jj # Git-compatible version control system

      # Essential editors
      micro
      neovim

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
      gnupg
      pre-commit
      openssh

      # Modern CLI productivity tools
      glow # Render markdown on the CLI, with pizzazz

      # System monitoring
      bottom
      procs
      btop
      htop

      # File utilities
      sd # Modern find and replace
      dust # Modern du

      # GNU utilities (cross-platform)
      coreutils
      findutils
      gnused

      # Graph visualization
      graphviz
      d2 # Declarative diagram scripting language

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
      nodejs # Node.js JavaScript runtime
      nodePackages.pnpm # Fast, disk space-efficient package manager
      vtsls # TypeScript language server for IDE LSP support
      esbuild # Fast JavaScript bundler and minifier

      # Go development
      go
      goplsWithoutModernize  # Custom override without modernize binary (use our custom build)
      golangci-lint
      gofumpt
      gotests
      mockgen
      protoc-gen-go
      buf
      delve
      gup

      # CGO build tools for Go
      gcc
      gnumake

      # Common libraries for CGO dependencies
      pkg-config

      # JavaScript/TypeScript development (Oxc tools)
      oxlint
      tsgolint
      oxfmt

      # Infrastructure as Code
      terraform # Infrastructure as Code tool from HashiCorp
      google-cloud-sdk # Google Cloud SDK for cloud management

      # Container tools
      docker # Docker CLI tools
      docker-compose # Multi-container Docker applications

      # Kubernetes tools
      kubectl # Kubernetes CLI (includes fish/zsh/bash completions!)
      k9s # Kubernetes CLI To Manage Your Clusters In Style

      # Nix helper tools
      nh

      # Wallpaper management tools (Linux-only)
      imagemagick # Image manipulation for wallpaper management
    ]
    ++ lib.optionals (modernizePackage != null) [ modernizePackage ]
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

      # Hardware monitoring (Linux-only)
      lm_sensors # Hardware monitoring (GPU/CPU temperature)

      # Additional ricing tools discovered from community configs
      hyprpicker # Color picker for Wayland
      swappy # Screenshot annotation tool
      imv # Minimal image viewer
      wf-recorder # Screen recorder
      brillo # Brightness control utility
      pamixer # PulseAudio command line mixer
      foot # Lightweight Wayland terminal emulator
      zellij # Modern terminal multiplexer
    ];

  # GUI Applications (cross-platform)
  guiPackages = with pkgs;
    (lib.optional (heliumPackage != null) heliumPackage)
    ++ [
      # Import platform-specific Helium browser - them disable
      #(
      #  if stdenv.isDarwin
      #  then (import ../../darwin/packages/helium.nix {inherit lib pkgs;})
      #  else (import ./helium-linux.nix {inherit lib pkgs;})
      #)
    ]
    ++ lib.optionals stdenv.isDarwin [
      google-chrome
      iterm2
      duti # macOS file association utility (used by activation scripts)
    ];

  # AI tools (using patched version with Lars' PRs)
  aiPackages = [crush-patched];
in {
  # System packages list
  environment.systemPackages = essentialPackages ++ developmentPackages ++ guiPackages ++ aiPackages ++ linuxUtilities;
}
