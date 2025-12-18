# Program Integration Layer
# Bridges isolated program modules with existing platform configurations

{ lib, pkgs, inputs, ... }:

let
  # Import program modules system
  programsModule = import ../../programs { inherit lib pkgs; };
  
  # Helper to merge program module configurations
  mergeProgramConfig = programConfig:
    let
      # Extract packages from program module if enabled
      packages = if programConfig.enable then
        ([ programConfig.package ] ++ programConfig.packages)
      else [];
      
      # Extract services from program module if enabled  
      services = if programConfig.enable && programConfig.services.enable then
        lib.mapAttrs' (serviceName: serviceConfig:
          lib.nameValuePair "${programConfig._moduleName}-${serviceName}" {
            description = serviceConfig.description;
            wantedBy = serviceConfig.wantedBy;
            after = serviceConfig.after;
            serviceConfig = {
              ExecStart = serviceConfig.execStart;
              Restart = "always";
              User = serviceConfig.user;
              Environment = lib.mapAttrsToList (k: v: "${k}=${v}") serviceConfig.environment;
            };
          }
        ) (lib.filterAttrs (n: v: v.enable) programConfig.services.definitions)
      else {};
      
      # Extract configuration files
      configFiles = if programConfig.enable then
        lib.mapAttrs' (path: content:
          lib.nameValuePair "home-manager.users.lars.home.file.${path}" {
            text = content;
          }
        ) programConfig.configuration.files
      else {};
      
      # Extract directory permissions
      permissions = if programConfig.enable && programConfig.permissions.enable then
        {
          systemd.services."${programConfig._moduleName}-permissions" = {
            description = "Set ${programConfig._moduleName} file permissions";
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Type = "oneshot";
            script = with programConfig.permissions;
              lib.concatStringsSep "\n" (lib.mapAttrsToList (dir: perms: ''
                mkdir -p "${dir}"
                chmod ${perms} "${dir}"
                chown $USER:$USER "${dir}"
              '') directories);
          };
        }
      else {};
      
      # Extract ZFS management
      zfsManagement = if programConfig.enable && programConfig.zfs.enable then
        {
          systemd.services."${programConfig._moduleName}-zfs-dataset" = {
            description = "Create ${programConfig._moduleName} ZFS dataset";
            wantedBy = [ "local-fs.target" ];
            serviceConfig.Type = "oneshot";
            script = with programConfig.zfs;
              ''
                if ! command -v zfs >/dev/null 2>&1; then
                  echo "ZFS not available, skipping dataset creation for ${dataset}"
                  exit 0
                fi
                
                if ! zfs list -o name ${dataset} >/dev/null 2>&1; then
                  echo "Creating ZFS dataset ${dataset}..."
                  zfs create -p ${lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "-o ${k}=${v}") properties)} ${dataset}
                  echo "ZFS dataset ${dataset} created successfully"
                else
                  echo "ZFS dataset ${dataset} already exists"
                fi
                
                mkdir -p ${mountpoint}
                if ! zfs get mounted ${dataset} | grep -q "yes"; then
                  zfs mount ${dataset}
                fi
              '';
          };
        }
      else {};
      
    in
    {
      # Package management
      environment.systemPackages = packages;
      
      # Service management (systemd for NixOS)
      systemd.services = services;
      
      # File system permissions
      inherit permissions;
      
      # ZFS management (if available)
      inherit zfsManagement;
      
      # Home Manager configuration
      home-manager.users.lars = {
        home = {
          file = lib.listToAttrs (lib.attrValues configFiles);
        };
        
        # Shell aliases for the program
        programs.zsh.shellAliases = 
          if programConfig.enable then
            {
              "${programConfig._moduleName}" = "${programConfig._moduleName}";
            }
          else {};
      };
    };

  # Merge all enabled program configurations
  mergedProgramConfigs = programs:
    let
      enabledPrograms = lib.filterAttrs (n: v: v.enable) programs;
      programConfigs = lib.mapAttrs (name: config:
        mergeProgramConfig (config // { _moduleName = name; })
      ) enabledPrograms;
    in
    lib.foldl (acc: config: 
      acc // {
        environment.systemPackages = acc.environment.systemPackages or [] ++ config.environment.systemPackages;
        systemd.services = acc.systemd.services or {} // config.systemd.services;
        home-manager.users.lars.home.file = 
          (acc.home-manager.users.lars.home.file or {}) // 
          config.home-manager.users.lars.home.file;
        programs.zsh.shellAliases = 
          (acc.programs.zsh.shellAliases or {}) // 
          config.programs.zsh.shellAliases;
      }
    ) {} (lib.attrValues programConfigs);

in
{
  # Export integration function
  inherit mergeProgramConfig mergedProgramConfigs;
  
  # Helper to create program module integration
  integratePrograms = { enabledPrograms ? [], ... }:
    let
      # Get all available programs
      allPrograms = programsModule.listPrograms;
      
      # Filter enabled programs
      enabledProgramSet = lib.listToAttrs (map (name: {
        name = name;
        value = {
          enable = lib.elem name enabledPrograms;
        };
      }) enabledPrograms);
      
      # Merge with program modules
      finalPrograms = lib.mapAttrs (name: baseConfig:
        baseConfig // (enabledProgramSet.${name} or { enable = false; })
      ) allPrograms;
    in
    mergedProgramConfigs finalPrograms;
    
  # Create integration module for platform configurations
  programsIntegration = { 
    enabledVSCode ? false,
    enabledFish ? false,
    enabledStarship ? false,
    ... 
  }: {
    # Example integration for common programs
    programs = {
      vscode = {
        enable = enabledVSCode;
        zfs.enable = false; # Disable ZFS on macOS
        configuration.settings = {
          "workbench.colorTheme" = "Default High Contrast";
        };
      };
      
      fish = {
        enable = enabledFish;
        # Add fish-specific configuration
      };
      
      starship = {
        enable = enabledStarship;
        # Add starship-specific configuration
      };
    };
  };
  
  # Export as NixOS module
  nixosModule = { config, ... }: {
    options = {
      setup-mac.programs = {
        enable = lib.mkEnableOption "Setup-Mac program modules";
        
        enabled = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "List of enabled program modules";
        };
        
        autoEnable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Automatically enable all available program modules";
        };
      };
    };
    
    config = lib.mkIf config.setup-mac.programs.enable {
      # Auto-enable all programs if requested
      setup-mac.programs.enabled = 
        if config.setup-mac.programs.autoEnable then
          programsModule.listPrograms
        else
          config.setup-mac.programs.enabled;
          
      # Integrate enabled programs
      setup-mac.programs.integrated = programsModule.integratePrograms {
        enabledPrograms = config.setup-mac.programs.enabled;
      };
    };
  };
}