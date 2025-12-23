{ pkgs, lib, ... }:

{
  # Enable X11 windowing system
  services.xserver = {
    enable = true;

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable SDDM (Simple Desktop Display Manager) with X11 support
  # Replaces heavier GDM/GNOME setup
  # Note: Wayland disabled for stability with AMD GPU
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;  # Disabled for AMD GPU stability
    theme = "sugar-dark";
    enableHidpi = true;
    autoNumlock = true;
    extraPackages = [ pkgs.sddm-sugar-dark ];
  };
}
