{
  lib,
  nix-colors,
  ...
}: {
  # Import Darwin-specific system configurations
  imports = [
    ./networking/default.nix
    ./nix/settings.nix
    ./security/pam.nix
    ./security/keychain.nix
    ./services/default.nix
    ./services/launchagents.nix # Declarative LaunchAgents (replaces bash scripts)
    ./system/activation.nix
    ./system/settings.nix
    ./environment.nix
    ../common/packages/base.nix
    ../common/packages/fonts.nix
  ];

  # Define color scheme option
  options.colorScheme = lib.mkOption {
    type = lib.types.attrs;
    default = nix-colors.colorSchemes.catppuccin-mocha;
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
    # Define color scheme and utilities
    colorScheme = nix-colors.colorSchemes.catppuccin-mocha;
    colorSchemeLib = nix-colors.lib;

    ## TODO: Should we move these nixpkgs configs to ../common/?
    # Enable unfree packages for Chrome and Terraform
    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["terraform"];
    };

    # Pin Go to version 1.26
    nixpkgs.overlays = [
      (final: prev: {
        go = prev.callPackage (prev.path + "/pkgs/development/compilers/go/1.26.nix") {};
      })
      (final: prev: {
        # Override golangci-lint to use Go 1.26 instead of default Go version
        # golangci-lint uses buildGo125Module by default, we need to use buildGo126Module
        golangci-lint = prev.golangci-lint.override {
          buildGo125Module = prev.buildGo126Module;
        };
      })
    ];

    # Workaround: Define users for Home Manager (see docs/reports/home-manager-users-workaround-bug-report.md)
    # Home Manager's nix-darwin/default.nix imports ../nixos/common.nix which requires this
    users.users.larsartmann = {
      name = "larsartmann";
      home = "/Users/larsartmann";
    };
  };
}
