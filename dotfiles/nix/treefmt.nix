# treefmt-nix Configuration with Comprehensive Formatter Collection
# Unified code formatting using treefmt-full-flake for comprehensive language support
{ pkgs, lib, inputs, treefmt-full-flake, ... }:

{
  # Import treefmt-nix and comprehensive formatter collection
  imports = [
    inputs.treefmt-nix.flakeModule
    treefmt-full-flake.flakeModule
  ];

  # Comprehensive formatter configuration using treefmt-full-flake
  treefmtFlake = {
    # Project configuration
    projectRootFile = "flake.nix";

    # Auto-detection settings for dynamic formatter selection
    autoDetection = {
      enable = true;
      aggressive = false; # Conservative auto-detection
      override = "merge"; # Merge auto-detected with explicit settings
    };

    # Comprehensive formatter configuration
    formatters = {
      # Nix formatting with deterministic nixfmt
      nix = {
        enable = true;
        formatter = "nixfmt-rfc-style"; # RFC-compliant formatting
        linting = {
          deadnix = true; # Dead code detection
          statix = true; # Nix linting
        };
      };

      # Web development (JS/TS/CSS) with Biome
      web = {
        enable = true;
        formatter = "biome"; # Fast modern formatter
        languages = {
          javascript = true;
          typescript = true;
          css = true;
          scss = true;
          json = true;
          html = false; # Enable if needed
        };
      };

      # Python formatting and linting
      python = {
        enable = true;
        formatters = {
          black = true; # Code formatting
          isort = true; # Import sorting
          ruff = true; # Fast linting and formatting
        };
      };

      # Shell script formatting and linting
      shell = {
        enable = true;
        formatters = {
          shfmt = true; # Shell script formatting
          shellcheck = true; # Shell script linting
        };
      };

      # Rust formatting
      rust = {
        enable = true;
        formatters = {
          rustfmt = true; # Rust code formatting
        };
      };

      # YAML formatting
      yaml = {
        enable = true;
        formatters = {
          yamlfmt = true; # YAML formatting
        };
      };

      # Markdown formatting
      markdown = {
        enable = true;
        formatters = {
          mdformat = true; # Markdown formatting
        };
      };

      # JSON formatting
      json = {
        enable = true;
        formatters = {
          jsonfmt = true; # JSON formatting
        };
      };

      # Miscellaneous formatters
      misc = {
        enable = true;
        tools = {
          buf = true; # Protocol Buffer formatting
          taplo = true; # TOML formatting
          just = true; # Justfile formatting
          actionlint = true; # GitHub Actions linting
        };
      };
    };

    # Performance and behavior settings
    behavior = {
      performance = "balanced"; # fast/balanced/thorough
      allowMissingFormatter = false;
      enableDefaultExcludes = true;
    };

    # Incremental formatting for performance (10-100x faster)
    incremental = {
      enable = true;
      mode = "git"; # git/cache/auto
      cache = "./.cache/treefmt";
      gitBased = true;
      performance = {
        parallel = true; # Enable parallel processing
        maxJobs = 4; # Maximum parallel jobs
      };
    };

    # Git integration settings
    git = {
      branch = "master"; # Compare against master branch
      stagedOnly = false; # Format all changed files
      sinceCommit = null; # Optional: format since specific commit
      hooks = {
        preCommit = false; # Set to true to install pre-commit hook
        prePush = false; # Set to true to install pre-push hook
      };
    };
  };

  # Install comprehensive formatting tools system-wide for persistence after 'just clean'
  # These packages ensure formatters remain available even after nix-collect-garbage
  environment.systemPackages = with pkgs; [
    # Core formatting tools - CRITICAL for persistence
    nixfmt-rfc-style          # Deterministic Nix formatter
    biome                     # Modern JS/TS/CSS formatter and linter
    black                     # Python code formatter
    isort                     # Python import sorter
    ruff                      # Fast Python linter and formatter
    shfmt                     # Shell script formatter
    shellcheck                # Shell script linter
    rustfmt                   # Rust formatter
    yamlfmt                   # YAML formatter
    just                      # Justfile formatter
    buf                       # Protocol Buffer formatter
    taplo                     # TOML formatter
    mdformat                  # Markdown formatter
    actionlint                # GitHub Actions linter

    # Essential development tools
    nodePackages.eslint       # JavaScript linting (legacy support)
    yamllint                  # YAML linting (additional validation)
    alejandra                 # Alternative Nix formatter (backup)
    deadnix                   # Dead Nix code detection
    statix                    # Nix static analysis

    # Processing and utility tools
    jq                        # JSON processor
    yq-go                     # YAML processor
    treefmt                   # Core treefmt binary
  ];

}