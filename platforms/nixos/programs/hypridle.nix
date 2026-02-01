{pkgs, ...}: {
  # Hypridle - idle management daemon
  services.hypridle = {
    enable = true;

    settings = {
      # General settings
      general = {
        lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        before_sleep_cmd = "${pkgs.hyprlock}/bin/hyprlock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };

      # Listeners for idle events
      listener = [
        {
          # Dim screen after 2.5 minutes
          timeout = 150;
          on-timeout = "brightnessctl -s set 30%";
          on-resume = "brightnessctl -r";
        }
        {
          # Lock screen after 5 minutes
          timeout = 300;
          on-timeout = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        }
        {
          # Turn off display after 8 minutes
          timeout = 480;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          # Suspend after 20 minutes
          timeout = 1200;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
