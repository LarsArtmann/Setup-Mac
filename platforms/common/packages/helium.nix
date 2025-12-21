{ lib
, pkgs
}:

pkgs.stdenv.mkDerivation rec {
  pname = "helium";
  version = "0.7.6.1";

  # Architecture-specific source handling (2025 best practice)
  src = pkgs.fetchurl {
    url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_${if pkgs.stdenv.isAarch64 then "arm64" else "x86_64"}-macos.dmg";
    sha256 = if pkgs.stdenv.isAarch64
      then "sha256-f35ecf26fdde1d8cd85222e65b1b670553a553fe964b9435d8a2945503703808" # ARM64 hash
      else "sha256-81030f17fddc05fe18797cd9561b565a9478813b5e2e3cd38fe2b7b0ebb83914"; # x86_64 hash
  };

  # Build inputs (2025 best practice: explicit dependencies)
  nativeBuildInputs = with pkgs; [ undmg ];

  # Best practice: explicit source root
  sourceRoot = ".";

  # Improved installPhase with proper structure
  installPhase = ''
    runHook preInstall

    # Install application bundle (macOS standard)
    mkdir -p $out/Applications
    cp -R "Helium.app" $out/Applications/

    # Create CLI wrapper (following Darwin app conventions)
    mkdir -p $out/bin
    cat > $out/bin/helium << EOF
#!/bin/bash
exec "$out/Applications/Helium.app/Contents/MacOS/Helium" "\$@"
EOF
    chmod +x $out/bin/helium

    runHook postInstall
  '';

  # Optional: Add desktop entry for GUI integration
  # desktopItems = [ ... ];

  # Comprehensive metadata (2025 standard)
  meta = with lib; {
    description = "Privacy-focused web browser based on ungoogled-chromium";
    longDescription = ''
      Helium is a "bullshit-free" web browser built on ungoogled-chromium
      that prioritizes privacy and user experience. It aims to provide an
      honest, comfortable, privacy-respecting, and non-invasive browsing experience.
    '';
    homepage = "https://helium.computer";
    downloadPage = "https://github.com/imputnet/helium-macos/releases";
    changelog = "https://github.com/imputnet/helium-macos/releases/tag/${version}";
    license = licenses.gpl3Only;
    platforms = platforms.darwin;
    maintainers = with maintainers; [
      # Add your maintainer info here
    ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    # Mark as unfree if needed
    # unfree = true;
    mainProgram = "helium";
    # Supported macOS versions
    broken = pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.system == "x86_64-darwin" && lib.versionOlder pkgs.stdenv.hostPlatform.darwinMinVersion "10.15";
  };
}