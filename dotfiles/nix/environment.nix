{ pkgs, lib, ... }:

let
  homeDir = "/Users/larsartmann";
in
{
  environment = {
    # TODO: https://mynixos.com/nix-darwin/options/environment
    #darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";

    variables = {
      EDITOR = "nano";
      LANG = "en_GB.UTF-8";
      SHELL = "${pkgs.nushell}/bin/nu"; # Dynamic reference to nushell package
      #NIX_PATH = "$HOME/.nix-defexpr/channels:nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels";

      # Custom PATH configuration
      PATH =
        lib.concatStringsSep ":" [
          # Homebrew paths
          "/opt/homebrew/bin"
          "/opt/homebrew/sbin"

          # Nix paths
          "${homeDir}/.nix-profile/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"

          # System paths
          "/usr/local/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"

          # Tool-specific paths
          "${homeDir}/Library/Application Support/JetBrains/Toolbox/scripts"
          "${homeDir}/.local/bin"
          "${homeDir}/go/bin"
          "${homeDir}/.bun/bin"
          "${homeDir}/.turso"
          "${homeDir}/.orbstack/bin"
        ];

      # Java Home configuration - using Nix-installed JDK 21
      JAVA_HOME = "${pkgs.jdk}/lib/openjdk";
    };

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep <PACKAGE_NAME>
    systemPackages = with pkgs;
      # Development tools
      [
        # Version control
        git
        git-lfs
        git-town # Git workflow manager
        github-cli
        lazygit
        pre-commit

        # Build tools
        gradle
        maven
        just # Task runner similar to make
        devenv # Developer environments

        # Programming languages and runtimes
        go
        jdk             # Java Development Kit (JDK 21)
        kotlin
        # nodejs          # Node.js JavaScript runtime - temporarily disabled
        ruby
        # rust
        rustup          # Rust toolchain installer
        # bun             # JavaScript runtime and package manager - temporarily disabled
        # pnpm_10         # Fast, disk space efficient package manager for JavaScript - temporarily disabled
        # dotnetCorePackages.sdk_8_0 # .NET Core SDK - temporarily disabled

        # Temporary disabled because of storage issues
        #jetbrains.idea-ultimate
        #jetbrains.webstorm
        #jetbrains.goland
        #jetbrains.rider

        # Development utilities
        openapi-generator-cli # Generate API clients from OpenAPI specs
        # typespec # API specification language with rich features for the cloud - temporarily disabled due to build issues
        sqlc # Generate type-safe Go code from SQL
        graphviz # Graph visualization tools
        yamllint # YAML linter
        tokei # Count code statistics
        # firebase-tools # Firebase CLI - temporarily disabled
        # docker-buildx # Docker Buildx CLI plugin - temporarily disabled
        gnupg # GnuPG
        pinentry_mac # Pinentry for macOS
      ] ++

      # Cloud and infrastructure tools
      [
        # Google Cloud
        google-cloud-sdk # Google Cloud Platform CLI

        # AWS
        awscli2
        aws-iam-authenticator
        aws-vault

        # Kubernetes
        kubectl # Kubernetes control plane
        kubernetes-helm # Package manager for Kubernetes
        k9s # Kubernetes CLI to manage clusters in real-time
        cilium-cli # CLI for Cilium
        k8sgpt # Kubernetes LLM CLI
        helmfile # Declarative spec for deploying Helm charts

        # Infrastructure as Code
        terraform # Infrastructure as code
        terraformer # Generate Terraform files from existing infrastructure
        colmena # NixOS deployment tool

        # Other cloud tools
        stripe-cli # Command-line tool for Stripe
        #rustdesk       # Remote desktop and screen sharing; NOT for nix-darwin (lastest check 2025-04-16)
      ] ++

      # Command line utilities
      [
        # File and text manipulation
        bat # Better cat with syntax highlighting
        fd # Alternative to find
        fzf # Fuzzy finder
        jq # JSON processor
        jqp # TUI playground for jq
        tree # Directory listing
        ncdu # Disk usage analyzer
        zip # Compression utility
        zlib # Compression library
        zstd # Fast compression algorithm

        # System utilities
        htop # Process viewer
        hyperfine # Command-line benchmarking tool
        nmap # Network discovery and security auditing
        duti # Set default applications

        # Nix utilities
        comma # Run commands without installing them
        nh # Nix helper tools

        # Other utilities
        wget # File downloader
        age # Encryption tool
      ] ++

      # Media tools
      [
        ffmpeg # Audio/video converter
        imagemagick # Image manipulation
        exiftool # Read/write EXIF metadata
      ] ++

      # Security tools
      [
        gitleaks # Scan repos for secrets
        vault # Secret management
      ] ++

      # AI and ML tools
      [
        ollama # Run LLMs locally
        code2prompt # Convert code to LLM prompts
        code-cursor # AI-powered code editor
      ] ++

      # Database tools
      [
        redis # In-memory database
        turso-cli # Edge database CLI
      ] ++

      # Applications
      [
        # Terminal emulators
        alacritty # Terminal emulator
        iterm2 # Terminal emulator

        # Utilities
        keepassxc # Password manager
        beancount # Plain text accounting
        grandperspective # Disk usage visualization tool

        # Browsers and Internet
        # firefox # Web browser - temporarily disabled
        # google-chrome # Web browser - temporarily disabled to test build
        # tor-browser-bundle-bin # Privacy-focused browser - temporarily disabled to test build
        # tailscale # VPN service - temporarily disabled

        # Media
        # vlc # Media player - temporarily disabled

        # Communication
        # telegram-desktop # Messaging app - temporarily disabled to test build
        # signal-desktop # Secure messaging app - temporarily disabled to test build

        #ONLY PROBLEMS: sublime4 # Text editor for code, markup and prose
        #NO aarch64-apple-darwin support: cloudflare-warp # Optimized internet protocol
      ] ++

      # Shells (also defined in shells below)
      [
        zsh
        nushell # Modern shell written in Rust
      ] ++

      # Fonts
      [
        jetbrains-mono
      ];

    shells = with pkgs; [
      bashInteractive
      zsh
      nushell
    ];
    shellAliases = {
      l = "ls -la";
      nixup = "darwin switch";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      diskStealer = "ncdu -x --exclude /Users/larsartmann/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
    };
  };
}
