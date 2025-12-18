# Error Monitor Module
# Error monitoring and alerting system

{ lib, ... }:

let
  # MONITORING AND ALERTING
  ErrorMonitor = { config, thresholds }:
    let
      monitorErrors = errors:
        let
          errorCount = builtins.length errors;
          criticalCount = builtins.length (lib.filter (e: e.error.severity == "critical") errors);

          alertThresholds = thresholds // {
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
      thresholds = thresholds // {
        criticalThreshold = 1;
        totalThreshold = 5;
      };
    };

in {
  inherit ErrorMonitor;
}