{ pkgs, lib, inputs, llm-agents, ... }:

let
  # Import crush from llm-agents packages
  # llm-agents provides CRUSH AI tool through its packages
  system = pkgs.stdenv.hostPlatform.system;
  crush = llm-agents.packages.${system}.crush or pkgs.crush or null;

  # Import custom packages
  helium-pkg = import ./helium.nix { inherit lib pkgs; };

  # Essential CLI tools that work across platforms
  essentialPackages = with pkgs; [
    # Version control
    git
    git-town  # High-level Git workflow management

    # Essential editors
    vim
    micro-full

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

  # GUI Applications (cross-platform)
  guiPackages = with pkgs; [
    # Import Helium browser (cross-platform)
    (import ./helium.nix { inherit lib pkgs; })
  ] ++ lib.optionals stdenv.isDarwin [
    google-chrome  # Chrome browser (unfree, macOS only)
  ];

  # AI tools (conditionally added)
  aiPackages = lib.optional (crush != null) crush;

in
{
  # System packages list
  environment.systemPackages = essentialPackages ++ developmentPackages ++ guiPackages ++ aiPackages;
}