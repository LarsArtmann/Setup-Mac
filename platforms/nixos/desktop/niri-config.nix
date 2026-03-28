{pkgs, ...}: {
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
