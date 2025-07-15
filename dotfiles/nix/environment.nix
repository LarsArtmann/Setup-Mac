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
      SHELL = "${pkgs.fish}/bin/fish"; # ULTIMATE MIN-MAX: Fish shell for performance

      # Optimize NIX_PATH for better performance
      NIX_PATH = lib.mkForce "nixpkgs=flake:nixpkgs";

      # Disable automatic homebrew analytics for faster startup
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_AUTO_UPDATE = "1";

      # Optimize locale settings
      LC_ALL = "en_GB.UTF-8";

      # Custom PATH configuration - optimized for performance
      # Order: most frequently used first, system paths last
      PATH =
        lib.concatStringsSep ":" [
          # High-frequency development tools first
          "${homeDir}/.local/bin"
          "${homeDir}/go/bin"
          "${homeDir}/.bun/bin"

          # Homebrew paths (frequently used)
          "/opt/homebrew/bin"
          "/opt/homebrew/sbin"

          # Nix paths (managed packages)
          "${homeDir}/.nix-profile/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"

          # Tool-specific paths (less frequent)
          "${homeDir}/Library/Application Support/JetBrains/Toolbox/scripts"
          "${homeDir}/.turso"
          "${homeDir}/.orbstack/bin"

          # System paths (fallback, lowest priority)
          "/usr/local/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
        ];

      # Java Home configuration - COMMENTED OUT for minimal build
      # JAVA_HOME = "${pkgs.jdk}/lib/openjdk";
    };

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep <PACKAGE_NAME>
    systemPackages = with pkgs;
      # MINIMAL CONFIGURATION: Essential packages only
      [
        # CORE: Version control
        git
        github-cli

        # CORE: Essential dev tools
        go
        just # Task runner similar to make

        # CORE: Shell stack - Fish + Carapace + Starship
        fish # Modern shell with smart features
        carapace # Universal completion engine (1000+ commands)
        starship # Cross-shell prompt

        # CORE: File and text utilities
        bat # Better cat with syntax highlighting
        fd # Alternative to find
        fzf # Fuzzy finder
        jq # JSON processor
        ripgrep # Fast grep replacement (rg command)
        tree # Directory listing

        # CORE: System utilities
        htop # Process viewer
        wget # File downloader

        # COMMENTED OUT: Non-essential packages for minimal build
        # git-lfs
        # git-town # Git workflow manager
        # lazygit
        # pre-commit

        # Build tools - COMMENTED OUT
        # gradle
        # maven
        # devenv # Developer environments

        # Programming languages and runtimes - COMMENTED OUT
        # templ # Go HTML template language and tool
        # go-tools # Go static analysis tools (staticcheck.dev)

        # Go development tools - COMMENTED OUT
        # golangci-lint # Fast linters runner for Go
        # gofumpt # Stricter gofmt
        # gopls # Go language server
        # gotests # Generate Go tests
        # wire # Compile-time dependency injection for Go
        # mockgen # Generate mocks for Go interfaces
        # protoc-gen-go # Protocol buffer compiler for Go
        # buf # Modern protobuf toolchain
        # delve # Go debugger
        # gup # Auto-update Go binaries installed via 'go install'

        # jdk # Java Development Kit (JDK 21)
        # kotlin
        # nodejs # Node.js JavaScript runtime
        # ruby
        # rustup # Rust toolchain installer
        # bun # JavaScript runtime and package manager
        # pnpm_10 # Fast, disk space efficient package manager for JavaScript
        # dotnetCorePackages.sdk_8_0 # .NET Core SDK

        # Development utilities - COMMENTED OUT
        # openapi-generator-cli # Generate API clients from OpenAPI specs
        # sqlc # Generate type-safe Go code from SQL
        # graphviz # Graph visualization tools
        # yamllint # YAML linter
        # tokei # Count code statistics
        # firebase-tools # Firebase CLI
        # docker-buildx # Docker Buildx CLI plugin
        # gnupg # GnuPG
        # pinentry_mac # Pinentry for macOS
        # mitmproxy2swagger # Convert mitmproxy logs to OpenAPI spec
        # uv # Ultra-fast Python package installer and resolver, written in Rust

        # Cloud and infrastructure tools - COMMENTED OUT
        # google-cloud-sdk # Google Cloud Platform CLI
        # awscli2
        # aws-iam-authenticator
        # aws-vault
        # kubectl # Kubernetes control plane
        # kubernetes-helm # Package manager for Kubernetes
        # k9s # Kubernetes CLI to manage clusters in real-time
        # cilium-cli # CLI for Cilium
        # k8sgpt # Kubernetes LLM CLI
        # helmfile # Declarative spec for deploying Helm charts
        # terraform # Infrastructure as code
        # colmena # NixOS deployment tool
        # stripe-cli # Command-line tool for Stripe

        # Command line utilities - COMMENTED OUT
        # glow # Markdown renderer for the terminal
        # jqp # TUI playground for jq
        # yq-go # YAML processor (Go implementation)
        # ncdu # Disk usage analyzer
        # zip # Compression utility
        # zlib # Compression library
        # zstd # Fast compression algorithm
        # zsh-defer # Async zsh plugin loading (keeping for compatibility)
        # hyperfine # Command-line benchmarking tool
        # nmap # Network discovery and security auditing
        # duti # Set default applications
        # comma # Run commands without installing them
        # nh # Nix helper tools
        # age # Encryption tool
        # treefmt # Universal code formatter for multiple languages

        # Media tools - COMMENTED OUT
        # ffmpeg # Audio/video converter
        # imagemagick # Image manipulation
        # exiftool # Read/write EXIF metadata

        # Security tools - COMMENTED OUT
        # gitleaks # Scan repos for secrets
        # mitmproxy # man in the middle proxy for intercepting HTTP requests

        # AI and ML tools - COMMENTED OUT
        # ollama # Run LLMs locally
        # code2prompt # Convert code to LLM prompts

        # Database tools - COMMENTED OUT
        # redis # In-memory database
        # turso-cli # Edge database CLI

        # Applications - COMMENTED OUT
        # iterm2 # Terminal emulator
        # keepassxc # Password manager
        # beancount # Plain text accounting
        # grandperspective # Disk usage visualization tool
        # firefox # Web browser
        # google-chrome # Web browser
        # tailscale # VPN service
        # telegram-desktop # Messaging app
        # signal-desktop-bin # Secure messaging app

        # Shells - COMMENTED OUT
        # zsh
        # nushell # Modern shell written in Rust

        # Fonts - COMMENTED OUT
        # jetbrains-mono
      ];

    shells = with pkgs; [
      bashInteractive
      zsh
      fish
      nushell
    ];
    shellAliases = {
      l = "ls -la";
      t = "tree -h -L 2 -C --dirsfirst";
      nixup = "darwin-rebuild switch";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
      diskStealer = "ncdu -x --exclude /Users/larsartmann/Library/CloudStorage/GoogleDrive-lartyhd@gmail.com/";

      # Performance aliases
      path = "echo $PATH | tr ':' '\\n' | nl";
      envclean = "env | sort | less";
    };

    # Optimize shell initialization
    shellInit = ''
      # Disable homebrew auto-update check in shells
      export HOMEBREW_NO_AUTO_UPDATE=1
      export HOMEBREW_NO_ANALYTICS=1

      # Optimize terminal performance
      export TERM=xterm-256color

      # Reduce history size for better memory usage
      export HISTSIZE=5000
      export SAVEHIST=5000
    '';
  };
}
