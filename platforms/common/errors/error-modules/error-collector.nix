# Error Collector Module
# Error collection, analysis, and reporting
{lib, ...}: let
  # ERROR COLLECTION AND REPORTING
  ErrorCollector = {
    ErrorHandler,
    ErrorDefinitions,
    errors,
    systemConfig,
  }: let
    collectError = error:
      ErrorHandler {
        inherit ErrorDefinitions;
        errorType = error.type;
        errorCode = error.code;
        context = error.context // {};
        inherit systemConfig;
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
    generateReport = let
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
        - Recovery Success Rate: ${builtins.toString (
          if analysis.totalErrors > 0
          then (builtins.length analysis.recoverySuccessfulErrors) * 100.0 / analysis.totalErrors
          else 100.0
        )}%

        ## Detailed Errors
        ${lib.concatStringsSep "\n\n" (map (error: ''
            ### ${error.error.type}:${error.error.code}
            - Severity: ${error.error.severity}
            - Message: ${error.error.message}
            - Auto Retry: ${
              if error.error.autoRetry
              then "Yes"
              else "No"
            }
            - Rollbackable: ${
              if error.error.rollbackable
              then "Yes"
              else "No"
            }
            - Recovery Actions: ${lib.concatStringsSep ", " error.error.recoveryActions}
            - Recovery Success: ${
              if error.error.anyRecoverySuccessful
              then "Yes"
              else "No"
            }

            Context:
            ${lib.concatStringsSep "\n" (map (name: "  - ${name}: ${builtins.toString error.error.context.${name}}") (builtins.attrNames error.error.context))}
          '')
          collectedErrors)}
      '';
    in
      report;
  in {
    errors = collectedErrors;
    analysis = errorAnalysis;
    report = generateReport;
  };
in {
  inherit ErrorCollector;
}
