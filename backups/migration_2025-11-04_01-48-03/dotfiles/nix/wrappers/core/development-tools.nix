# CLI Tool Wrapper Template
# For command-line tools with configuration files

{ pkgs, lib, wrapPackage }:

{ package 
, configFiles ? {}
, environment ? {}
, theme ? null
, style ? null
, ... }:

wrapPackage {
  inherit package;
  
  configFiles = configFiles // (lib.optionalAttrs (theme != null) {
    "config/bat/config" = pkgs.writeText "bat-config" ''
      --theme="${theme}"
      ${lib.optionalString (style != null) "--style=${style}"}
    '';
  });
  
  environment = environment // {
    BAT_CONFIG_PATH = "$(pwd)/.config/bat/config";
    BAT_THEME = theme or "default";
  };
  
  preHook = ''
    # Ensure bat config directory exists
    mkdir -p "$(dirname "$BAT_CONFIG_PATH")"
  '';
}