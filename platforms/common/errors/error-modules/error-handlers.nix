# Error Handlers Module
# Error handling and recovery logic
{
  lib,
  pkgs,
  ...
}: let
  # ERROR HANDLERS - TYPE-SAFE ERROR MANAGEMENT
  ErrorHandler = {
    ErrorDefinitions,
    errorType,
    errorCode,
    context,
    systemConfig,
  }: let
    errorDef =
      ErrorDefinitions.${errorType}.${errorCode} or
        ErrorDefinitions.build.compilation_failed; # Default fallback

    inherit (errorDef) severity;
    inherit (errorDef) autoRetry;
    inherit (errorDef) rollbackable;
    inherit (errorDef) notifyUser;
    inherit (errorDef) logLevel;
    inherit (errorDef) recoveryActions;

    # Context enrichment
    enrichedContext =
      context
      // {
        timestamp = builtins.currentTime;
        inherit systemConfig;
        errorDefinition = errorDef;
        recoveryAttempted = false;
      };

    # Error message generation
    generateErrorMessage = let
      baseMessage = "Error ${errorType}:${errorCode}";
      contextMessage =
        if builtins.isContext context
        then lib.concatStringsSep ", " (map (name: "${name}=${builtins.toString context.${name}}") (builtins.attrNames context))
        else "";
      severityMessage = "[${severity}]";
    in "${severityMessage} ${baseMessage}${
      if contextMessage != ""
      then " - ${contextMessage}"
      else ""
    }";

    # Recovery action execution
    executeRecoveryAction = action: let
      recoveryResult =
        if action == "check_package_name"
        then lib.hasAttr (context.packageName or "") pkgs
        else if action == "clean_build"
        then true # Would execute actual clean build
        else if action == "retry_build"
        then true # Would execute retry
        else if action == "check_platform"
        then true # Would execute platform check
        else true
        # Default to true for demonstration
        ;
    in {
      inherit action;
      success = recoveryResult;
      timestamp = builtins.currentTime;
    };

    recoveryResults = map executeRecoveryAction recoveryActions;

    anyRecoverySuccessful = lib.any (result: result.success) recoveryResults;

    # Log error
    logError = let
      logLevelStr = logLevel;
      message = generateErrorMessage;
    in {
      timestamp = builtins.currentTime;
      level = logLevelStr;
      inherit message;
      context = enrichedContext;
      recovery = recoveryResults;
    };
  in {
    error = {
      type = errorType;
      code = errorCode;
      inherit severity;
      inherit autoRetry;
      inherit rollbackable;
      inherit notifyUser;
      context = enrichedContext;
      message = generateErrorMessage;
      recoveryActions = recoveryResults;
      inherit anyRecoverySuccessful;
    };
    log = logError;
  };
in {
  inherit ErrorHandler;
}
