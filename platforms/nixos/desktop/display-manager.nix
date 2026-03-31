{config, ...}: {
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    displayManager.defaultSession = "niri";
  };

  programs.silentSDDM = {
    enable = true;
    theme = "catppuccin-mocha";
  };
}
