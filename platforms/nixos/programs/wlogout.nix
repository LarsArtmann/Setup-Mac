{pkgs, ...}: {
  # wlogout power menu with Catppuccin Mocha theme
  programs.wlogout = {
    enable = true;

    # Layout configuration
    layout = [
      {
        label = "lock";
        action = "${pkgs.hyprlock}/bin/hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "logout";
        action = "hyprctl dispatch exit";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
    ];

    # Catppuccin Mocha styling
    style = ''
      * {
        background-image: none;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 16px;
      }

      window {
        background-color: rgba(30, 30, 46, 0.95);
        border-radius: 20px;
        border: 3px solid #b4befe;
      }

      button {
        background-color: #313244;
        color: #cdd6f4;
        border-radius: 16px;
        border: 2px solid #45475a;
        margin: 10px;
        padding: 20px;
        transition: all 0.2s ease;
      }

      button:focus,
      button:active,
      button:hover {
        background-color: #b4befe;
        color: #1e1e2e;
        border-color: #b4befe;
        box-shadow: 0 4px 15px rgba(180, 190, 254, 0.4);
      }

      /* Lock button - blue accent */
      #lock {
        background-color: #313244;
        border-color: #89b4fa;
      }
      #lock:hover {
        background-color: #89b4fa;
        border-color: #89b4fa;
        box-shadow: 0 4px 15px rgba(137, 180, 250, 0.4);
      }

      /* Hibernate button - mauve accent */
      #hibernate {
        background-color: #313244;
        border-color: #cba6f7;
      }
      #hibernate:hover {
        background-color: #cba6f7;
        border-color: #cba6f7;
        box-shadow: 0 4px 15px rgba(203, 166, 247, 0.4);
      }

      /* Logout button - peach accent */
      #logout {
        background-color: #313244;
        border-color: #fab387;
      }
      #logout:hover {
        background-color: #fab387;
        border-color: #fab387;
        box-shadow: 0 4px 15px rgba(250, 179, 135, 0.4);
      }

      /* Shutdown button - red accent */
      #shutdown {
        background-color: #313244;
        border-color: #f38ba8;
      }
      #shutdown:hover {
        background-color: #f38ba8;
        border-color: #f38ba8;
        box-shadow: 0 4px 15px rgba(243, 139, 168, 0.4);
      }

      /* Suspend button - teal accent */
      #suspend {
        background-color: #313244;
        border-color: #94e2d5;
      }
      #suspend:hover {
        background-color: #94e2d5;
        border-color: #94e2d5;
        box-shadow: 0 4px 15px rgba(148, 226, 213, 0.4);
      }

      /* Reboot button - green accent */
      #reboot {
        background-color: #313244;
        border-color: #a6e3a1;
      }
      #reboot:hover {
        background-color: #a6e3a1;
        border-color: #a6e3a1;
        box-shadow: 0 4px 15px rgba(166, 227, 161, 0.4);
      }
    '';
  };
}
