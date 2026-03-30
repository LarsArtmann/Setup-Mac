{pkgs, ...}: {
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  programs.regreet = {
    enable = true;

    theme = {
      name = "Catppuccin-Mocha-Compact-Lavender-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = ["lavender"];
        size = "compact";
        variant = "mocha";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };

    font = {
      name = "Cantarell";
      size = 16;
      package = pkgs.cantarell-fonts;
    };

    settings = {
      commands = {
        reboot = ["loginctl" "reboot"];
        poweroff = ["loginctl" "poweroff"];
      };
    };

    cageArgs = ["-s"];
    extraCss = ./regreet.css;
  };

  services.greetd = {
    restart = true;
    settings = {
      default_session = {
        user = "greeter";
      };
    };
  };
}
