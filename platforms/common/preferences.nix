{lib, ...}: {
  options.preferences = {
    appearance = {
      variant = lib.mkOption {
        type = lib.types.enum ["dark" "light"];
        default = "dark";
        description = "System-wide color variant — affects GTK, Qt, portals, browsers, and macOS";
      };

      colorSchemeName = lib.mkOption {
        type = lib.types.str;
        default = "catppuccin-mocha";
        description = "nix-colors scheme name (must exist in nix-colors.colorSchemes)";
      };

      accent = lib.mkOption {
        type = lib.types.str;
        default = "lavender";
        description = "Accent color for theme variants";
      };

      density = lib.mkOption {
        type = lib.types.enum ["standard" "compact"];
        default = "compact";
        description = "UI density — standard or compact";
      };

      gtkThemeName = lib.mkOption {
        type = lib.types.str;
        default = "Catppuccin-Mocha-Compact-Lavender-Dark";
        description = "Full GTK theme name (must match installed theme)";
      };

      iconTheme = lib.mkOption {
        type = lib.types.str;
        default = "Papirus-Dark";
        description = "Icon theme name";
      };

      cursorTheme = lib.mkOption {
        type = lib.types.str;
        default = "Bibata-Modern-Classic";
        description = "Cursor theme name";
      };

      cursorSize = lib.mkOption {
        type = lib.types.int;
        default = 96;
        description = "Cursor size in pixels";
      };

      font = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Sans";
          description = "Default UI font";
        };
        size = lib.mkOption {
          type = lib.types.int;
          default = 16;
          description = "Default UI font size";
        };
        mono = lib.mkOption {
          type = lib.types.str;
          default = "JetBrainsMono Nerd Font";
          description = "Monospace font";
        };
        monoSize = lib.mkOption {
          type = lib.types.int;
          default = 16;
          description = "Monospace font size";
        };
      };
    };
  };
}
