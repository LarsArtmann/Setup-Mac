## TODO: very much not a fan of this file at all! It should be all moved into the other config files and then deleted.
# Test minimal Darwin configuration
{pkgs, ...}: {
  # Basic system configuration
  system.stateVersion = 5;

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
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
