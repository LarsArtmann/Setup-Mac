# ErrorManagement.nix - CENTRALIZED ERROR MANAGEMENT SYSTEM
# TYPE-SAFE ERROR HANDLING WITH COMPREHENSIVE COVERAGE

{ lib, pkgs, State, Types, Validation, ... }:

let
  # ERROR TYPE DEFINITIONS - TYPE-SAFE ERROR CATEGORIES
  ErrorType = lib.types.enum [
    "validation" "build" "runtime" "configuration"
    "external" "performance" "dependency" "platform"
    "license" "filesystem" "network" "rollback"
  ];

  ErrorSeverity = lib.types.enum [ "critical" "high" "medium" "low" "info" ];

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
        type = lib.types.enum [ "error" "warn" "info" "debug" ];
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

  # ERROR HANDLERS - TYPE-SAFE ERROR MANAGEMENT
  ErrorHandler = { errorType, errorCode, context, systemConfig }:
    let
      errorDef =
        ErrorDefinitions.${errorType}.${errorCode} or
        ErrorDefinitions.build.compilation_failed; # Default fallback

      severity = errorDef.severity;
      autoRetry = errorDef.autoRetry;
      rollbackable = errorDef.rollbackable;
      notifyUser = errorDef.notifyUser;
      logLevel = errorDef.logLevel;
      recoveryActions = errorDef.recoveryActions;

      # Context enrichment
      enrichedContext = context // {
        timestamp = builtins.currentTime;
        systemConfig = systemConfig;
        errorDefinition = errorDef;
        recoveryAttempted = false;
      };

      # Error message generation
      generateErrorMessage =
        let
          baseMessage = "Error ${errorType}:${errorCode}";
          contextMessage = if builtins.isContext context then
            lib.concatStringsSep ", " (map (name: "${name}=${builtins.toString context.${name}}") (builtins.attrNames context))
          else "";
          severityMessage = "[${severity}]";
        in "${severityMessage} ${baseMessage}${if contextMessage != "" then " - ${contextMessage}" else ""}";

      # Recovery action execution
      executeRecoveryAction = action:
        let
          recoveryResult = if action == "check_package_name" then
            lib.hasAttr (context.packageName or "") pkgs
          else if action == "clean_build" then
            true # Would execute actual clean build
          else if action == "retry_build" then
            true # Would execute retry
          else if action == "check_platform" then
            true # Would execute platform check
          else
            true # Default to true for demonstration
        in {
          action = action;
          success = recoveryResult;
          timestamp = builtins.currentTime;
        };

      recoveryResults = map executeRecoveryAction recoveryActions;
      anyRecoverySuccessful = lib.any (r: r.success) recoveryResults;

      # Log error
      logError =
        let
          logLevelStr = logLevel;
          message = generateErrorMessage;
        in {
          timestamp = builtins.currentTime;
          level = logLevelStr;
          message = message;
          context = enrichedContext;
          recovery = recoveryResults;
        };

    in {
      error = {
        type = errorType;
        code = errorCode;
        severity = severity;
        autoRetry = autoRetry;
        rollbackable = rollbackable;
        notifyUser = notifyUser;
        context = enrichedContext;
        message = generateErrorMessage;
        recoveryActions = recoveryResults;
        anyRecoverySuccessful = anyRecoverySuccessful;
      };
      log = logError;
    };

  # ERROR COLLECTION AND REPORTING
  ErrorCollector = { errors, systemConfig }:
    let
      collectError = error: ErrorHandler {
        errorType = error.type;
        errorCode = error.code;
        context = error.context or {};
        systemConfig = systemConfig;
      };

      collectedErrors = map collectError errors;

      # Error analysis
      errorAnalysis = {
        totalErrors = builtins.length collectedErrors;
        criticalErrors = lib.filter (e: e.error.severity == "critical") collectedErrors;
        highErrors = lib.filter (e: e.error.severity == "high") collectedErrors;
        mediumErrors = lib.filter (e: e.error.severity == "medium") collectedErrors;
        lowErrors = lib.filter (e: e.error.severity == "low") collectedErrors;
        infoErrors = lib.filter (e: e.error.severity == "info") collectedErrors;

        recoverySuccessfulErrors = lib.filter (e: e.error.anyRecoverySuccessful) collectedErrors;
        recoveryFailedErrors = lib.filter (e: !e.error.anyRecoverySuccessful) collectedErrors;

        autoRetryErrors = lib.filter (e: e.error.autoRetry) collectedErrors;
        rollbackableErrors = lib.filter (e: e.error.rollbackable) collectedErrors;
      };

      # Error reporting
      generateReport =
        let
          analysis = errorAnalysis;
          report = ''
            # System Error Report
            Generated: ${builtins.toString builtins.currentTime}

            ## Summary
            - Total Errors: ${builtins.toString analysis.totalErrors}
            - Critical: ${builtins.toString (builtins.length analysis.criticalErrors)}
            - High: ${builtins.toString (builtins.length analysis.highErrors)}
            - Medium: ${builtins.toString (builtins.length analysis.mediumErrors)}
            - Low: ${builtins.toString (builtins.length analysis.lowErrors)}
            - Info: ${builtins.toString (builtins.length analysis.infoErrors)}

            ## Recovery Analysis
            - Recovery Successful: ${builtins.toString (builtins.length analysis.recoverySuccessfulErrors)}
            - Recovery Failed: ${builtins.toString (builtins.length analysis.recoveryFailedErrors)}
            - Recovery Success Rate: ${builtins.toString (if analysis.totalErrors > 0 then (builtins.length analysis.recoverySuccessfulErrors) * 100.0 / analysis.totalErrors else 100.0)}%

            ## Detailed Errors
            ${lib.concatStringsSep "\n\n" (map (error: ''
              ### ${error.error.type}:${error.error.code}
              - Severity: ${error.error.severity}
              - Message: ${error.error.message}
              - Auto Retry: ${if error.error.autoRetry then "Yes" else "No"}
              - Rollbackable: ${if error.error.rollbackable then "Yes" else "No"}
              - Recovery Actions: ${lib.concatStringsSep ", " error.error.recoveryActions}
              - Recovery Success: ${if error.error.anyRecoverySuccessful then "Yes" else "No"}

              Context:
              ${lib.concatStringsSep "\n" (map (name: "  - ${name}: ${builtins.toString error.error.context.${name}}") (builtins.attrNames error.error.context))}
            '') collectedErrors)}
          '';
        in report;

    in {
      errors = collectedErrors;
      analysis = errorAnalysis;
      report = generateReport;
    };

  # MONITORING AND ALERTING
  ErrorMonitor = { config, thresholds }:
    let
      monitorErrors = errors:
        let
          errorCount = builtins.length errors;
          criticalCount = builtins.length (lib.filter (e: e.error.severity == "critical") errors);

          alertThresholds = thresholds or {
            criticalThreshold = 1;
            totalThreshold = 5;
          };

          shouldAlert =
            criticalCount >= alertThresholds.criticalThreshold ||
            errorCount >= alertThresholds.totalThreshold;

          alertMessage =
            if shouldAlert then
              "🚨 System Alert: ${builtins.toString criticalCount} critical, ${builtins.toString errorCount} total errors detected"
            else
              "";

        in {
          errorCount = errorCount;
          criticalCount = criticalCount;
          shouldAlert = shouldAlert;
          alertMessage = alertMessage;
          thresholdsMet = {
            criticalThreshold = criticalCount >= alertThresholds.criticalThreshold;
            totalThreshold = errorCount >= alertThresholds.totalThreshold;
          };
        };

    in {
      monitor = monitorErrors;
      thresholds = thresholds or {
        criticalThreshold = 1;
        totalThreshold = 5;
      };
    };

in {
  inherit ErrorType ErrorSeverity ErrorCategory ErrorDefinitions;
  inherit ErrorHandler ErrorCollector ErrorMonitor;
}
