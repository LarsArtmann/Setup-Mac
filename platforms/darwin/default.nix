{lib, ...}: {
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

  ## TODO: Should we move these nixpkgs configs to ../common/?
  # Enable unfree packages for Chrome and Terraform
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) ["terraform"];
  };

  # NOTE: Removed users.users.larsartmann definition (2026-01-13)
  # This workaround was thought to be required for Home Manager integration
  # Testing to confirm if actually needed (see docs/reports/home-manager-users-workaround-bug-report.md)
  # If build fails, restore users definition
}
