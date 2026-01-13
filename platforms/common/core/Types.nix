# Types.nix - TYPE SYSTEM ARCHITECTURE
# STRONG TYPE SAFETY FOR ALL CONFIGURATION COMPONENTS
{lib, ...}: let
  # CORE TYPE DEFINITIONS - TYPE SAFETY ENFORCEMENT
  ValidationLevel = lib.types.enum ["none" "standard" "strict"];

  Platform = lib.types.enum ["all" "darwin" "linux" "aarch64-darwin" "x86_64-darwin"];

  PackageValidator = lib.types.functionTo (lib.types.package
    // {
      description = "Function to validate package compatibility";
    });

  # VALIDATION TYPE DEFINITIONS - TYPE-SAFE GUARANTEES
  ValidationRule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Rule name";
      };

      validator = lib.mkOption {
        type = PackageValidator;
        description = "Validation function";
      };

      errorMessage = lib.mkOption {
        type = lib.types.str;
        description = "Error message on validation failure";
      };

      level = lib.mkOption {
        type = ValidationLevel;
        default = "standard";
        description = "Validation level";
      };

      autoFix = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Attempt automatic fix on failure";
      };
    };
  };

  # SYSTEM STATE TYPE DEFINITIONS
  SystemState = lib.types.submodule {
    options = {
      paths = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        description = "System path configuration";
      };

      validation = lib.mkOption {
        type = lib.types.listOf ValidationRule;
        default = [];
        description = "System validation rules";
      };

      performance = lib.mkOption {
        type = lib.types.submodule {
          options = {
            maxConcurrentBuilds = lib.mkOption {
              type = lib.types.int;
              default = 4;
              description = "Maximum concurrent builds";
            };
            buildTimeout = lib.mkOption {
              type = lib.types.int;
              default = 3600;
              description = "Build timeout (seconds)";
            };
            retryAttempts = lib.mkOption {
              type = lib.types.int;
              default = 3;
              description = "Retry attempts on failure";
            };
          };
        };
        default = {};
      };
    };
  };
in {
  inherit ValidationLevel Platform PackageValidator ValidationRule SystemState;
}
