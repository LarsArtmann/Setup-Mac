{pkgs, ...}: {
  # Font configuration (cross-platform)
  fonts = {
    packages =
      [
        # Primary programming font
        pkgs.jetbrains-mono

        # Additional Nerd Fonts for variety
        pkgs.fira-code
        pkgs.iosevka-bin

        # Linux-only: Bibata cursor theme for Hyprcursor
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        pkgs.bibata-cursors
      ];
  };
}
