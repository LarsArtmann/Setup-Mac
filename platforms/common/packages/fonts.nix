{pkgs, ...}: {
  # Font configuration (cross-platform)
  fonts = {
    packages =
      [
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.iosevka

        # Unicode fallback fonts for full UTF-8 coverage
        # Covers: emoji, CJK, Arabic, Devanagari, and other non-Latin scripts
        pkgs.noto-fonts
        pkgs.noto-fonts-color-emoji
        pkgs.noto-fonts-cjk-sans

        # Linux-only: Bibata cursor theme for Hyprcursor
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        pkgs.bibata-cursors
      ];
  };
}
