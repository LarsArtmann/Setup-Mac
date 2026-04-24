{
  pkgs,
  lib,
  nix-colors,
  ...
}: {
  # Import Darwin-specific system configurations
  imports = [
    # Cross-platform preferences (dark mode, fonts, themes — single source of truth)
    ../common/preferences.nix
    ./networking/default.nix
    ./nix/settings.nix
    ./security/pam.nix
    ./security/keychain.nix
    ./services/default.nix
    ./services/launchagents.nix # Declarative LaunchAgents (replaces bash scripts)
    ./system/activation.nix
    ./system/settings.nix
    ./environment.nix
    ./programs/chrome.nix # Chrome policy configuration for extension management
    ../common/packages/base.nix
    ../common/packages/fonts.nix
  ];

  # Define color scheme option
  options.colorScheme = lib.mkOption {
    type = lib.types.attrs;
    default = nix-colors.colorSchemes.${config.preferences.appearance.colorSchemeName};
    description = "Color scheme for system";
  };

  # Define colorSchemeLib option (different name to avoid conflict with lib)
  options.colorSchemeLib = lib.mkOption {
    type = lib.types.attrs;
    default = nix-colors.lib;
    description = "nix-colors library functions";
  };

  # Wrap all configuration in config attribute
  config = {
    # Build-time validation: Ensure critical packages exist in nixpkgs
    # These assertions fail fast if packages are unavailable
    assertions = [
      {
        assertion = builtins.hasAttr "d2" pkgs;
        message = "d2 package not found in nixpkgs - verify package name and availability";
      }
    ];

    # Define color scheme and utilities
    colorScheme = nix-colors.colorSchemes.catppuccin-mocha;
    colorSchemeLib = nix-colors.lib;

    # Note: nixpkgs.config is now centralized in ../common/core/nix-settings.nix
    # This eliminates duplicate allowUnfree and permittedInsecurePackages declarations

    # Homebrew casks for GUI applications not available in nixpkgs
    homebrew = {
      enable = true;
      casks = [
        "headlamp" # Kubernetes dashboard GUI
      ];
    };

    # Pin Go to version 1.26.1
    nixpkgs.overlays = [
      (_: prev: {
        go = prev.go_1_26.overrideAttrs (_: {
          version = "1.26.1";
          src = prev.fetchurl {
            url = "https://go.dev/dl/go1.26.1.src.tar.gz";
            hash = "sha256-MXIpPQSyCdwRRGmOe6E/BHf2uoxf/QvmbCD9vJeF37s=";
          };
        });
      })
      (final: prev: {
        # Override golangci-lint to use Go 1.26 instead of default Go version
        golangci-lint = prev.golangci-lint.override {
          buildGo126Module = prev.buildGoModule.override {inherit (final) go;};
        };
      })
    ];

    # Home Manager workaround: Explicit user definition required
    # Home Manager's nix-darwin/default.nix imports ../nixos/common.nix which
    # requires config.users.users.<name>.home to be defined for home.directory
    # See: https://github.com/nix-community/home-manager/issues/6036
    users.users.larsartmann = {
      name = "larsartmann";
      home = "/Users/larsartmann";
    };
  };
}
