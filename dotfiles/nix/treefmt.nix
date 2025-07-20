# treefmt-nix Configuration
# Unified code formatting for the project
{ pkgs, lib, ... }:

{
  # Install treefmt and formatters system-wide
  environment.systemPackages = with pkgs; [
    # Core treefmt tool
    treefmt
    
    # Go formatters
    go
    gofumpt     # Enhanced Go formatter (stricter than gofmt)
    
    # JavaScript/TypeScript formatters
    nodePackages.prettier
    biome       # Modern JS/TS formatter and linter
    
    # Nix formatters
    nixfmt-classic  # Official Nix formatter
    alejandra       # Alternative Nix formatter
    
    # Shell script formatters
    shfmt
    
    # JSON/YAML formatters
    jq
    yq-go
    
    # Markdown formatters (via prettier)
    # Included in nodePackages.prettier
    
    # Additional useful formatters
    nodePackages.eslint        # JavaScript linting
    nodePackages."@biomejs/biome"  # Alternative modern toolchain
  ];

  # Create treefmt configuration in /etc
  environment.etc."treefmt.toml" = {
    text = ''
      # treefmt configuration for Setup-Mac project
      # Universal code formatter configuration

      [formatter.go]
      command = "gofumpt"
      options = ["-w"]
      includes = ["*.go"]

      [formatter.javascript]
      command = "prettier"
      options = ["--write", "--tab-width", "2", "--single-quote", "--trailing-comma", "es5"]
      includes = ["*.js", "*.ts", "*.jsx", "*.tsx", "*.json", "*.yaml", "*.yml", "*.md"]

      [formatter.nix]
      command = "nixfmt"
      options = ["--width", "100"]
      includes = ["*.nix"]

      [formatter.shell]
      command = "shfmt"
      options = ["-w", "-i", "2", "-ci"]
      includes = ["*.sh", "*.bash"]

      # Global settings
      [global]
      excludes = [
          "*.lock",
          "node_modules/",
          ".git/",
          "target/",
          "build/",
          "dist/",
          ".next/",
          ".cache/",
          "backups/",
          "*.log",
          "result",
          "result-*",
          ".direnv/",
          "vendor/"
      ]
    '';
  };

  # Add shell aliases for convenient formatting
  programs.fish.shellInit = lib.mkAfter ''
    # treefmt aliases for convenient code formatting
    alias fmt='treefmt'
    alias fmt-check='treefmt --check'
    alias fmt-go='treefmt --formatters go'
    alias fmt-js='treefmt --formatters javascript'  
    alias fmt-nix='treefmt --formatters nix'
    alias fmt-all='treefmt --no-cache'
  '';
}