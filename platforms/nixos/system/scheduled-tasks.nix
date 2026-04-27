let
  primaryUser = "lars";
in
  # Scheduled tasks for NixOS using systemd timers
  {
    pkgs,
    config,
    ...
  }: let
    uid = builtins.toString config.users.users.${primaryUser}.uid;
  in {
    systemd = {
      timers = {
        crush-update-providers = {
          description = "Daily Crush AI provider update";
          timerConfig = {
            OnCalendar = "00:00";
            Persistent = true;
            RandomizedDelaySec = "30m";
          };
          wantedBy = ["timers.target"];
        };

        blocklist-auto-update = {
          description = "Weekly blocklist hash update";
          timerConfig = {
            OnCalendar = "Mon *-*-* 04:00";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
          wantedBy = ["timers.target"];
        };

        service-health-check = {
          description = "Service health check";
          timerConfig = {
            OnCalendar = "*:0/15";
            Persistent = true;
            RandomizedDelaySec = "5m";
          };
          wantedBy = ["timers.target"];
        };
      };

      services = {
        # Reusable failure notification template — use via `OnFailure = "notify-failure@%n.service"`
        "notify-failure@" = {
          description = "Notify on failure of %i";
          serviceConfig = {
            Type = "oneshot";
            User = primaryUser;
            Environment = [
              "DISPLAY=:0"
              "WAYLAND_DISPLAY=wayland-1"
              "XDG_RUNTIME_DIR=/run/user/${uid}"
            ];
            ExecStart = pkgs.writeShellScript "notify-failure" ''
              ${pkgs.libnotify}/bin/notify-send -u critical "Scheduled task failed" "%i — check journalctl -u %i" 2>/dev/null || \
                ${pkgs.util-linux}/bin/logger -t "%i" -p user.err "Scheduled task failed — check journalctl -u %i"
            '';
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };

        crush-update-providers = {
          description = "Update Crush AI providers";
          onFailure = ["notify-failure@%n.service"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.nur.repos.charmbracelet.crush}/bin/crush update-providers";
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };

        blocklist-auto-update = {
          description = "Download blocklists and update hashes in config";
          onFailure = ["notify-failure@%n.service"];
          path = [pkgs.git pkgs.nix pkgs.gawk pkgs.gnused pkgs.python3];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "blocklist-hash-updater" (builtins.readFile ../scripts/blocklist-hash-updater)}";
            WorkingDirectory = "/home/${primaryUser}/projects/SystemNix";
            User = primaryUser;
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };

        service-health-check = {
          description = "Check critical services and notify on failure";
          onFailure = ["notify-failure@%n.service"];
          path = [pkgs.systemd pkgs.python3 pkgs.libnotify];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "service-health-check" (builtins.readFile ../scripts/service-health-check)}";
            User = primaryUser;
            Environment = [
              "DISPLAY=:0"
              "WAYLAND_DISPLAY=wayland-1"
              "XDG_RUNTIME_DIR=/run/user/${uid}"
            ];
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };
      };
    };
  }
