{ pkgs, lib, ... }:

{
  # Starship Prompt Configuration (Cross-Platform)
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      add_newline = false;
      format = "$all$character";
    };
  };
}