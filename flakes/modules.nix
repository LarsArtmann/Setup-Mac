# flake-parts module definitions for isolated program management

{ lib, ... }:

{
  # Export program modules as flake modules
  flakeModules = {
    # Core program management module
    programs = { lib, ... }: {
      options = {
        programs = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
            options = {
              enable = lib.mkEnableOption "${name} program";

              # ZFS integration
              zfs = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Create and manage dedicated ZFS dataset";
                };

                dataset = lib.mkOption {
                  type = lib.types.str;
                  default = "tank/data/${name}";
                  description = "ZFS dataset path for program data";
                };

                properties = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = {
                    compression = "lz4";
                    atime = "off";
                    recordsize = "1M";
                  };
                  description = "ZFS dataset properties";
                };

                mountpoint = lib.mkOption {
                  type = lib.types.str;
                  default = "/${name}";
                  description = "Mountpoint for the ZFS dataset";
                };

                snapshots = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Enable automatic snapshots";
                  };

                  retention = lib.mkOption {
                    type = lib.types.int;
                    default = 7;
                    description = "Number of snapshots to retain";
                  };
                };
              };

              # File system permissions
              permissions = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Set file system permissions";
                };

                directories = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = {};
                  description = "Directory permissions (path -> permissions)";
                };

                files = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = {};
                  description = "File permissions (path -> permissions)";
                };
              };

              # Package management
              package = lib.mkOption {
                type = lib.types.nullOr lib.types.package;
                default = null;
                description = "Primary package for this program";
              };

              packages = lib.mkOption {
                type = lib.types.listOf lib.types.package;
                default = [];
                description = "Additional packages to install";
              };

              # Configuration management
              configuration = {
                files = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.path);
                  default = {};
                  description = "Configuration files (path -> content)";
                };

                directories = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = {};
                  description = "Configuration directories to create";
                };

                environment = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = {};
                  description = "Environment variables to set";
                };
              };

              # Service management
              services = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Enable background services";
                };

                user = lib.mkOption {
                  type = lib.types.str;
                  default = "$USER";
                  description = "User to run services as";
                };

                definitions = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.submodule ({ serviceName, ... }: {
                    options = {
                      enable = lib.mkEnableOption "${serviceName} service";

                      description = lib.mkOption {
                        type = lib.types.str;
                        default = "${name} ${serviceName} service";
                        description = "Service description";
                      };

                      execStart = lib.mkOption {
                        type = lib.types.str;
                        description = "Command to start the service";
                      };

                      after = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = [];
                        description = "Services this service depends on";
                      };

                      wantedBy = lib.mkOption {
                        type = lib.types.listOf lib.types.str;
                        default = [ "multi-user.target" ];
                        description = "Targets that should start this service";
                      };

                      environment = lib.mkOption {
                        type = lib.types.attrsOf lib.types.str;
                        default = {};
                        description = "Environment variables for the service";
                      };
                    };
                  }));
                  default = {};
                  description = "Service definitions";
                };
              };

              # Integration hooks
              hooks = {
                preSetup = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                  description = "Commands to run before program setup";
                };

                postSetup = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                  description = "Commands to run after program setup";
                };

                preRemove = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                  description = "Commands to run before program removal";
                };

                postRemove = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                  description = "Commands to run after program removal";
                };
              };

              # Cross-platform compatibility
              platforms = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable cross-platform compatibility";
                };

                darwin = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = config.platforms.enable;
                    description = "Enable on macOS";
                  };

                  overrides = lib.mkOption {
                    type = lib.types.attrs;
                    default = {};
                    description = "Darwin-specific configuration overrides";
                  };
                };

                linux = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = config.platforms.enable;
                    description = "Enable on Linux";
                  };

                  overrides = lib.mkOption {
                    type = lib.types.attrs;
                    default = {};
                    description = "Linux-specific configuration overrides";
                  };
                };
              };
            };
          }));
          default = {};
          description = "Isolated program configurations";
        };
      };
    };
  };

  # Module that provides helper functions for program modules
  helpers = { lib, ... }: {
    options = {};
    config = {
      lib = {
        programHelpers = {
          # Helper to create ZFS dataset configuration
          createZfsDataset = { name, dataset, properties, mountpoint }: {
            name = "${name}-zfs-dataset";
            description = "Create ${name} ZFS dataset";
            wantedBy = [ "local-fs.target" ];
            serviceConfig.Type = "oneshot";
            script = ''
              # Check if ZFS is available
              if ! command -v zfs >/dev/null 2>&1; then
                echo "ZFS not available, skipping dataset creation"
                exit 0
              fi

              # Create dataset if it doesn't exist
              if ! zfs list -o name ${dataset} >/dev/null 2>&1; then
                echo "Creating ZFS dataset ${dataset}..."
                zfs create -p \
                  ${lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "-o ${k}=${v}") properties)} \
                  ${dataset}
                echo "ZFS dataset ${dataset} created successfully"
              else
                echo "ZFS dataset ${dataset} already exists"
              fi

              # Ensure mountpoint exists and is mounted
              mkdir -p ${mountpoint}
              if ! zfs get mounted ${dataset} | grep -q "yes"; then
                zfs mount ${dataset}
              fi
            '';
          };

          # Helper to create permission management service
          createPermissionsService = { name, directories, files, user }: {
            name = "${name}-permissions";
            description = "Set ${name} file permissions";
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Type = "oneshot";
            script = ''
              # Set directory permissions
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList (dir: perms: ''
                echo "Setting permissions for ${dir} to ${perms}"
                mkdir -p "${dir}"
                chmod ${perms} "${dir}"
                chown ${user}:${user} "${dir}"
              '') directories)}

              # Set file permissions
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList (file: perms: ''
                if [ -f "${file}" ]; then
                  echo "Setting permissions for ${file} to ${perms}"
                  chmod ${perms} "${file}"
                  chown ${user}:${user} "${file}"
                fi
              '') files)}
            '';
          };

          # Helper to create configuration management service
          createConfigService = { name, files, directories, user }: {
            name = "${name}-config";
            description = "Manage ${name} configuration";
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Type = "oneshot";
            script = ''
              # Create directories
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList (dir: desc: ''
                echo "Creating directory: ${dir}"
                mkdir -p "${dir}"
                chown ${user}:${user} "${dir}"
              '') directories)}

              # Write configuration files
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList (path: content: ''
                echo "Writing configuration to ${path}"
                mkdir -p "$(dirname "${path}")"
                cat > "${path}" << 'EOF'
${content}
EOF
                chown ${user}:${user} "${path}"
              '') files)}
            '';
          };

          # Helper to create service from definition
          createService = { name, serviceName, service }: {
            name = "${name}-${serviceName}";
            description = service.description;
            after = service.after;
            wantedBy = service.wantedBy;
            serviceConfig = {
              ExecStart = service.execStart;
              Restart = "always";
              User = service.user;
              Environment = lib.mapAttrsToList (k: v: "${k}=${v}") service.environment;
            };
          };
        };
      };
    };
  };
}