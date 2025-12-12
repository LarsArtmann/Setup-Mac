{ config, pkgs, lib, TypeAssertions, ConfigAssertions, ModuleAssertions, Types, UserConfig, PathConfig, State, Validation, ... }:

{
  imports = [
    ../common/home.nix
    ../programs/tmux.nix
    # ./modules/ghost-wallpaper.nix  # Temporarily disabled
  ];

  # macOS-specific session variables
  home.sessionVariables = {
    LANG = lib.mkForce "en_GB.UTF-8"; # Keep UK English for macOS
  };

  # macOS-specific path additions
  home.sessionPath = [
    "$HOME/.local/bin/crush"
    "$HOME/.turso"
    "$HOME/.orbstack/bin"
    "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  ];

  # Ghost Btop Wallpaper temporarily disabled due to service conflicts
  # programs.ghost-btop-wallpaper = {
  #   enable = true;
  #   updateRate = 2000;
  #   backgroundOpacity = "0.0";
  # };

  # Ghost Systems integration
  # Note: State.nix and other Ghost System modules are available via specialArgs

  # Basic assertion to verify Ghost Systems injection
  assertions = [
    {
      assertion = TypeAssertions != null;
      message = "Ghost Systems TypeAssertions not injected!";
    }
  ];
}
