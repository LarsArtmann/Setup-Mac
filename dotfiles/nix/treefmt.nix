# treefmt-nix Configuration
# Unified code formatting for the project
{ pkgs, lib, inputs, ... }:

{
  # Import treefmt-nix flake module and configure formatters
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  # Configure treefmt with comprehensive formatters
  treefmt = {
    # Enable treefmt system-wide
    enable = true;

    # Project root directory
    projectRootFile = "flake.nix";

    # Configure formatters for different languages
    programs = {
      # Go formatting with gofumpt (enhanced formatter)
      gofumpt = {
        enable = true;
        # gofumpt is stricter than gofmt, provides additional formatting rules
      };

      # JavaScript/TypeScript formatting with prettier
      prettier = {
        enable = true;
        # Configure prettier for consistent JS/TS/JSON/YAML/MD formatting
        settings = {
          tabWidth = 2;
          singleQuote = true;
          trailingComma = "es5";
          printWidth = 100;
          semi = true;
          bracketSpacing = true;
          arrowParens = "avoid";
        };
        # Include various web development file types
        includes = [
          "*.js"
          "*.ts"
          "*.jsx"
          "*.tsx"
          "*.json"
          "*.yaml"
          "*.yml"
          "*.md"
          "*.css"
          "*.scss"
          "*.html"
        ];
      };

      # Nix formatting with nixfmt
      nixfmt = {
        enable = true;
        # Use consistent 100-character width for Nix files
        settings = {
          width = 100;
        };
      };

      # Shell script formatting with shfmt
      shfmt = {
        enable = true;
        # Configure shell formatting with 2-space indentation
        settings = {
          indent = 2;
          case_indent = true;  # Indent case statements
          space_redirects = true;  # Add space before redirects
        };
      };
    };

    # Global exclusions for treefmt
    settings = {
      global = {
        excludes = [
          # Lock files and dependencies
          "*.lock"
          "package-lock.json"
          "yarn.lock"
          "pnpm-lock.yaml"
          "Cargo.lock"
          "poetry.lock"

          # Build artifacts and dependencies
          "node_modules/"
          ".next/"
          "dist/"
          "build/"
          "target/"
          "vendor/"
          ".cache/"

          # Version control and environment
          ".git/"
          ".direnv/"
          ".env*"

          # Nix build results
          "result"
          "result-*"

          # Backups and temporary files
          "backups/"
          "*.tmp"
          "*.bak"
          "*.backup"

          # Log files
          "*.log"

          # IDE and editor files
          ".vscode/"
          ".idea/"
          "*.swp"
          "*.swo"
          "*~"

          # macOS system files
          ".DS_Store"
          "._*"
        ];
      };
    };
  };

  # Install additional formatting and linting tools system-wide
  environment.systemPackages = with pkgs; [
    # Core treefmt tool (provided by treefmt-nix)
    # treefmt  # This is now handled by the treefmt-nix module

    # Additional development tools that complement treefmt
    nodePackages.eslint        # JavaScript linting
    shellcheck                 # Shell script linting
    yamllint                   # YAML linting

    # Alternative formatters (for manual use if needed)
    alejandra                  # Alternative Nix formatter
    biome                      # Modern JS/TS formatter and linter

    # JSON/YAML processing tools
    jq                         # JSON processor
    yq-go                      # YAML processor
  ];

}