# CLI Tool Wrapper Template
# TYPE-SAFE CLI TOOL WRAPPER GENERATION

{ pkgs, lib, stdenv, config, ... }:

let
  packageName = config.packageName or "unknown";
  wrapperName = config.wrapperName or "cli-wrapper";
  description = config.description or "CLI tool wrapper";
  additionalPackages = config.additionalPackages or [];
  aliasName = config.aliasName or "";

  # Input validation
  validateInputs =
    let
      packageValid = lib.hasAttr packageName pkgs;
      aliasValid = aliasName == "" || lib.isString aliasName;
    in {
      package = packageValid;
      alias = aliasValid;
      allValid = packageValid && aliasValid;
    };

  # Get package reference with validation
  basePackage =
    if validateInputs.package then
      pkgs.${packageName} or (builtins.throw "Package ${packageName} not found in nixpkgs")
    else
      builtins.throw "Invalid package name: ${packageName}";

  # Build wrapper command
  wrapperCommand = lib.concatStringsSep " " [
    "exec"
    basePackage.outPath or (builtins.throw "Package ${packageName} missing outPath")
    "\"$@\""
  ];

  # Create wrapper script
  wrapperScript = ''
    #!/bin/bash
    # CLI Tool Wrapper: ${wrapperName}
    # Generated from template: ${packageName}
    # Description: ${description}

    set -euo pipefail

    # Add additional packages to PATH
    ${lib.concatStringsSep "\n" (map (pkg: "export PATH=\"${lib.getBin pkg}/bin:$PATH\"") additionalPackages)}

    # Main command execution
    ${wrapperCommand}
  '';

in lib.mkIf validateInputs.allValid {
  # Create wrapper package
  wrapperPackage = stdenv.mkDerivation {
    name = "${wrapperName}-wrapper";
    version = lib.getVersion basePackage;

    # Dependencies
    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [ basePackage ] ++ additionalPackages;

    # Build phase
    buildPhase = ''
      mkdir -p $out/bin

      # Create main wrapper
      echo '${wrapperScript}' > $out/bin/${wrapperName}
      chmod +x $out/bin/${wrapperName}

      # Create alias if requested
      ${lib.optionalString (aliasName != "") ''
        echo '#!/bin/bash
        exec $out/bin/${wrapperName} "$@"' > $out/bin/${aliasName}
        chmod +x $out/bin/${aliasName}
      ''}

      # Wrap with makeWrapper for proper PATH handling
      wrapProgram $out/bin/${wrapperName} \
        --prefix PATH : "${lib.makeBinPath additionalPackages}" \
        --set WRAPPER_NAME "${wrapperName}" \
        --set WRAPPER_PACKAGE "${packageName}" \
        --set WRAPPER_DESCRIPTION "${description}"

      ${lib.optionalString (aliasName != "") ''
      wrapProgram $out/bin/${aliasName} \
        --prefix PATH : "${lib.makeBinPath additionalPackages}" \
        --set WRAPPER_NAME "${aliasName}" \
        --set WRAPPER_PACKAGE "${packageName}" \
        --set WRAPPER_DESCRIPTION "${description}"
      ''}
    '';

    # Metadata
    meta = with lib; {
      description = "Wrapper for ${packageName} CLI tool";
      longDescription = ''
        This is a generated wrapper for the ${packageName} CLI tool.

        ${description}

        Additional packages included: ${lib.concatStringsSep ", " (map (p: lib.getName p) additionalPackages)}
      '';

      homepage = basePackage.meta.homepage or "";
      downloadPage = basePackage.meta.downloadPage or "";
      changelog = basePackage.meta.changelog or "";
      license = basePackage.meta.license or [];
      platforms = basePackage.meta.platforms or [];
      maintainers = basePackage.meta.maintainers or [];

      # Template-specific metadata
      templateType = "cli-tool";
      inherit wrapperName;
      basePackage = packageName;
      toolDescription = description;
      additionalPackages = map (p: lib.getName p) additionalPackages;
      inherit aliasName;

      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      mainProgram = wrapperName;

      # Performance configuration
      performance = {
        lazyLoad = config.lazyLoad or false;
        maxMemory = config.maxMemory or 256;
        cache = config.cache or true;
      };
    };
  };
}
