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
          # Dim screen after 15 minutes
          timeout = 900;
          on-timeout = "brightnessctl -s set 30%";
          on-resume = "brightnessctl -r";
        }
        {
          # Lock screen after 30 minutes
          timeout = 1800;
          on-timeout = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
        }
        {
          # Turn off display after 45 minutes
          timeout = 2700;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          # Suspend after 60 minutes
          timeout = 3600;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
