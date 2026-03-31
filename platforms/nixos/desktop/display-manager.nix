{
  pkgs,
  lib,
  ...
}: {
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # SDDM with sugar-dark theme (beautiful, available in nixpkgs)
  services.displayManager.sddm = {
    enable = true;
    theme = "sugar-dark";
    extraPackages = with pkgs; [
      qt6Packages.qtbase
      qt6Packages.qtsvg
      qt6Packages.qtwayland
    ];
  };

  environment.etc = {
    "sddm.conf".text = ''
      [Theme]
      Current=sugar-dark
    '';
  };
}
