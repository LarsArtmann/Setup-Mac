# Validation.nix - TYPE-SAFE VALIDATION SYSTEM
# CENTRALIZED VALIDATION WITH STRONG TYPE GUARANTEES

{ lib, pkgs, State, Types, ... }:

let
  # PLATFORM-SPECIFIC VALIDATION FUNCTIONS
  validateDarwin = pkg:
    let
      platforms = pkg.meta.platforms or ["all"];
      isDarwin = lib.any (p: lib.hasPrefix "darwin" p) platforms;
    in isDarwin || (builtins.trace "⚠️  ${lib.getName pkg}: Not compatible with Darwin platform" false);

  validateLinux = pkg:
    let
      platforms = pkg.meta.platforms or ["all"];
      isLinux = lib.any (p: lib.hasPrefix "linux" p) platforms;
    in isLinux || (builtins.trace "⚠️  ${lib.getName pkg}: Not compatible with Linux platform" false);

  validateAarch64 = pkg:
    let
      platforms = pkg.meta.platforms or ["all"];
      isAarch64 = lib.any (p: lib.hasPrefix "aarch64" p) platforms;
    in isAarch64 || (builtins.trace "⚠️  ${lib.getName pkg}: Not compatible with aarch64 platform" false);

  validateX86_64 = pkg:
    let
      platforms = pkg.meta.platforms or ["all"];
      isX86_64 = lib.any (p: lib.hasPrefix "x86_64" p) platforms;
    in isX86_64 || (builtins.trace "⚠️  ${lib.getName pkg}: Not compatible with x86_64 platform" false);

  # LICENSE VALIDATION - TYPE-SAFE
  validateLicense = allowedLicenses: pkg:
    let
      license = pkg.meta.license or [];
      isUnfree = lib.any (l: (l.shortDescription or l) == "unfree") license;
      isAllowed = lib.any (allowed =>
        lib.any (l => lib.hasInfix allowed (l.shortDescription or l)) license
      ) allowedLicenses;
    in
      if isUnfree then isAllowed
      else true
      || (builtins.trace "❌ ${lib.getName pkg}: License ${lib.concatStringsSep ", " (map (l: l.shortDescription or "unknown") license)} not in allowed list ${lib.concatStringsSep ", " allowedLicenses}" false);

  # DEPENDENCY VALIDATION - TYPE-SAFE
  validateDependencies = packages: pkg:
    let
      dependencies = pkg.buildInputs or [] ++ pkg.nativeBuildInputs or [];
      missingDeps = lib.filter (dep: !(lib.any (p: p == dep) packages)) dependencies;
      essentialMissing = lib.filter (dep: (dep.config or {}).essential or false) missingDeps;
    in {
      allAvailable = (builtins.length missingDeps) == 0;
      missingDependencies = missingDeps;
      essentialMissing = essentialMissing;
    };

  # CONFIGURATION VALIDATION - TYPE-SAFE
  validateConfig = wrapper: config:
    let
      requiredFields = wrapper.config.requiredFields or [];
      missingFields = lib.filter (field: !config ? field) requiredFields;
      invalidFields = lib.filter (field: config ? field && !(wrapper.config.validFields or {} ? field)) (lib.attrNames config);
    in {
      allPresent = (builtins.length missingFields) == 0;
      missingFields = missingFields;
      allValid = (builtins.length invalidFields) == 0;
      invalidFields = invalidFields;
    };

  # PERFORMANCE VALIDATION - TYPE-SAFE
  validatePerformance = wrapper: actualPerformance:
    let
      expectedPerformance = wrapper.performance or {};
      maxMemory = expectedPerformance.maxMemory or 512;
      actualMemory = actualPerformance.memory or 0;
      isMemoryWithinLimit = actualMemory <= maxMemory;
    in {
      memoryValid = isMemoryWithinLimit;
      memoryUsage = "${toString actualMemory}MB / ${toString maxMemory}MB";
      memoryExcess = if actualMemory > maxMemory then "${toString (actualMemory - maxMemory)}MB over limit" else "within limits";
    };

  # COMPREHENSIVE VALIDATION PIPELINE
  validateWrapper = wrapper: level: system:
    let
      package = wrapper.package;
      wrapperType = wrapper.type or "cli-tool";
      platform = wrapper.platform or "all";

      # Level-based validation
      strictValidation = level == "strict";
      standardValidation = level == "standard";
      noValidation = level == "none";

      # Core validations
      packageValid = package ? outPath && package ? meta;
      platformValid =
        if platform == "all" then true
        else if platform == "darwin" then validateDarwin package
        else if platform == "linux" then validateLinux package
        else if platform == "aarch64-darwin" then validateAarch64 package
        else if platform == "x86_64-darwin" then validateX86_64 package
        else true;

      typeValid = lib.elem wrapperType ["cli-tool" "gui-app" "shell" "service" "dev-env"];

      # Level-dependent validations
      strictValid =
        if strictValidation then
          validateLicense system.allowedUnfreeLicenses package &&
          (validateDependencies system.packages package).allAvailable
        else true;

      # Configuration validation for standard+ levels
      configValid =
        if (standardValidation || strictValidation) then
          (validateConfig wrapper wrapper.config).allPresent &&
          (validateConfig wrapper wrapper.config).allValid
        else true;

      # Performance validation for strict level
      perfValid =
        if strictValidation then
          (validatePerformance wrapper (wrapper.performance or {})).memoryValid
        else true;

      # Overall validation result
      overallValid = packageValid && platformValid && typeValid && strictValid && configValid && perfValid;

      validationResults = {
        package = {
          valid = packageValid;
          name = lib.getName package;
          version = lib.getVersion package;
        };
        platform = {
          valid = platformValid;
          required = platform;
        };
        type = {
          valid = typeValid;
          actual = wrapperType;
        };
        license = {
          valid = strictValidation ? (validateLicense system.allowedUnfreeLicenses package) : true;
          skipped = !strictValidation;
        };
        dependencies = {
          valid = strictValidation ? ((validateDependencies system.packages package).allAvailable) : true;
          skipped = !strictValidation;
          missing = (validateDependencies system.packages package).missingDependencies;
          essentialMissing = (validateDependencies system.packages package).essentialMissing;
        };
        config = {
          valid = configValid;
          skipped = !standardValidation && !strictValidation;
        };
        performance = {
          valid = perfValid;
          skipped = !strictValidation;
        };
        overall = overallValid;
        level = level;
      };

    in validationResults;

in {
  inherit
    validateDarwin validateLinux validateAarch64 validateX86_64
    validateLicense validateDependencies validateConfig validatePerformance
    validateWrapper;
}
