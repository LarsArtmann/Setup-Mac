# Test minimal Darwin configuration
{ pkgs, lib, ... }:
{
  # Basic system configuration
  system.stateVersion = 5;

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    neovim
  ];

  # Enable shells
  programs.zsh.enable = true;
  programs.bash.enable = true;

  # User configuration
  users.users.larsartmann = {
    home = "/Users/larsartmann";
    shell = pkgs.zsh;
  };
}