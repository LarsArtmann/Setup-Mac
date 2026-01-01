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

  # Create systemd service for Timeshift backup timer
  systemd.timers.timeshift-backup = {
    description = "Automatic BTRFS snapshots with Timeshift";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = ["timers.target"];
  };

  systemd.services.timeshift-backup = {
    description = "Create BTRFS snapshot with Timeshift";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.timeshift}/bin/timeshift --create --scripted";
    };
  };

  # Enable BTRFS maintenance
  services.btrfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/"];
    };
  };
}
