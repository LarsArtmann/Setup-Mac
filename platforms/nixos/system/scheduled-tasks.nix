let
  primaryUser = "lars";
in
  # Scheduled tasks for NixOS using systemd timers
  {
    pkgs,
    config,
    lib,
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

        docker-prune = {
          description = lib.mkForce "Weekly Docker system prune";
          wantedBy = ["timers.target"];
          timerConfig = lib.mkForce {
            OnCalendar = "Mon *-*-* 03:00";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };

        rust-target-cleanup = {
          description = "Weekly Rust target/ cleanup (dirs >2GB)";
          timerConfig = {
            OnCalendar = "Sun *-*-* 05:00";
            Persistent = true;
            RandomizedDelaySec = "1h";
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

        docker-prune = {
          description = lib.mkForce "Prune unused Docker resources";
          onFailure = ["notify-failure@%n.service"];
          path = [pkgs.docker];
          serviceConfig = lib.mkForce {
            Type = "oneshot";
            ExecStart = "${pkgs.docker}/bin/docker system prune -f --filter until=168h";
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };

        rust-target-cleanup = {
          description = "Clean Rust target/ directories over 2GB";
          onFailure = ["notify-failure@%n.service"];
          path = [pkgs.findutils pkgs.coreutils pkgs.gnused pkgs.libnotify];
          serviceConfig = {
            Type = "oneshot";
            User = primaryUser;
            ExecStart =
              pkgs.writeShellScript "rust-target-cleanup" ''
                set -euo pipefail

                SIZE_THRESHOLD=$((2 * 1024 * 1024))  # 2GB in KB
                SEARCH_ROOTS=("/home/${primaryUser}/projects")
                TOTAL_FREED=0
                CLEANED=0
                SKIPPED=0

                log() { echo "[rust-target-cleanup] $*"; }

                for root in "''${SEARCH_ROOTS[@]}"; do
                  [ -d "$root" ] || continue

                  while IFS= read -r target_dir; do
                    [ -d "$target_dir" ] || continue
                    dir_size_kb=$(${pkgs.coreutils}/bin/du -sk "$target_dir" 2>/dev/null | ${pkgs.coreutils}/bin/cut -f1)

                    if [ -z "$dir_size_kb" ] || [ "$dir_size_kb" -lt "$SIZE_THRESHOLD" ]; then
                      SKIPPED=$((SKIPPED + 1))
                      continue
                    fi

                    dir_size_human=$(${pkgs.coreutils}/bin/numfmt --to=iec --suffix=B "$((dir_size_kb * 1024))")
                    project=$(${pkgs.coreutils}/bin/dirname "$target_dir")

                    if [ ! -f "$project/Cargo.toml" ]; then
                      log "Skipping $target_dir — no Cargo.toml found"
                      continue
                    fi

                    # Safety: skip if cargo-lock is held and recent (build in progress)
                    if [ -f "$target_dir/.cargo-lock" ]; then
                      lock_age=$(( $(${pkgs.coreutils}/bin/date +%s) - $(${pkgs.coreutils}/bin/stat -c %Y "$target_dir/.cargo-lock" 2>/dev/null || echo 0) ))
                      if [ "$lock_age" -lt 3600 ]; then
                        log "Skipping $target_dir — cargo lock held (''${lock_age}s old)"
                        continue
                      fi
                    fi

                    log "Removing $target_dir ($dir_size_human)"
                    if ${pkgs.coreutils}/bin/rm -rf "$target_dir"; then
                      TOTAL_FREED=$((TOTAL_FREED + dir_size_kb))
                      CLEANED=$((CLEANED + 1))
                      log "Cleaned $target_dir — freed $dir_size_human"
                    else
                      log "FAILED to remove $target_dir"
                    fi
                  done < <(${pkgs.findutils}/bin/find "$root" \
                    -type d \
                    -name target \
                    -not -path '*/.*' \
                    -not -path '*/target/*/target')
                done

                TOTAL_FREED_HUMAN=$(${pkgs.coreutils}/bin/numfmt --to=iec --suffix=B "$((TOTAL_FREED * 1024))")
                log "Done: cleaned $CLEANED dirs, skipped $SKIPPED (under 2GB), freed $TOTAL_FREED_HUMAN"

                if [ "$CLEANED" -gt 0 ]; then
                  export DISPLAY=:0
                  export WAYLAND_DISPLAY=wayland-1
                  export XDG_RUNTIME_DIR=/run/user/${uid}
                  ${pkgs.libnotify}/bin/notify-send -u low \
                    "Rust target/ cleanup" \
                    "Cleaned $CLEANED projects, freed $TOTAL_FREED_HUMAN" 2>/dev/null || true
                fi
              '';
            StandardOutput = "journal";
            StandardError = "journal";
          };
        };
      };
    };
  }
