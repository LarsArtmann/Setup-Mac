{pkgs, ...}: {
  # Enable X11 windowing system
  services.xserver = {
    enable = true;

    # Configure keymap in X11
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable SDDM (Simple Desktop Display Manager) with Wayland support
  # Replaces heavier GDM/GNOME setup
  # Note: Wayland enabled for modern experience (AMD GPU stable in 2025)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; # Enabled for modern Wayland experience
    theme = "sugar-dark";
    enableHidpi = true;
    autoNumlock = true;
    extraPackages = [pkgs.sddm-sugar-dark];
    settings = {
      General = {
        GreeterEnvironment = "QT_SCREEN_SCALE_FACTORS=2,QT_FONT_DPI=96";
      };
    };
  };
}
