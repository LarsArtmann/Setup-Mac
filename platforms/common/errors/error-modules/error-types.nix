# Error Types Module
# Type definitions and categories for error management
{lib, ...}: let
  # ERROR TYPE DEFINITIONS - TYPE-SAFE ERROR CATEGORIES
  ErrorType = lib.types.enum [
    "validation"
    "build"
    "runtime"
    "configuration"
    "external"
    "performance"
    "dependency"
    "platform"
    "license"
    "filesystem"
    "network"
    "rollback"
  ];

  ErrorSeverity = lib.types.enum ["critical" "high" "medium" "low" "info"];

  ErrorCategory = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = ErrorType;
        description = "Error type classification";
      };
      severity = lib.mkOption {
        type = ErrorSeverity;
        default = "medium";
        description = "Error severity level";
      };
      autoRetry = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically retry on error";
      };
      rollbackable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Can rollback recover from this error";
      };
      notifyUser = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Notify user of this error";
      };
      logLevel = lib.mkOption {
        type = lib.types.enum ["error" "warn" "info" "debug"];
        default = "error";
        description = "Log level for this error";
      };
      recoveryActions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Automatic recovery actions";
      };
    };
  };
in {
  inherit ErrorType ErrorSeverity ErrorCategory;
}
