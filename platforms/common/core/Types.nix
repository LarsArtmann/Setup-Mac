# Types.nix - TYPE SYSTEM ARCHITECTURE
# STRONG TYPE SAFETY FOR ALL CONFIGURATION COMPONENTS
{lib, ...}: let
  # CORE TYPE DEFINITIONS - TYPE SAFETY ENFORCEMENT
  WrapperType = lib.types.enum ["cli-tool" "gui-app" "shell" "service" "dev-env"];

  ValidationLevel = lib.types.enum ["none" "standard" "strict"];

  Platform = lib.types.enum ["all" "darwin" "linux" "aarch64-darwin" "x86_64-darwin"];

  PackageValidator = lib.types.functionTo (lib.types.package
    // {
      description = "Function to validate package compatibility";
    });

  # CONFIGURATION TYPE DEFINITIONS - TYPE GUARANTEES
  WrapperConfig = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Wrapper name";
      };

      package = lib.mkOption {
        type = lib.types.package;
        description = "Base package to wrap";
      };

      type = lib.mkOption {
        type = WrapperType;
        description = "Wrapper type classification";
      };

      config = lib.mkOption {
        type = lib.types.attrs;
        default = {};
        description = "Wrapper configuration parameters";
      };

      platform = lib.mkOption {
        type = Platform;
        default = "all";
        description = "Platform compatibility requirement";
      };

      validation = lib.mkOption {
        type = ValidationLevel;
        default = "standard";
        description = "Validation strictness level";
      };

      dependencies = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Required dependencies";
      };

      essential = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Essential wrapper - system will fail without it";
      };

      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Auto-start on system boot";
      };

      performance = lib.mkOption {
        type = lib.types.submodule {
          options = {
            lazyLoad = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable lazy loading";
            };
            cache = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable caching";
            };
            maxMemory = lib.mkOption {
              type = lib.types.int;
              default = 512;
              description = "Maximum memory usage (MB)";
            };
          };
        };
        default = {};
      };
    };
  };

  TemplateConfig = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Template name";
      };

      type = lib.mkOption {
        type = WrapperType;
        description = "Template wrapper type";
      };

      template = lib.mkOption {
        type = lib.types.path;
        description = "Template file path";
      };

      variables = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Variable name";
            };
            type = lib.mkOption {
              type = lib.types.enum ["str" "path" "package" "bool" "int" "list"];
              description = "Variable type";
            };
            required = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Required variable";
            };
            default = lib.mkOption {
              type = lib.types.anything;
              description = "Default value";
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = "Variable description";
            };
          };
        });
        default = [];
        description = "Template variables";
      };

      examples = lib.mkOption {
        type = lib.types.listOf WrapperConfig;
        default = [];
        description = "Example configurations";
      };

      validation = lib.mkOption {
        type = lib.types.submodule {
          options = {
            syntaxCheck = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable syntax validation";
            };
            dependencyCheck = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable dependency validation";
            };
            platformCheck = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable platform compatibility validation";
            };
          };
        };
        default = {};
      };
    };
  };

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

      packages = lib.mkOption {
        type = lib.types.listOf WrapperConfig;
        description = "System package wrappers";
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
  inherit WrapperType ValidationLevel Platform WrapperConfig TemplateConfig ValidationRule SystemState;
}
