# Validation.nix - TYPE-SAFE VALIDATION SYSTEM
# CENTRALIZED VALIDATION WITH STRONG TYPE GUARANTEES
{lib, ...}: let
  # PLATFORM-SPECIFIC VALIDATION FUNCTIONS
  validateDarwin = pkg: let
    platforms = pkg.meta.platforms or ["all"];
    isDarwin = lib.any (p: lib.hasSuffix "darwin" p) platforms;
  in
    isDarwin || (builtins.trace "⚠️  ${lib.getName pkg}: Not compatible with Darwin platform" false);

  validateLinux = pkg: let
    platforms = pkg.meta.platforms or ["all"];
    isLinux = lib.any (p: lib.hasSuffix "linux" p) platforms;
  in
    isLinux || (builtins.trace "⚠️  ${lib.getName pkg}: Not compatible with Linux platform" false);

  validateAarch64 = pkg: let
    platforms = pkg.meta.platforms or ["all"];
    isAarch64 = lib.any (p: lib.hasPrefix "aarch64" p) platforms;
  in
    isAarch64 || (builtins.trace "⚠️  ${lib.getName pkg}: Not compatible with aarch64 platform" false);

  validateX86_64 = pkg: let
    platforms = pkg.meta.platforms or ["all"];
    isX86_64 = lib.any (p: lib.hasPrefix "x86_64" p) platforms;
  in
    isX86_64 || (builtins.trace "⚠️  ${lib.getName pkg}: Not compatible with x86_64 platform" false);

  # LICENSE VALIDATION - TYPE-SAFE
  validateLicense = allowedLicenses: pkg: let
    license = pkg.meta.license or [];
    isUnfree = lib.any (l: (l.shortDescription or l) == "unfree") license;
    isAllowed = lib.any (allowed: lib.any (l: lib.hasInfix allowed (l.shortDescription or l)) license) allowedLicenses;
  in
    if isUnfree
    then isAllowed
    else
      true
      || (builtins.trace "❌ ${lib.getName pkg}: License ${lib.concatStringsSep ", " (map (l: l.shortDescription or "unknown") license)} not in allowed list ${lib.concatStringsSep ", " allowedLicenses}" false);

  # DEPENDENCY VALIDATION - TYPE-SAFE
  validateDependencies = packages: pkg: let
    dependencies = pkg.buildInputs or [] ++ pkg.nativeBuildInputs or [];
    missingDeps = lib.filter (dep: !(lib.any (p: p == dep) packages)) dependencies;
    essentialMissing = lib.filter (dep: (dep.config or {}).essential or false) missingDeps;
  in {
    allAvailable = (builtins.length missingDeps) == 0;
    missingDependencies = missingDeps;
    inherit essentialMissing;
  };

  # VALIDATE CROSS-PLATFORM PACKAGE - TYPE-SAFE
  validateCrossPlatformPackage = pkg: system: let
    isCrossPlatform =
      lib.any (p: lib.hasSuffix "darwin" p) (pkg.meta.platforms or [])
      && lib.any (p: lib.hasSuffix "linux" p) (pkg.meta.platforms or []);

    # Check if package supports current system
    supportsCurrentSystem =
      if system.isDarwin
      then lib.any (p: lib.hasSuffix "darwin" p) (pkg.meta.platforms or [])
      else if system.isLinux
      then lib.any (p: lib.hasSuffix "linux" p) (pkg.meta.platforms or [])
      else false;

    # Check architecture support
    currentArch =
      if system.isAarch64
      then "aarch64"
      else if system.isx86_64
      then "x86_64"
      else "unknown";
    archSupported = lib.any (p: lib.hasPrefix currentArch p) (pkg.meta.platforms or []);

    # Check passthru attributes for cross-platform packages
    hasValidPassthru =
      pkg ? passthru
      && pkg.passthru ? platform
      && pkg.passthru ? arch;

    # Validate binary path exists
    hasValidBinaryPath = pkg ? passthru && pkg.passthru ? binaryPath;
  in {
    inherit isCrossPlatform;
    inherit supportsCurrentSystem;
    inherit currentArch;
    inherit archSupported;
    inherit hasValidPassthru;
    inherit hasValidBinaryPath;
    valid = supportsCurrentSystem && archSupported && hasValidPassthru && hasValidBinaryPath;
  };
in {
  inherit
    validateDarwin
    validateLinux
    validateAarch64
    validateX86_64
    validateLicense
    validateDependencies
    validateCrossPlatformPackage
    ;
}
