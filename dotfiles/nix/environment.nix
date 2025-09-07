{ pkgs, lib, nix-ai-tools, ... }:

let
  homeDir = "/Users/larsartmann";

  # Validation helpers
  validateHomeDir = dir:
    if !lib.pathExists dir then
      lib.warn "Home directory ${dir} does not exist"
    else dir;

  validatePackage = pkg:
    if pkg == null then
      throw "Package cannot be null"
    else if !(lib.hasAttr "outPath" pkg) then
      throw "Invalid package provided"
    else pkg;

in
{
  # Enhanced environment configuration with validation
  assertions = [
    {
      assertion = homeDir != null && homeDir != "";
      message = "Home directory must be defined";
    }
    {
      assertion = pkgs.fish != null;
      message = "Fish shell package must be available";
    }
  ];

  environment = {
    # Enhanced environment configuration
    # Configure available shells for nix-darwin user management
    shells = [ pkgs.fish pkgs.zsh pkgs.bash ];

    # Additional environment settings for robustness
    etc = {
      # Create additional configuration files if needed
      # "nix/nix.conf".text = ''
      #   # Additional Nix configuration
      # '';
    };

    # Set Darwin configuration path for explicit configuration management
    # darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";

    variables = {
      # Core system settings
      EDITOR = "nano";
      LANG = "en_GB.UTF-8";
      SHELL = "${validatePackage pkgs.fish}/bin/fish"; # ULTIMATE MIN-MAX: Fish shell for performance

      # Optimize NIX_PATH for better performance
      NIX_PATH = lib.mkForce "nixpkgs=flake:nixpkgs";

      # Homebrew optimization
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_AUTO_UPDATE = "1";
      HOMEBREW_NO_INSTALL_CLEANUP = "1";
      HOMEBREW_NO_ENV_HINTS = "1";

      # Locale optimization
      LC_ALL = "en_GB.UTF-8";
      LC_CTYPE = "en_GB.UTF-8";

      # Development environment enhancements
      PAGER = "less";
      LESS = "-R -S -M +Gg";

      # Security and privacy
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      NEXT_TELEMETRY_DISABLED = "1";
      GATSBY_TELEMETRY_DISABLED = "1";

      # Performance optimizations
      NODE_OPTIONS = "--max-old-space-size=4096";
      NPM_CONFIG_AUDIT = "false";
      NPM_CONFIG_FUND = "false";

      # Development workflow
      DOCKER_BUILDKIT = "1";
      COMPOSE_DOCKER_CLI_BUILD = "1";

      # Build and deployment optimization
      NIXPKGS_ALLOW_UNFREE = "1";
      NIXPKGS_ALLOW_BROKEN = "0";  # Strict: No broken packages
      NIXPKGS_ALLOW_INSECURE = "0"; # Strict: No insecure packages

      # Go development optimization
      GOPROXY = "https://proxy.golang.org,direct";
      GOSUMDB = "sum.golang.org";
      GOMODCACHE = "${homeDir}/.cache/go/mod";
      GOCACHE = "${homeDir}/.cache/go/build";

      # Rust development optimization
      CARGO_HOME = "${homeDir}/.cargo";
      RUSTUP_HOME = "${homeDir}/.rustup";
      CARGO_TARGET_DIR = "${homeDir}/.cache/cargo/target";

      # Python development optimization
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONUNBUFFERED = "1";
      PIP_CACHE_DIR = "${homeDir}/.cache/pip";

      # Java development optimization
      GRADLE_USER_HOME = "${homeDir}/.gradle";
      MAVEN_OPTS = "-Xmx2g -XX:ReservedCodeCacheSize=1g";

      # Editor and tooling preferences
      VISUAL = "nano";
      BROWSER = "open";  # Use macOS default browser
      MANPAGER = "less -R";

      # macOS-specific optimizations
      TERM_PROGRAM = "iTerm.app";
      COLORTERM = "truecolor";

      # Privacy and tracking opt-outs
      DO_NOT_TRACK = "1";
      ADBLOCK = "1";
      DISABLE_OPENCOLLECTIVE = "1";
      OPEN_SOURCE_CONTRIBUTOR = "true";

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
        wire # Compile-time dependency injection for Go
        mockgen # Generate mocks for Go interfaces
        protoc-gen-go # Protocol buffer compiler for Go
        buf # Modern protobuf toolchain
        delve # Go debugger
        gup # Auto-update Go binaries installed via 'go install'

        jdk # Java Development Kit (JDK 21)
        kotlin
        nodejs # Node.js JavaScript runtime
        ruby
        # rust
        rustup # Rust toolchain installer
        bun # JavaScript runtime and package manager
        pnpm_10 # Fast, disk space efficient package manager for JavaScript
        dotnetCorePackages.sdk_8_0 # .NET Core SDK
        tailwindcss_4 # Utility-first CSS framework v4

        # Temporary disabled because of storage issues - and exiting installations via Toolbox
        #jetbrains.idea-ultimate
        #jetbrains.webstorm
        #jetbrains.goland
        #jetbrains.rider

        # Development utilities
        openapi-generator-cli # Generate API clients from OpenAPI specs
        # typespec # API specification language with rich features for the cloud - temporarily disabled due to build issues
        sqlc # Generate type-safe Go code from SQL
        graphviz # Graph visualization tools
        mermaid-cli # Generate diagrams from text in a similar manner as markdown
        d2 # Modern diagram scripting language
        yamllint # YAML linter
        tokei # Count code statistics
        firebase-tools # Firebase CLI
        docker-buildx # Docker Buildx CLI plugin
        gnupg # GnuPG
        pinentry_mac # Pinentry for macOS
        mitmproxy2swagger # Convert mitmproxy logs to OpenAPI spec
        uv # Ultra-fast Python package installer and resolver, written in Rust
        github-linguist # Programming language detection library and command-line tool
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
        #DISABLED since used rarely: terraformer # Generate Terraform files from existing infrastructure
        colmena # NixOS deployment tool

        # Other cloud tools
        stripe-cli # Command-line tool for Stripe
        #rustdesk       # Remote desktop and screen sharing; NOT for nix-darwin (latest check 2025-04-16)
      ] ++

      # Command line it self
      [
        # CORE: Shell stack - Fish + Carapace + Starship
        carapace # Universal completion engine (1000+ commands)
        starship # Cross-shell prompt
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

      # Security and network monitoring tools
      [
        gitleaks # Scan repos for secrets
        #DISABLED because of: VERY long build time (~5:30min) (seems like it has no caching) + rarely used: vault # Secret management
        mitmproxy # man in the middle proxy for intercepting HTTP requests
        netdata # Real-time performance monitoring tool
        adguardian # Terminal-based, real-time traffic monitoring
      ] ++

      # AI and ML tools
      [
        # DISABLED: temporary due to BROKEN build: ollama # Run LLMs locally
        code2prompt # Convert code to LLM prompts
        nix-ai-tools.packages.${pkgs.system}.crush # AI coding agent by Charmbracelet
      ] ++

      # Database tools
      [
        redis # In-memory database
        turso-cli # Edge database CLI
      ] ++

      # Applications
      [
        # Terminal emulators
        #DISABLED since iterm2 is preferred: alacritty # Terminal emulator
        #BROKEN version ghostty-1.1.3: ghostty # Fast, native, feature-rich terminal emulator
        iterm2 # Terminal emulator

        # Utilities
        keepassxc # Password manager
        beancount # Plain text accounting
        grandperspective # Disk usage visualization tool

        # Browsers and Internet
        firefox # Web browser
        google-chrome # Web browser
        # tor-browser-bundle-bin # Privacy-focused browser - temporarily disabled to test build
        tailscale # VPN service

        # Media
        # vlc # Media player - temporarily disabled
        #BROKE because of 'valgrind-3.25.1' dependency: tidal-hifi # Web version of Tidal running in electron with hifi support

        # Communication
        telegram-desktop # Messaging app
        signal-desktop-bin # Secure messaging app
        #BROKE because of 'valgrind-3.24.0' dependency: franz # All in one messaging app

        # Other
        #NO darwin support: activitywatch

        #ONLY PROBLEMS: sublime4 # Text editor for code, markup and prose
        #NO aarch64-apple-darwin support: cloudflare-warp # Optimized internet protocol
      ] ++

      # Shells (also defined in shells below)
      [
        zsh
        fish
        #SOME SMALL TEST PANICKED: nushell # Modern shell written in Rust
      ] ++

      # Fonts
      [
        jetbrains-mono
      ];

    shellAliases = {
      l = "ls -laSh";
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
