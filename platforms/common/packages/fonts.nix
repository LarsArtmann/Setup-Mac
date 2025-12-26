{pkgs, ...}: {
  # Font configuration (cross-platform)
  fonts = {
    packages = [pkgs.jetbrains-mono];
  };
}
