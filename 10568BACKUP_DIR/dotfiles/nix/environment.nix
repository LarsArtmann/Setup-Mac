{ pkgs, lib, ... }:

let
  homeDir = "/Users/larsartmann";
in
{
  environment = {

    variables = {
      EDITOR = "nano";
      LANG = "en_GB.UTF-8";
      SHELL = "${pkgs.nushell}/bin/nu"; # Dynamic reference to nushell package

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
        templ # Go HTML template language and tool
        go-tools # Go static analysis tools (staticcheck.dev)

        # Go development tools
        golangci-lint # Fast linters runner for Go
        gofumpt # Stricter gofmt
        gopls # Go language server
        gotests # Generate Go tests
        go-wire # Compile-time dependency injection for Go
        mockgen # Generate mocks for Go interfaces
        protoc-gen-go # Protocol buffer compiler for Go
        buf # Modern protobuf toolchain
        delve # Go debugger
        jdk # Java Development Kit (JDK 21)
        kotlin
        nodejs # Node.js JavaScript runtime
        ruby
        rustup # Rust toolchain installer
        bun # JavaScript runtime and package manager
        pnpm_10 # Fast, disk space efficient package manager for JavaScript
        dotnetCorePackages.sdk_8_0 # .NET Core SDK


        # Development utilities
        openapi-generator-cli # Generate API clients from OpenAPI specs
        sqlc # Generate type-safe Go code from SQL
        graphviz # Graph visualization tools
        yamllint # YAML linter
        tokei # Count code statistics
        firebase-tools # Firebase CLI
        docker-buildx # Docker Buildx CLI plugin
        gnupg # GnuPG
        pinentry_mac # Pinentry for macOS
        mitmproxy2swagger # Convert mitmproxy logs to OpenAPI spec
        uv # Ultra-fast Python package installer and resolver, written in Rust
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
        colmena # NixOS deployment tool

        # Other cloud tools
        stripe-cli # Command-line tool for Stripe
      ] ++

      # Command line utilities
      [
        # File and text manipulation
        bat # Better cat with syntax highlighting
        glow # Markdown renderer for the terminal
        fd # Alternative to find
        fzf # Fuzzy finder
        jq # JSON processor
        jqp # TUI playground for jq
        yq-go # YAML processor (Go implementation)
        ripgrep # Fast grep replacement (rg command)
        tree # Directory listing
        ncdu # Disk usage analyzer
        zip # Compression utility
        zlib # Compression library
        zstd # Fast compression algorithm
        starship # Cross-shell prompt
        zsh-defer # Async zsh plugin loading

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
        treefmt # Universal code formatter for multiple languages
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
        mitmproxy # man in the middle proxy for intercepting HTTP requests
      ] ++

      # AI and ML tools
      [
        ollama # Run LLMs locally
        code2prompt # Convert code to LLM prompts
      ] ++

      # Database tools
      [
        redis # In-memory database
        turso-cli # Edge database CLI
      ] ++

      # Applications
      [
        # Terminal emulators
        iterm2 # Terminal emulator

        # Utilities
        keepassxc # Password manager
        beancount # Plain text accounting
        grandperspective # Disk usage visualization tool

        # Browsers and Internet
        firefox # Web browser
        google-chrome # Web browser
        tailscale # VPN service

        # Media
        tidal-hifi # Web version of Tidal running in electron with hifi support

        # Communication
        telegram-desktop # Messaging app
        signal-desktop-bin # Secure messaging app

        # Other

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
      t = "tree -h -L 2 -C --dirsfirst";
      nixup = "darwin-rebuild switch";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      diskStealer = "ncdu -x --exclude /Users/larsartmann/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";
    };
  };
}
