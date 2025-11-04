# Bat Wrapper - Enhanced cat with gruvbox theme
# Proof of concept for embedded configuration

{ pkgs, lib }:

let
  # Simple wrapper function using writeShellScriptBin
  wrapWithConfig = { name, package, configFiles ? {}, env ? {}, preHook ? "", postHook ? "" }:
    pkgs.writeShellScriptBin name ''
      ${preHook}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") env)}

      # Ensure config directories exist
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (configPath: source: ''
        mkdir -p "$(dirname "$HOME/.${configPath}")"
        ln -sf "${source}" "$HOME/.${configPath}" 2>/dev/null || true
      '') configFiles)}

      # Run the original binary
      exec "${lib.getBin package}/bin/${name}" "$@"
      ${postHook}
    '';

  # Bat configuration
  batConfig = pkgs.writeText "config" ''
    # Bat configuration
    --theme="gruvbox-dark"
    --style="numbers,changes,header"
  '';

  # Create Bat wrapper
  batWrapper = wrapWithConfig {
    name = "bat";
    package = pkgs.bat;
    configFiles = {
      "config/bat/config" = batConfig;
      "config/bat/themes/gruvbox-dark.tmTheme" = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/morhetz/gruvbox/master/textmate/gruvbox-dark.tmTheme";
        sha256 = "sha256-1vk7v2kyqpx1nq7h16c8sf0d5az2kzhq65b7iy12jbjwrf2r1yf";
      };
    };
    env = {
      BAT_THEME = "gruvbox-dark";
      BAT_STYLE = "numbers,changes,header";
      BAT_CONFIG_PATH = "$(pwd)/.config/bat/config";
    };
  };

in
{
  # Export wrapper for use in system packages
  bat = batWrapper;
}