{pkgs, ...}: {
  programs.niri.enable = true;

  # Note: xdg.portal is configured in hyprland-config.nix
  # Do NOT add portal-gnome here - it conflicts with portal-hyprland
  # and breaks Waybar/compositor IPC. Niri can use portal-gtk or
  # portal-hyprland (both support the wlr-foreign-toplevel protocol).
  # If session-specific portals are needed, use xdg.portal.config
  # with matchRules per compositor instead.

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
