# State.nix - CENTRALIZED SINGLE SOURCE OF TRUTH
# TYPE-SAFE STATE MANAGEMENT FOR ENTIRE SYSTEM

{ lib, pkgs, UserConfig, PathConfig, ... }:

let
  # TYPE DEFINITIONS - STRONG TYPE SAFETY ENFORCEMENT
  PathConfigType = lib.types.submodule {
    options = {
      home = lib.mkOption {
        type = lib.types.path;
        description = "User home directory";
      };
      config = lib.mkOption {
        type = lib.types.path;
        description = "Configuration directory";
      };
      flake = lib.mkOption {
        type = lib.types.path;
        description = "Flake configuration file";
      };
      dotfiles = lib.mkOption {
        type = lib.types.path;
        description = "Dotfiles source directory";
      };
    };
  };

  PackageConfig = lib.types.submodule {
    options = {
      essential = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Essential package - system will fail without it";
      };
      platform = lib.mkOption {
        type = lib.types.str;
        default = "all";
        description = "Platform compatibility (all, darwin, linux)";
      };
      validation = lib.mkOption {
        type = lib.types.str;
        default = "standard";
        description = "Validation level (none, standard, strict)";
      };
    };
  };

  # CENTRALIZED PATH CONFIGURATION - SINGLE SOURCE OF TRUTH
  # Using injected UserConfig and PathConfig to avoid circular imports
  Paths = let
    # Use injected UserConfig instead of direct import
    inherit (UserConfig.defaultUser) username;
    # Use injected PathConfig instead of direct import
    pathConfig = PathConfig.mkPathConfig username;
  in pathConfig;

  # STATE VALIDATION FUNCTIONS - TYPE-SAFE GUARANTEES
  validatePathConsistency = paths:
    let
      homeExists = lib.pathExists paths.home;
      configExists = lib.pathExists paths.config;
      flakeExists = lib.pathExists paths.flake;
      dotfilesExists = lib.pathExists paths.dotfiles;
      nixConfigExists = lib.pathExists paths.nixConfig;

      validationResults = [
        { path = "home"; exists = homeExists; }
        { path = "config"; exists = configExists; }
        { path = "flake"; exists = flakeExists; }
        { path = "dotfiles"; exists = dotfilesExists; }
        { path = "nixConfig"; exists = nixConfigExists; }
      ];

      allPathsExist = lib.all (r: r.exists) validationResults;
      missingPaths = lib.filter (r: !r.exists) validationResults;

    in {
      allValid = allPathsExist;
      inherit missingPaths;
      inherit validationResults;
    };

  validatePackageList = packages:
    let
      validatePackage = pkg: {
        name = lib.getName pkg;
        version = lib.getVersion pkg;
        available = (pkg ? outPath) && pkg ? meta;
        platforms = pkg.meta.platforms or ["all"];
        essential = (pkg.config or {}).essential or false;
      };

      validatedPackages = map validatePackage packages;
      essentialAvailable = lib.all (p: p.available) (lib.filter (p: p.essential) validatedPackages);

    in {
      packages = validatedPackages;
      inherit essentialAvailable;
      totalValid = lib.all (p: p.available) validatedPackages;
    };

in {
  inherit PathConfigType PackageConfig Paths;
  inherit validatePathConsistency validatePackageList;
}
