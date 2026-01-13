# Minimal test to isolate the issue
{pkgs, ...}: {
  system.stateVersion = 5;
  nix.package = pkgs.nix; # Use current Nix
}
