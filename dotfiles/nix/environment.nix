{ pkgs, ... }: {
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
    systemPackages = with pkgs; [
      age
      awscli2
      aws-iam-authenticator
      aws-vault
      bat # Cat(1) clone with syntax highlighting and Git integration.
      bun # JavaScript runtime, bundler, transpiler and package manager – all in one.
      fd # Simple, fast and user-friendly alternative to find.
      comma
      colmena # Simple, stateless NixOS deployment tool
      code2prompt # A CLI tool to convert your codebase into a single LLM prompt with source tree, prompt templating, and token counting. - https://github.com/mufeedvh/code2prompt?tab=readme-ov-file
      go
      git
      git-lfs
      gradle
      ffmpeg
      fzf
      htop
      graphviz
      pre-commit
      ncdu # Disk usage analyzer with an ncurses interface.
      maven
      hyperfine # Command-line benchmarking tool
      kotlin
      terraformer # CLI tool to generate terraform files from existing infrastructure (reverse Terraform). Infrastructure to Code.
      exiftool # Tool to read, write and edit EXIF meta information
      redis
      ruby
      # rust
      rustup # Rust toolchain installer.
      openapi-generator-cli # Allows generation of API client libraries (SDK generation), server stubs and documentation automatically given an OpenAPI Spec.
      yamllint
      tree # Command to produce a depth indented directory listing
      nmap # Free and open source utility for network discovery and security auditing.
      jq
      kubernetes-helm # Package manager for kubernetes
      kubectl # Kubernetes cluster's control plane
      jqp # TUI playground to experiment with jq
      sqlc # Generate type-safe code from SQL for golang
      nh # For nix clean
      ollama # Get up and running with large language models locally
      #ONLY PROBLEMS: sublime4 # Sophisticated text editor for code, markup and prose
      #DO NOT move before backup!: signal-desktop # Signal Desktop is an Electron application that links with your “Signal Android” or “Signal iOS” app.
      wget
      #NO aarch64-apple-darwin support: cloudflare-warp # Replaces the connection between your device and the Internet with a modern, optimized, protocol
      zsh
      iterm2 # command line terminal
      nushell # Modern shell written in Rust
      zip
      imagemagick # Software suite to create, edit, compose, or convert bitmap images
      stripe-cli # Command-line tool for Stripe.
      vault # Tool for managing secrets.
      terraform # Tool for building, changing, and versioning infrastructure.
      turso-cli # This is the command line interface (CLI) to Turso.
      zlib # Lossless data-compression library.
      zstd # Zstandard - Fast real-time compression algorithm
      gitleaks # Scan git repos (or files) for secrets
      beancount # Double-entry bookkeeping computer language
      code-cursor # AI-powered code editor built on vscode
      duti  # Utility to set default applications
      pnpm_10 # Fast, disk space efficient package manager for JavaScript
      just # Handy way to save and run project-specific commands
      k9s # Kubernetes CLI to manage your clusters in real-time
      cilium-cli # CLI for Cilium
    ];

    shells = with pkgs; [
      bashInteractive
      zsh
      nushell
    ];
    shellAliases = {
      t = "echo 'Test :)'";
      l = "ls -laSh";
      nixup = "darwin-rebuild switch";
      mkdir = "mkdir -p";
      c2p = "code2prompt . --output=code2prompt.md --tokens";
    };
  };
}
