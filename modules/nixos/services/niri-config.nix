_: {
  flake.nixosModules.niri-config = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.services.niri-desktop;
  in {
    options.services.niri-desktop = {
      enable = lib.mkEnableOption "Niri Wayland compositor with XWayland support";
    };

    config = lib.mkIf cfg.enable {
      programs.niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };

      # Extract systemd user units (niri.service, niri-shutdown.target) from the package.
      # The niri-flake module disables the nixpkgs niri module (which does this),
      # so we must do it here. Without this, the generated niri.service has no ExecStart.
      systemd.packages = [pkgs.niri-unstable];

      environment.systemPackages = with pkgs; [
        xwayland-satellite
      ];
    };
  };
}
