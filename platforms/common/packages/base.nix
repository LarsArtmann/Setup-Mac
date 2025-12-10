{ pkgs, lib, inputs, nix-ai-tools, ... }:

let
  # Import crush from nix-ai-tools if available
  # crush = nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system} or {}."crush" or null;
  crush = null; # Temporarily disabled due to build error (returning set instead of package)

  # Essential CLI tools that work across platforms
  essentialPackages = with pkgs; [
    # Version control
    git
    git-town  # High-level Git workflow management

    # Essential editors
    vim

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

    # Wallpaper management tools
    swww  # Simple Wayland Wallpaper for animated wallpapers
    imagemagick  # Image manipulation for wallpaper management
  ];

  # AI tools (conditionally added)
  aiPackages = lib.optional (crush != null) crush;

in
{
  # System packages list
  environment.systemPackages = essentialPackages ++ developmentPackages ++ aiPackages;
}