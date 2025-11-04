# ExternalTools.nix - ADAPTER PATTERN IMPLEMENTATION
# CLEAN ABSTRACTION FOR ALL EXTERNAL DEPENDENCIES

{ lib, pkgs, inputs, State, Types, Validation, ... }:

let
  # AI TOOLS ADAPTER - CLEAN ABSTRACTION
  AIAdapter = { aiTools }:
    let
      crush = aiTools.packages.${pkgs.system}.crush or null;

      validateAITool = tool:
        let
          packageValid = tool != null && (tool ? outPath);
          version = if packageValid then lib.getVersion tool else "unavailable";
        in {
          available = packageValid;
          version = version;
          name = "crush";
        };

      validatedTools = map validateAITool [crush];
      allAvailable = lib.all (t: t.available) validatedTools;

    in {
      tools = validatedTools;
      available = allAvailable;
      version = if allAvailable then "functional" else "partial";
      errors = lib.filter (t: !t.available) validatedTools;
    };

  # TREEFMT ADAPTER - CLEAN ABSTRACTION
  TreefmtAdapter = { treefmt }:
    let
      available = treefmt ? flakeModule;
      version = treefmt.version or "unknown";

      supportedFormatters = [
        "nix" "shell" "yaml" "json" "python" "rust" "toml"
      ];

      validateFormatter = formatter:
        let
          package = pkgs."${formatter}fmt" or null;
          available = package != null && (package ? outPath);
        in {
          name = formatter;
          available = available;
          package = package;
        };

      validatedFormatters = map validateFormatter supportedFormatters;
      availableFormatters = lib.filter (f: f.available) validatedFormatters;

    in {
      available = available;
      version = version;
      formatters = validatedFormatters;
      workingFormatters = availableFormatters;
      coverage = lib.floor ((builtins.length availableFormatters) * 100.0 / (builtins.length supportedFormatters));
    };

  # MONITORING ADAPTER - CLEAN ABSTRACTION
  MonitoringAdapter = { config }:
    let
      netdata = pkgs.netdata or null;
      adguardian = pkgs.adguardian or null;

      validateMonitorTool = tool: name:
        let
          packageValid = tool != null && (tool ? outPath);
          version = if packageValid then lib.getVersion tool else "unavailable";
          autoStart = config.autoStart or false;
        in {
          name = name;
          available = packageValid;
          version = version;
          autoStart = autoStart;
          type = "monitoring";
        };

      validatedTools = [
        (validateMonitorTool netdata "netdata")
        (validateMonitorTool adguardian "adguardian")
      ];

      availableTools = lib.filter (t: t.available) validatedTools;
      allAvailable = (builtins.length availableTools) >= 2;

    in {
      tools = validatedTools;
      availableTools = availableTools;
      allAvailable = allAvailable;
      status = if allAvailable then "fully-functional" else "partial";
    };

  # PACKAGE MANAGEMENT ADAPTER - CLEAN ABSTRACTION
  PackageManagementAdapter = { config }:
    let
      homebrew = pkgs.homebrew or null;
      nix = pkgs.nix or null;

      validatePackageTool = tool: name:
        let
          packageValid = tool != null && (tool ? outPath);
          version = if packageValid then lib.getVersion tool else "unavailable";
        in {
          name = name;
          available = packageValid;
          version = version;
        };

      validatedTools = [
        (validatePackageTool homebrew "homebrew")
        (validatePackageTool nix "nix")
      ];

      availableTools = lib.filter (t: t.available) validatedTools;

    in {
      tools = validatedTools;
      availableTools = availableTools;
      totalTools = builtins.length validatedTools;
      workingTools = builtins.length availableTools;
    };

  # VALIDATION WRAPPER ADAPTER - CLEAN ABSTRACTION
  ValidationWrapperAdapter = { validationConfig }:
    let
      validateWithLevel = wrapper: level:
        Validation.validateWrapper wrapper level validationConfig;

      validateAll = wrappers: level:
        let
          validationResults = map (wrapper: validateWithLevel wrapper level) wrappers;
          allValid = lib.all (r: r.overall.valid) validationResults;
          failedValidations = lib.filter (r: !r.overall.valid) validationResults;
        in {
          wrappers = validationResults;
          allValid = allValid;
          failedCount = builtins.length failedValidations;
          failedWrappers = failedValidations;
          level = level;
        };

    in {
      validateWrapper = validateWithLevel;
      validateAll = validateAll;
    };

  # PERFORMANCE MONITORING ADAPTER - CLEAN ABSTRACTION
  PerformanceMonitoringAdapter = { config }:
    let
      trackPerformance = wrapper: action:
        let
          startTime = builtins.currentTime;
          result = action;
          endTime = builtins.currentTime;
          duration = endTime - startTime;

          performanceData = {
            wrapperName = wrapper.name;
            action = action.type or "unknown";
            duration = duration;
            startTime = startTime;
            endTime = endTime;
            success = result.success or true;
            memoryUsage = result.memoryUsage or 0;
            cpuUsage = result.cpuUsage or 0;
          };

          withinLimits =
            (result.memoryUsage or 0) <= (wrapper.performance.maxMemory or 512) &&
            duration <= (wrapper.performance.maxDuration or 30);

        in {
          performance = performanceData;
          withinLimits = withinLimits;
          valid = result.success or true && withinLimits;
        };

      trackAllPerformances = wrappers: action:
        let
          results = map (wrapper: trackPerformance wrapper action) wrappers;
          allValid = lib.all (r: r.valid) results;
          invalidPerformances = lib.filter (r: !r.valid) results;
        in {
          results = results;
          allValid = allValid;
          invalidPerformances = invalidPerformances;
        };

    in {
      trackPerformance = trackPerformance;
      trackAllPerformances = trackAllPerformances;
    };

in {
  inherit
    AIAdapter TreefmtAdapter MonitoringAdapter
    PackageManagementAdapter ValidationWrapperAdapter
    PerformanceMonitoringAdapter;
}
