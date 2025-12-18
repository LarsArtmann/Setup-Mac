# VS Code Permissions Module
# File system permissions management for VS Code

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.vscode.permissions;
in {
  config = mkIf (config.programs.vscode.enable && cfg.enable) {
    # File System Permissions Management
    systemd.services.vscode-permissions = {
      description = "Set VS Code file permissions";
      wantedBy = [ "multi-user.target" ];
      after = [ "vscode-zfs-dataset.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        echo "Setting VS Code file permissions..."

        # Set directory permissions
        ${concatStringsSep "\n" (mapAttrsToList (dir: perms: ''
          echo "Creating and setting permissions for ${dir} to ${perms}"
          mkdir -p "${dir}"
          chmod ${perms} "${dir}"
          chown $USER:$USER "${dir}"
        '') cfg.directories)}

        # Set file permissions
        ${concatStringsSep "\n" (mapAttrsToList (file: perms: ''
          if [ -f "${file}" ]; then
            echo "Setting permissions for ${file} to ${perms}"
            chmod ${perms} "${file}"
            chown $USER:$USER "${file}"
          fi
        '') cfg.files)}

        echo "VS Code permissions configured successfully"
      '';
    };
  };
}