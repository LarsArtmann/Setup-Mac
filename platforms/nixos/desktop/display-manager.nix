{
  config,
  pkgs,
  lib,
  ...
}: {
  # SilentSDDM SDDM theme with Catppuccin-Mocha preset
  # Module from inputs.silent-sddm - handles SDDM config, Qt6 deps, virtual keyboard
  programs.silentSDDM = {
    enable = true;
    theme = "catppuccin-mocha";
  };

  # SilentSDDM sets defaultSession via its module, but we ensure niri
  services.displayManager.defaultSession = "niri";

  # X11 keymap
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };
}
