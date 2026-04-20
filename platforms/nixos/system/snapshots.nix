{pkgs, ...}: {
  # BTRFS snapshots with Timeshift
  # Provides system rollback capability for NixOS

  # Install Timeshift for BTRFS snapshot management
  environment.systemPackages = with pkgs; [
    timeshift
  ];

  # Create Timeshift configuration
  environment.etc."timeshift/timeshift.json".text = ''
    {
      "backup_device_uuid": "0b629b65-a1b7-40df-a7dc-9ea5e0b04959",
      "parent_device_uuid": "",
      "do_first_run": true,
      "btrfs_mode": true,
      "btrfs_use_qgroup": true,
      "schedule_monthly": false,
      "schedule_weekly": true,
      "schedule_daily": true,
      "schedule_hourly": false,
      "schedule_boot": false,
      "schedule_persist": false,
      "count_monthly": 2,
      "count_weekly": 3,
      "count_daily": 5,
      "count_hourly": 0,
      "count_boot": 5,
      "snapshot_size": "0",
      "snapshot_size_percentage": "0",
      "date_format": "%Y-%m-%d %H:%M:%S",
      "exclude": [
        "timeshift/snapshots",
        "home/*/.local/share/Trash",
        "home/*/.thumbnail",
        "home/*/.tmp",
        "home/*/.Trash",
        "home/*/.nv",
        "home/*/.cache"
      ],
      "exclude-apps": []
    }
  '';

  systemd = {
    timers.timeshift-backup = {
      description = "Automatic BTRFS snapshots with Timeshift";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      wantedBy = ["timers.target"];
    };

    services.timeshift-backup = {
      description = "Create BTRFS snapshot with Timeshift";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.timeshift}/bin/timeshift --create --scripted";
      };
    };

    services.timeshift-verify = {
      description = "Verify Timeshift snapshot freshness";
      path = [pkgs.timeshift pkgs.coreutils pkgs.gawk];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "timeshift-verify" ''
          set -euo pipefail
          MAX_AGE_DAYS=3

          SNAPSHOTS=$(${pkgs.timeshift}/bin/timeshift --list --scripted 2>/dev/null || echo "")

          if echo "$SNAPSHOTS" | grep -q "0 snapshots"; then
            echo "WARNING: No Timeshift snapshots found!"
            exit 1
          fi

          LATEST=$(echo "$SNAPSHOTS" | grep -oP '\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}' | tail -1)

          if [ -z "$LATEST" ]; then
            echo "WARNING: Could not parse latest snapshot date"
            exit 1
          fi

          SNAP_EPOCH=$(date -d "''${LATEST//_/-}" +%s 2>/dev/null || date -d "''${LATEST:0:10}" +%s 2>/dev/null || echo 0)
          NOW_EPOCH=$(date +%s)
          AGE_DAYS=$(( (NOW_EPOCH - SNAP_EPOCH) / 86400 ))

          if [ "$AGE_DAYS" -gt "$MAX_AGE_DAYS" ]; then
            echo "WARNING: Latest Timeshift snapshot is $AGE_DAYS days old (threshold: $MAX_AGE_DAYS)"
            exit 1
          fi

          echo "OK: Latest Timeshift snapshot is $AGE_DAYS day(s) old"
        '';
      };
    };

    timers.timeshift-verify = {
      description = "Verify Timeshift snapshot freshness daily";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      wantedBy = ["timers.target"];
    };
  };

  # Enable BTRFS maintenance
  services.btrfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/" "/data"];
    };
  };
}
