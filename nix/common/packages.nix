{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Essential tools
    git
    vim
    fish
    starship
    curl
    wget
    tree
    ripgrep
    fd
    eza
    bat
    jq
    yq-go
    just

    # Modern CLI productivity tools
    fzf
    glow
    bun
    git-town

    # Nix helper tools
    nh

    # Go development tools
    golangci-lint
    go
    gopls

    # Infrastructure as Code
    terraform

    # Security and development tools
    gitleaks
    pre-commit

    # AI development tools
    # crush # imported via flake input in main config

    # Shell completion and performance
    carapace

    # Modern CLI alternatives
    bottom
    procs
    sd
    dust

    # SSH
    openssh

    # Graph visualization
    graphviz
  ];
}
