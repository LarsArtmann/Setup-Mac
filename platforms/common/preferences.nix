{lib, ...}: {
  options.preferences = {
    appearance = {
      variant = lib.mkOption {
        type = lib.types.enum ["dark" "light"];
        default = "dark";
        description = "System-wide color variant — affects GTK, Qt, portals, browsers, and macOS";
      };

      colorSchemeName = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "catppuccin-mocha";
        description = "nix-colors scheme name (must exist in nix-colors.colorSchemes)";
      };

      accent = lib.mkOption {
        type = lib.types.enum ["rosewater" "flamingo" "pink" "mauve" "red" "maroon" "peach" "yellow" "green" "teal" "sky" "sapphire" "blue" "lavender"];
        default = "lavender";
        description = "Accent color for theme variants";
      };

      density = lib.mkOption {
        type = lib.types.enum ["standard" "compact"];
        default = "compact";
        description = "UI density — standard or compact";
      };

      gtkThemeName = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "Catppuccin-Mocha-Compact-Lavender-Dark";
        description = "Full GTK theme name (must match installed theme)";
      };

      iconTheme = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "Papirus-Dark";
        description = "Icon theme name";
      };

      cursorTheme = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "Bibata-Modern-Classic";
        description = "Cursor theme name";
      };

      cursorSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 96;
        description = "Cursor size in pixels";
      };

      font = {
        name = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "Sans";
          description = "Default UI font";
        };
        size = lib.mkOption {
          type = lib.types.ints.positive;
          default = 16;
          description = "Default UI font size";
        };
        mono = lib.mkOption {
          type = lib.types.nonEmptyStr;
          default = "JetBrainsMono Nerd Font";
          description = "Monospace font";
        };
        monoSize = lib.mkOption {
          type = lib.types.ints.positive;
          default = 16;
          description = "Monospace font size";
        };
      };
    };
  };
}
