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

    # Workaround: Define users for Home Manager (see docs/reports/home-manager-users-workaround-bug-report.md)
    # Home Manager's nix-darwin/default.nix imports ../nixos/common.nix which requires this
    users.users.larsartmann = {
      name = "larsartmann";
      home = "/Users/larsartmann";
    };
  };
}
