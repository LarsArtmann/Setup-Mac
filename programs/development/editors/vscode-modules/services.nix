# VS Code Services Module
# Service management for VS Code background services

{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.vscode.services;
in {
  config = mkIf (config.programs.vscode.enable && cfg.enable) {
    # Package Installation
    environment.systemPackages = [ config.programs.vscode.package ]
      ++ config.programs.vscode.packages
      ++ config.programs.vscode.configuration.extensions;

    # Service Management
    systemd.services =
      mapAttrs' (serviceName: service:
        nameValuePair "vscode-${serviceName}" {
          description = service.description;
          after = service.after;
          wantedBy = service.wantedBy;
          serviceConfig = {
            ExecStart = service.execStart;
            Restart = "always";
            User = config.programs.vscode.services.user;
            Environment = mapAttrsToList (k: v: "${k}=${v}") service.environment;
          };
        }
      ) (filterAttrs (n: v: v.enable) cfg.definitions);
  };
}