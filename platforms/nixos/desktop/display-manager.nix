{
  pkgs,
  lib,
  ...
}: {
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    # SDDM with sugar-dark theme (beautiful, available in nixpkgs)
    displayManager = {
      sddm = {
        enable = true;
        theme = "sugar-dark";
        extraPackages = with pkgs; [
          qt6Packages.qtbase
          qt6Packages.qtsvg
          qt6Packages.qtwayland
        ];
      };

      # Default to Niri session
      defaultSession = "niri";
    };
  };

  environment.etc = {
    "sddm.conf".text = ''
      [Theme]
      Current=sugar-dark
    '';
  };
}
