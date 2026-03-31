# ContainerTypes.nix - TYPE DEFINITIONS FOR OCI CONTAINER SERVICES
# Reusable types for podman/docker container-based services with health checks
{lib, ...}: let
  # Health check configuration for containers
  ContainerHealthCheck = lib.types.submodule {
    options = {
      command = lib.mkOption {
        type = lib.types.str;
        description = "Health check command to run inside container";
        example = "python3 -c \"import urllib.request;urllib.request.urlopen('http://localhost:8050/')\"";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "30s";
        description = "Time between health checks";
      };

      timeout = lib.mkOption {
        type = lib.types.str;
        default = "10s";
        description = "Health check timeout";
      };

      retries = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Number of retries before marking unhealthy";
      };
    };
  };

  # Dependency with optional wait logic
  ContainerDependency = lib.types.submodule {
    options = {
      service = lib.mkOption {
        type = lib.types.str;
        description = "Systemd service name to depend on";
        example = "immich-server.service";
      };

      waitUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "URL to poll before starting (enables ExecStartPre wait script)";
        example = "http://localhost:2283/api/server-info/ping";
      };

      waitTimeout = lib.mkOption {
        type = lib.types.int;
        default = 60;
        description = "Seconds to wait for dependency before failing";
      };

      waitInterval = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = "Seconds between poll attempts";
      };

      maxRetries = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Maximum number of poll attempts";
      };
    };
  };

  # Volume mount configuration
  ContainerVolume = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.path;
        description = "Host path to mount";
      };

      target = lib.mkOption {
        type = lib.types.str;
        description = "Container path to mount to";
      };

      readOnly = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the mount is read-only";
      };
    };
  };

  # Port mapping configuration
  ContainerPort = lib.types.submodule {
    options = {
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host interface to bind";
      };

      hostPort = lib.mkOption {
        type = lib.types.port;
        description = "Port on host";
      };

      containerPort = lib.mkOption {
        type = lib.types.port;
        description = "Port in container";
      };
    };
  };

  # Complete container service configuration
  ContainerService = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Service name (used for systemd unit name)";
      };

      image = lib.mkOption {
        type = lib.types.str;
        description = "Container image to use";
        example = "docker.io/lstein/photomapai:latest";
      };

      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to auto-start the container";
      };

      ports = lib.mkOption {
        type = lib.types.listOf ContainerPort;
        default = [];
        description = "Port mappings";
      };

      volumes = lib.mkOption {
        type = lib.types.listOf ContainerVolume;
        default = [];
        description = "Volume mounts";
      };

      healthCheck = lib.mkOption {
        type = lib.types.nullOr ContainerHealthCheck;
        default = null;
        description = "Optional health check configuration";
      };

      dependencies = lib.mkOption {
        type = lib.types.listOf ContainerDependency;
        default = [];
        description = "Services this container depends on";
      };

      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Environment variables for container";
      };

      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional podman/docker run options";
      };

      restartPolicy = lib.mkOption {
        type = lib.types.enum ["no" "on-failure" "always" "unless-stopped"];
        default = "on-failure";
        description = "Systemd restart policy";
      };

      restartSec = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Seconds to wait before restart";
      };

      dataDir = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Data directory for tmpfiles rules";
      };

      dataSubdirs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Subdirectories to create under dataDir";
      };
    };
  };
in {
  inherit
    ContainerHealthCheck
    ContainerDependency
    ContainerVolume
    ContainerPort
    ContainerService
    ;
}
