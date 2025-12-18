# VS Code ZFS Integration Module
# ZFS dataset management for VS Code data isolation

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.vscode.zfs;
in {
  config = mkIf (config.programs.vscode.enable && cfg.enable) {
    # ZFS Dataset Management
    systemd.services.vscode-zfs-dataset = {
      description = "Create VS Code ZFS dataset";
      wantedBy = [ "local-fs.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        # Check if ZFS is available
        if ! command -v zfs >/dev/null 2>&1; then
          echo "ZFS not available, skipping dataset creation for ${cfg.dataset}"
          exit 0
        fi

        # Create dataset if it doesn't exist
        if ! zfs list -o name ${cfg.dataset} >/dev/null 2>&1; then
          echo "Creating ZFS dataset ${cfg.dataset} with properties:"
          ${concatMapStringsSep "\n" (k: v: "  echo \"  ${k}=${v}\"") (attrsToList cfg.properties)}

          zfs create -p ${concatStringsSep " " (mapAttrsToList (k: v: "-o ${k}=${v}") cfg.properties)} ${cfg.dataset}
          echo "ZFS dataset ${cfg.dataset} created successfully"
        else
          echo "ZFS dataset ${cfg.dataset} already exists"
        fi

        # Ensure mountpoint exists and is mounted
        mkdir -p ${cfg.mountpoint}
        if ! zfs get mounted ${cfg.dataset} | grep -q "yes"; then
          echo "Mounting dataset ${cfg.dataset} to ${cfg.mountpoint}"
          zfs mount ${cfg.dataset}
        fi

        # Set up automatic snapshots if enabled
        ${optionalString cfg.snapshots.enable ''
          echo "Setting up automatic snapshots for ${cfg.dataset}"
          # Create systemd timer for snapshots
          cat > /etc/systemd/system/vscode-zfs-snapshot.timer << 'EOF'
[Unit]
Description=VS Code ZFS automatic snapshots

[Timer]
OnCalendar=${cfg.snapshots.frequency}
Persistent=true

[Install]
WantedBy=timers.target
EOF

          cat > /etc/systemd/system/vscode-zfs-snapshot.service << 'EOF'
[Unit]
Description=Create VS Code ZFS snapshot

[Service]
Type=oneshot
ExecStart=/usr/bin/zfs snapshot ${cfg.dataset}@$(date +%Y%m%d_%H%M%S)
ExecStartPost=/usr/bin/zfs list -t snapshot -o name,creation -d1 ${cfg.dataset} | tail -n +${toString (cfg.snapshots.retention + 2)} | awk '{print $1}' | xargs -r zfs destroy
EOF

          systemctl enable vscode-zfs-snapshot.timer
          systemctl start vscode-zfs-snapshot.timer
          echo "ZFS snapshot timer configured for ${cfg.snapshots.frequency} snapshots"
        ''}
      '';
    };
  };
}