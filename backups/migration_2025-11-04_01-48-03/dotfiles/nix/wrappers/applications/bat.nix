# Bat Wrapper - Enhanced cat with gruvbox theme
# Proof of concept for embedded configuration

{ pkgs, lib, wrappers }:

wrappers.wrapperModules.bat.apply {
  inherit pkgs;
  theme = "gruvbox-dark";
  style = "numbers,changes,header";
  
  # Additional bat configuration
  configFiles = {
    "config/bat/themes/gruvbox-dark.tmTheme" = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/morhetz/gruvbox/master/textmate/gruvbox-dark.tmTheme";
      sha256 = "sha256-1vk7v2kyqpx1nq7h16c8sf0d5az2kzhq65b7iy12jbjwrf2r1yf";
    };
  };
  
  environment = {
    BAT_THEME = "gruvbox-dark";
    BAT_STYLE = "numbers,changes,header";
    BAT_CONFIG_PATH = "$(pwd)/.config/bat/config";
  };
}