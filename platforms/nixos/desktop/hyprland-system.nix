{ pkgs, lib, ... }:

{
  # Note: polkit-gnome authentication agent handled by system-level services
  # Removing manual user service to avoid conflicts

  # Enable touchpad support (enabled default in most desktopManager)
  # services.xserver.libinput.enable = true;
}
