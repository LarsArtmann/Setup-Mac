{...}: {
  flake.nixosModules.dns-failover = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.services.dns-failover;
    inherit (lib) mkEnableOption mkOption types;
  in {
    options.services.dns-failover = {
      enable = mkEnableOption "DNS failover via Keepalived VRRP";

      virtualIP = mkOption {
        type = types.str;
        description = "Virtual IP address shared between DNS nodes (clients point to this)";
      };

      interface = mkOption {
        type = types.str;
        description = "Network interface for VRRP advertisements and virtual IP";
      };

      priority = mkOption {
        type = types.int;
        default = 100;
        description = "VRRP priority (higher = preferred master). Use 100 for primary, 50 for backup.";
      };

      routerID = mkOption {
        type = types.int;
        default = 53;
        description = "VRRP router ID (must match on all nodes in the cluster)";
      };

      subnetPrefix = mkOption {
        type = types.int;
        default = 24;
        description = "Subnet prefix length for the virtual IP";
      };
    };

    config = lib.mkIf cfg.enable {
      services.keepalived = {
        enable = true;
        openFirewall = true;

        vrrpScripts.chk_unbound = {
          script = "${pkgs.procps}/bin/pidof unbound";
          interval = 2;
          fall = 2;
          rise = 2;
        };

        vrrpInstances.VI_DNS = {
          state =
            if cfg.priority >= 100
            then "MASTER"
            else "BACKUP";
          interface = cfg.interface;
          virtualRouterId = cfg.routerID;
          priority = cfg.priority;
          noPreempt = cfg.priority < 100;

          virtualIps = [
            {addr = "${cfg.virtualIP}/${toString cfg.subnetPrefix}";}
          ];

          trackScripts = ["chk_unbound"];
        };

        extraGlobalDefs = ''
          vrrp_garp_master_refresh 30
          vrrp_garp_master_refresh_repeat 2
        '';
      };
    };
  };
}
