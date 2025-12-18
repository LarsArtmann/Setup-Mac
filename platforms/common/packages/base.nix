{ pkgs, lib, inputs, nix-ai-tools, ... }:

let
  # Import crush from nixpkgs instead of nix-ai-tools
  # nix-ai-tools is not properly configured as a flake input
  crush = pkgs.crush or null;

  # Import custom packages
  helium-pkg = import ./helium.nix { inherit lib pkgs; };

  # Essential CLI tools that work across platforms
  essentialPackages = with pkgs; [
    # Version control
    git
    git-town  # High-level Git workflow management

    # Essential editors
    vim

    # Terminal emulator
    alacritty-graphics

    # Shells and prompts
    fish
    starship

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
    glow  # Render markdown on the CLI, with pizzazz

    # System monitoring
    bottom
    procs

    # File utilities
    sd  # Modern find and replace
    dust  # Modern du

    # GNU utilities (cross-platform)
    coreutils
    findutils
    gnused

    # Graph visualization
    graphviz

    # Task management
    taskwarrior3
    timewarrior
  ];

  # Development tools (platform-agnostic)
  developmentPackages = with pkgs; [
    # JavaScript/TypeScript
    bun    # Incredibly fast JavaScript runtime

    # Go development
    go
    gopls
    golangci-lint

    # Infrastructure as Code
    terraform  # Infrastructure as Code tool from HashiCorp

    # Nix helper tools
    nh

    # Wallpaper management tools (Linux-only)
    imagemagick  # Image manipulation for wallpaper management
  ] ++ lib.optionals stdenv.isLinux [
    swww  # Simple Wayland Wallpaper for animated wallpapers (Linux-only)
  ];

  # GUI Applications (platform-specific)
  guiPackages = with pkgs; lib.optionals stdenv.isDarwin [
    # Import Helium browser
    (import ./helium.nix { inherit lib pkgs; })
  ] ++ lib.optionals (stdenv.isDarwin && config.allowUnfree or false) [
    google-chrome  # Chrome browser (unfree)
  ];

  # AI tools (conditionally added)
  aiPackages = lib.optional (crush != null) crush;

in
{
  # System packages list
  environment.systemPackages = essentialPackages ++ developmentPackages ++ guiPackages ++ aiPackages;
}