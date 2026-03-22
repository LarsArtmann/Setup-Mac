# Scheduled tasks for NixOS using systemd timers
{pkgs, ...}: {
  # Crush AI provider update service
  # Runs daily at midnight to update AI provider configurations
  systemd = {
    timers.crush-update-providers = {
      description = "Daily Crush AI provider update";
      timerConfig = {
        OnCalendar = "00:00";
        Persistent = true;
      };
      wantedBy = ["timers.target"];
    };

    services.crush-update-providers = {
      description = "Update Crush AI providers";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.crush}/bin/crush update-providers";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
