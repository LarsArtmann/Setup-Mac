# Error Definitions Module
# Centralized error definitions dictionary

{ lib, ... }:

let
  # CENTRALIZED ERROR DEFINITIONS
  ErrorDefinitions = {
    validation = {
      package_not_found = {
        type = "validation";
        severity = "critical";
        autoRetry = false;
        rollbackable = false;
        notifyUser = true;
        logLevel = "error";
        recoveryActions = ["check_package_name" "verify_nixpkgs"];
      };
      invalid_template = {
        type = "validation";
        severity = "high";
        autoRetry = false;
        rollbackable = true;
        notifyUser = true;
        logLevel = "error";
        recoveryActions = ["reset_template" "use_default"];
      };
      type_mismatch = {
        type = "validation";
        severity = "high";
        autoRetry = false;
        rollbackable = true;
        notifyUser = true;
        logLevel = "error";
        recoveryActions = ["convert_type" "reset_to_default"];
      };
    };

    build = {
      compilation_failed = {
        type = "build";
        severity = "high";
        autoRetry = true;
        rollbackable = true;
        notifyUser = true;
        logLevel = "error";
        recoveryActions = ["clean_build" "retry_build"];
      };
      dependency_missing = {
        type = "build";
        severity = "critical";
        autoRetry = false;
        rollbackable = false;
        notifyUser = true;
        logLevel = "error";
        recoveryActions = ["install_dependency" "check_alternatives"];
      };
      platform_incompatible = {
        type = "build";
        severity = "critical";
        autoRetry = false;
        rollbackable = false;
        notifyUser = true;
        logLevel = "error";
        recoveryActions = ["check_platform" "find_alternative"];
      };
    };

    runtime = {
      wrapper_execution_failed = {
        type = "runtime";
        severity = "medium";
        autoRetry = true;
        rollbackable = true;
        notifyUser = true;
        logLevel = "warn";
        recoveryActions = ["restart_wrapper" "check_permissions"];
      };
      performance_threshold_exceeded = {
        type = "runtime";
        severity = "low";
        autoRetry = false;
        rollbackable = true;
        notifyUser = false;
        logLevel = "info";
        recoveryActions = ["optimize_performance" "reduce_usage"];
      };
    };

    configuration = {
      path_consistency_error = {
        type = "configuration";
        severity = "high";
        autoRetry = false;
        rollbackable = true;
        notifyUser = true;
        logLevel = "error";
        recoveryActions = ["fix_paths" "reset_to_defaults"];
      };
      duplicate_configuration = {
        type = "configuration";
        severity = "medium";
        autoRetry = false;
        rollbackable = true;
        notifyUser = true;
        logLevel = "warn";
        recoveryActions = ["merge_configs" "remove_duplicate"];
      };
    };

    external = {
      tool_not_available = {
        type = "external";
        severity = "high";
        autoRetry = true;
        rollbackable = true;
        notifyUser = true;
        logLevel = "error";
        recoveryActions = ["check_tool_installation" "use_fallback"];
      };
      api_connection_failed = {
        type = "external";
        severity = "medium";
        autoRetry = true;
        rollbackable = true;
        notifyUser = true;
        logLevel = "warn";
        recoveryActions = ["retry_connection" "use_cached_data"];
      };
    };
  };

in {
  inherit ErrorDefinitions;
}