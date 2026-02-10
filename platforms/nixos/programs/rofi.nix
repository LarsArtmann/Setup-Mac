{pkgs, ...}: {
  # Rofi application launcher with Catppuccin Mocha theme
  programs.rofi = {
    enable = true;

    # Rofi package with Wayland support (now merged into main rofi)
    package = pkgs.rofi;

    # Catppuccin Mocha theme configuration
    theme = builtins.toFile "catppuccin-mocha.rasi" ''
      * {
          bg: #1e1e2e;
          bg-alt: #313244;
          fg: #cdd6f4;
          fg-alt: #a6adc8;

          blue: #89b4fa;
          lavender: #b4befe;
          sapphire: #74c7ec;
          sky: #89dceb;
          teal: #94e2d5;
          green: #a6e3a1;
          yellow: #f9e2af;
          peach: #fab387;
          maroon: #eba0ac;
          red: #f38ba8;
          mauve: #cba6f7;
          pink: #f5c2e7;
          flamingo: #f2cdcd;
          rosewater: #f5e0dc;

          background-color: @bg;
          text-color: @fg;
          font: "JetBrainsMono Nerd Font 14";
      }

      window {
          width: 50%;
          height: 60%;
          border: 3px;
          border-color: @lavender;
          border-radius: 16px;
          background-color: @bg;
          padding: 20px;
      }

      mainbox {
          background-color: transparent;
          children: [inputbar, listview];
          spacing: 15px;
      }

      inputbar {
          background-color: @bg-alt;
          border-radius: 12px;
          padding: 12px 16px;
          children: [prompt, entry];
          spacing: 12px;
      }

      prompt {
          background-color: transparent;
          text-color: @lavender;
          font: "JetBrainsMono Nerd Font 16";
      }

      entry {
          background-color: transparent;
          text-color: @fg;
          placeholder: "Search...";
          placeholder-color: @fg-alt;
          cursor: text;
      }

      listview {
          background-color: transparent;
          columns: 1;
          lines: 8;
          spacing: 8px;
          fixed-height: false;
          dynamic: true;
      }

      element {
          background-color: transparent;
          padding: 12px 16px;
          border-radius: 10px;
          spacing: 12px;
      }

      element-icon {
          background-color: transparent;
          size: 24px;
      }

      element-text {
          background-color: transparent;
          text-color: @fg;
          vertical-align: 0.5;
      }

      element normal.normal {
          background-color: transparent;
      }

      element normal.urgent {
          background-color: @red;
          text-color: @bg;
      }

      element normal.active {
          background-color: @blue;
          text-color: @bg;
      }

      element selected.normal {
          background-color: @lavender;
          text-color: @bg;
      }

      element selected.urgent {
          background-color: @red;
          text-color: @bg;
      }

      element selected.active {
          background-color: @green;
          text-color: @bg;
      }

      element alternate.normal {
          background-color: transparent;
      }

      element alternate.urgent {
          background-color: @red;
          text-color: @bg;
      }

      element alternate.active {
          background-color: @blue;
          text-color: @bg;
      }

      mode-switcher {
          background-color: @bg-alt;
          border-radius: 12px;
          padding: 8px;
          spacing: 8px;
      }

      button {
          background-color: transparent;
          text-color: @fg-alt;
          padding: 8px 12px;
          border-radius: 8px;
      }

      button selected {
          background-color: @lavender;
          text-color: @bg;
      }

      message {
          background-color: @bg-alt;
          border-radius: 12px;
          padding: 12px;
      }

      textbox {
          background-color: transparent;
          text-color: @fg;
      }

      scrollbar {
          background-color: @bg-alt;
          border-radius: 8px;
          width: 8px;
          padding: 4px;
      }

      handle {
          background-color: @lavender;
          border-radius: 4px;
      }
    '';

    # Additional configuration
    extraConfig = {
      modi = "drun,run,window,ssh";
      show-icons = true;
      icon-theme = "Papirus";
      terminal = "kitty";
      drun-display-format = "{name}";
      location = 0;
      disable-history = false;
      hide-scrollbar = false;
      display-drun = "  Apps  ";
      display-run = "  Run  ";
      display-window = "  Window  ";
      display-ssh = "  SSH  ";
      sidebar-mode = true;
    };
  };
}
