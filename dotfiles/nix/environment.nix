{ pkgs,... }: {
  environment = {
    # TODO: https://mynixos.com/nix-darwin/options/environment
    #darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";

    variables = {
      EDITOR = "nano";
      LANG = "en_GB.UTF-8";
      SHELL = "$HOME/.nix-profile/bin/nu";# TODO make dynamic, something like: "${pkgs.nu}";
      #NIX_PATH = "$HOME/.nix-defexpr/channels:nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels";
    };

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep <PACKAGE_NAME>
    systemPackages = with pkgs;
      # Development tools
      [
        # Version control
        git
        git-lfs
        github-cli
        lazygit
        pre-commit

        # Build tools
        gradle
        maven
        just            # Task runner similar to make
        devenv          # Developer environments

        # Programming languages and runtimes
        go
        kotlin
        ruby
        # rust
        rustup          # Rust toolchain installer
        bun             # JavaScript runtime and package manager
        pnpm_10         # Fast, disk space efficient package manager for JavaScript

        # Development utilities
        openapi-generator-cli  # Generate API clients from OpenAPI specs
        sqlc            # Generate type-safe Go code from SQL
        graphviz        # Graph visualization tools
        yamllint        # YAML linter
        tokei           # Count code statistics
      ] ++

      # Cloud and infrastructure tools
      [
        # AWS
        awscli2
        aws-iam-authenticator
        aws-vault

        # Kubernetes
        kubectl         # Kubernetes control plane
        kubernetes-helm # Package manager for Kubernetes
        k9s             # Kubernetes CLI to manage clusters in real-time
        cilium-cli      # CLI for Cilium
        k8sgpt          # Kubernetes LLM CLI
        helmfile        # Declarative spec for deploying Helm charts

        # Infrastructure as Code
        terraform       # Infrastructure as code
        terraformer     # Generate Terraform files from existing infrastructure
        colmena         # NixOS deployment tool

        # Other cloud tools
        stripe-cli      # Command-line tool for Stripe
        #rustdesk       # Remote desktop and screen sharing; NOT for nix-darwin (lastest check 2025-04-16)
      ] ++

      # Command line utilities
      [
        # File and text manipulation
        bat             # Better cat with syntax highlighting
        fd              # Alternative to find
        fzf             # Fuzzy finder
        jq              # JSON processor
        jqp             # TUI playground for jq
        tree            # Directory listing
        ncdu            # Disk usage analyzer
        zip             # Compression utility
        zlib            # Compression library
        zstd            # Fast compression algorithm

        # System utilities
        htop            # Process viewer
        hyperfine       # Command-line benchmarking tool
        nmap            # Network discovery and security auditing
        duti            # Set default applications

        # Nix utilities
        comma           # Run commands without installing them
        nh              # Nix helper tools

        # Other utilities
        wget            # File downloader
        age             # Encryption tool
      ] ++

      # Media tools
      [
        ffmpeg          # Audio/video converter
        imagemagick     # Image manipulation
        exiftool        # Read/write EXIF metadata
      ] ++

      # Security tools
      [
        gitleaks        # Scan repos for secrets
        vault           # Secret management
      ] ++

      # AI and ML tools
      [
        ollama          # Run LLMs locally
        code2prompt     # Convert code to LLM prompts
        code-cursor     # AI-powered code editor
      ] ++

      # Database tools
      [
        redis           # In-memory database
        turso-cli       # Edge database CLI
      ] ++

      # Applications
      [
        alacritty       # Terminal emulator
        iterm2          # Terminal emulator
        keepassxc       # Password manager
        beancount       # Plain text accounting
        #ONLY PROBLEMS: sublime4 # Text editor for code, markup and prose
        #DO NOT move before backup!: signal-desktop # Signal Desktop is an Electron application that links with your "Signal Android" or "Signal iOS" app.
        #NO aarch64-apple-darwin support: cloudflare-warp # Optimized internet protocol
      ] ++

      # Shells (also defined in shells below)
      [
        zsh
        nushell         # Modern shell written in Rust
      ];

    shells = with pkgs; [
      bashInteractive
      zsh
      nushell
    ];
    shellAliases = {
      t = "echo 'Test :)'";
      l = "ls -laSh";
      nixup = "nh darwin switch $HOME/Desktop/Setup-Mac/dotfiles/nix/";
      mkdir = "mkdir -p";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      firebase-login = "firebase login";
      gcloud-init = "gcloud init";
      gcloud-components-install = "gcloud components install cbt alpha beta";
    };
  };
}
