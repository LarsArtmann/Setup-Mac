# ContainerService.nix - Helper functions for container-based services
# Provides mkContainerService function to generate NixOS config from ContainerService type
{
  lib,
  pkgs,
  config,
  ...
}: let
  # Generate wait script for dependency checking
  mkWaitScript = dep: let
    attempts = builtins.ceil (dep.waitTimeout / dep.waitInterval);
  in
    pkgs.writeShellScript "wait-for-${dep.service}" ''
      echo "Waiting for ${dep.service}..."
      for i in {1..${toString attempts}}; do
        if curl -s ${dep.waitUrl} &>/dev/null; then
          echo "${dep.service} is ready!"
          exit 0
        fi
        echo "${dep.service} not ready yet, attempt $i/${toString attempts}..."
        sleep ${toString dep.waitInterval}
      done
      echo "${dep.service} failed to become ready after ${toString dep.waitTimeout} seconds"
      exit 1
    '';

  # Convert ContainerVolume to podman volume string
  mkVolumeString = vol: "${vol.source}:${vol.target}${lib.optionalString vol.readOnly ":ro"}";

  # Convert ContainerPort to podman port string
  mkPortString = port: "${port.host}:${toString port.hostPort}:${toString port.containerPort}";

  # Generate health check extra options
  mkHealthCheckOptions = hc: [
    "--health-cmd=${hc.command}"
    "--health-interval=${hc.interval}"
    "--health-timeout=${hc.timeout}"
    "--health-retries=${toString hc.retries}"
  ];

  # Generate tmpfiles rules for data directory
  mkTmpfilesRules = cfg: let
    baseRule = "d ${cfg.dataDir} 0755 root root -";
    subdirRules = map (subdir: "d ${cfg.dataDir}/${subdir} 0755 root root -") cfg.dataSubdirs;
  in
    [baseRule] ++ subdirRules;
in rec {
  # Main function to create a container service configuration
  mkContainerService = cfg: let
    # Build dependencies list
    depServices = map (d: d.service) cfg.dependencies;
    hasWaitDeps = lib.any (d: d.waitUrl != null) cfg.dependencies;
    waitDeps = lib.filter (d: d.waitUrl != null) cfg.dependencies;

    # Generate ExecStartPre scripts for waiting
    waitScripts = map mkWaitScript waitDeps;

    # Build extra options
    healthOpts = lib.optionals (cfg.healthCheck != null) (mkHealthCheckOptions cfg.healthCheck);
    allExtraOptions = cfg.extraOptions ++ healthOpts;

    # Build port mappings
    portStrings = map mkPortString cfg.ports;

    # Build volume mappings
    volumeStrings = map mkVolumeString cfg.volumes;

    # Container name (used for systemd service)
    containerName = cfg.name;
    systemdServiceName = "docker-${containerName}";
  in {
    # OCI container configuration
    virtualisation.oci-containers.containers.${containerName} = {
      inherit (cfg) image autoStart environment;
      ports = portStrings;
      volumes = volumeStrings;
      extraOptions = allExtraOptions;
    };

    # Systemd service overrides for startup behavior
    systemd.services.${systemdServiceName} = {
      after = lib.unique (["network-online.target"] ++ depServices);
      wants = ["network-online.target"];
      requires = lib.unique depServices;
      serviceConfig = {
        Restart = cfg.restartPolicy;
        RestartSec = "${toString cfg.restartSec}s";
        ExecStartPre = lib.mkIf hasWaitDeps waitScripts;
      };
    };

    # tmpfiles rules for data directories
    systemd.tmpfiles.rules = lib.optionals (cfg.dataDir != null) (mkTmpfilesRules cfg);
  };

  # Helper to merge multiple container service configurations
  mkContainerServices = configs: lib.mkMerge (map mkContainerService configs);
}
