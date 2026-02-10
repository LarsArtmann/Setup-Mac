{
  pkgs,
  config,
  ...
}: let
  # Catppuccin Mocha colors
  colors = {
    base = "1e1e2e";
    mantle = "181825";
    crust = "11111b";
    text = "cdd6f4";
    subtext0 = "a6adc8";
    subtext1 = "bac2de";
    surface0 = "313244";
    surface1 = "45475a";
    surface2 = "585b70";
    overlay0 = "6c7086";
    overlay1 = "7f849c";
    overlay2 = "9399b2";
    blue = "89b4fa";
    lavender = "b4befe";
    sapphire = "74c7ec";
    sky = "89dceb";
    teal = "94e2d5";
    green = "a6e3a1";
    yellow = "f9e2af";
    peach = "fab387";
    maroon = "eba0ac";
    red = "f38ba8";
    mauve = "cba6f7";
    pink = "f5c2e7";
    flamingo = "f2cdcd";
    rosewater = "f5e0dc";
  };
in {
  # Hyprlock screen locker with Catppuccin Mocha theme
  programs.hyprlock = {
    enable = true;

    settings = {
      # General settings
      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
        no_fade_out = false;
        ignore_empty_input = false;
      };

      # Background configuration
      background = [
        {
          monitor = "";
          path = "screenshot"; # Use screenshot as background with blur
          blur_passes = 3;
          blur_size = 8;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];

      # Input field (password entry)
      input-field = [
        {
          monitor = "";
          size = "300, 60";
          outline_thickness = 4;
          dots_size = 0.25;
          dots_spacing = 0.15;
          dots_center = true;
          dots_rounding = 2;
          outer_color = "rgb(${colors.lavender})";
          inner_color = "rgb(${colors.surface0})";
          font_color = "rgb(${colors.text})";
          fade_on_empty = true;
          fade_timeout = 1000;
          placeholder_text = "<i>Enter Password...</i>";
          hide_input = false;
          rounding = 12;
          check_color = "rgb(${colors.green})";
          fail_color = "rgb(${colors.red})";
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          fail_transition = 300;
          capslock_color = "rgb(${colors.yellow})";
          numlock_color = "rgb(${colors.blue})";
          bothlock_color = "rgb(${colors.peach})";
          invert_numlock = false;
          swap_font_color = false;
          position = "0, -100";
          halign = "center";
          valign = "center";
        }
      ];

      # Time label
      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgb(${colors.lavender})";
          font_size = 90;
          font_family = "JetBrainsMono Nerd Font Bold";
          position = "0, 150";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
          shadow_size = 4;
          shadow_color = "rgb(${colors.crust})";
          shadow_boost = 1.2;
        }
        # Date label
        {
          monitor = "";
          text = "cmd[update:1000] date +\"%A, %B %d\"";
          color = "rgb(${colors.text})";
          font_size = 28;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 60";
          halign = "center";
          valign = "center";
          shadow_passes = 1;
          shadow_size = 2;
          shadow_color = "rgb(${colors.crust})";
        }
        # Username label
        {
          monitor = "";
          text = "Welcome back, $USER";
          color = "rgb(${colors.blue})";
          font_size = 20;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -20";
          halign = "center";
          valign = "center";
          shadow_passes = 1;
          shadow_size = 2;
          shadow_color = "rgb(${colors.crust})";
        }
        # Lock icon
        {
          monitor = "";
          text = "󰌾";
          color = "rgb(${colors.lavender})";
          font_size = 48;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, -180";
          halign = "center";
          valign = "center";
        }
      ];

      # Shape decorations (optional aesthetic elements)
      shape = [
        {
          monitor = "";
          size = "360, 4";
          color = "rgba(${colors.lavender}, 0.5)";
          rounding = 2;
          position = "0, -60";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
