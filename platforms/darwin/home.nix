{
  pkgs,
  nix-ssh-config,
  config,
  ...
}: {
  # Import common Home Manager modules
  imports = [
    ../common/home-base.nix
    ./programs/shells.nix
    nix-ssh-config.homeManagerModules.ssh
  ];

  # SSH client configuration
  ssh-config = {
    enable = true;
    user = "lars";
    hosts = {
      onprem = {
        hostname = "192.168.1.100";
        user = "root";
      };
      "evo-x2" = {
        hostname = "192.168.1.150";
        user = "lars";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          TCPKeepAlive = "yes";
        };
      };
    };
  };

  # Darwin-specific Home Manager overrides
  home.sessionVariables = {
    # Empty for now, use common defaults from home-base.nix
    # Add Darwin-specific variables here if needed in the future
  };

  # Note: Starship Fish integration is handled by Home Manager
  # via programs.starship.enableFishIntegration = true (in common/programs/starship.nix)
  # No manual 'starship init fish | source' needed here

  # Note: Shell aliases and initialization are now in ./programs/shells.nix
  # to avoid duplication between home.nix and shells.nix

  # Darwin-specific packages (user-level)
  home.packages = with pkgs; [
    # Add Darwin-specific user packages if needed
    # Most packages are in common/packages/base.nix
  ];

}
