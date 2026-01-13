# Minimal test configuration to isolate the issue
{...}: {
  # Only essential imports
  imports = [
    ./environment.nix
    ./nix/settings.nix
  ];

  # Minimal configuration
  system.stateVersion = 5;
}
