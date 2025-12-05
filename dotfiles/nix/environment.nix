{ config, pkgs, lib, inputs, nix-ai-tools, nixpkgs-nh-dev, ... }:

let
  # Import centralized path configuration
  userConfig = (import ./core/UserConfig.nix { inherit lib; });
  pathConfigModule = (import ./core/PathConfig.nix { inherit lib; });
  pathConfig = pathConfigModule.mkPathConfig userConfig.defaultUser.username;
  homeDir = pathConfig.home;

  # Import crush from nix-ai-tools
  inherit (nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system} or {}) crush;

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
  imports = [ ../common/packages.nix ];

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
    # Configure available shells for nix-darwin user management
    shells = [ pkgs.fish pkgs.zsh pkgs.bash ];

    # Set Darwin configuration path for explicit configuration management
    darwinConfig = "$HOME/.nixpkgs/darwin-configuration.nix";

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
      NODE_OPTIONS = "--max-old-space-size=4096";
      NPM_CONFIG_AUDIT = "false";
      NPM_CONFIG_FUND = "false";

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

      # Node.js development optimization
      npm_config_prefix = "${homeDir}/.npm-global";
      npm_config_cache = "${homeDir}/.cache/npm";

      # Additional environment variables from issue #11
      PAGER = "less";
      LESS = "-R";  # Enable color output in less
      CLICOLOR = "1";  # Enable color output in ls
      LSCOLORS = "ExGxBxDxCxEgEdxbxgxcxd";  # Custom ls colors

      # PATH configuration is handled by nix-homebrew automatically
      # Manual PATH setting conflicts with nix-darwin's systemPath management
    };

    # Add user-specific paths to system PATH
    # This adds go/bin and other development tool directories
    systemPath = [
      "${homeDir}/go/bin"              # Go binaries (templ, air, etc.)
      "${homeDir}/.local/bin"           # Local user binaries
      "${homeDir}/.bun/bin"            # Bun runtime binaries
      "${homeDir}/.turso"              # Turso CLI
      "${homeDir}/.orbstack/bin"       # OrbStack CLI tools
    ];

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep <PACKAGE_NAME>
    systemPackages = with pkgs; [
        # Note: Core development tools are imported from ../common/packages.nix

        # Terminal applications
        iterm2

        # Browsers
        google-chrome

        # GNU utilities for macOS compatibility
        coreutils
        findutils
        gnused
    ];
  };
}
