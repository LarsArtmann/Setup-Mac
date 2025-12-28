{
  lib,
  pkgs,
}: let
  inherit (pkgs.stdenv) isAarch64;
  inherit (pkgs.stdenv) isx86_64;
in
  pkgs.stdenv.mkDerivation rec {
    pname = "helium";
    version = "0.7.6.1";

    src = pkgs.fetchurl {
      url = "https://github.com/imputnet/helium-macos/releases/download/${version}/helium_${version}_${
            if isAarch64
            then "arm64"
            else "x86_64"
          }-macos.dmg";
      sha256 =
        if isAarch64
        then "sha256-f35ecf26fdde1d8cd85222e65b1b670553a553fe964b9435d8a2945503703808"
        else "sha256-81030f17fddc05fe18797cd9561b565a9478813b5e2e3cd38fe2b7b0ebb83914";
    };

    nativeBuildInputs = with pkgs; [makeWrapper copyDesktopItems undmg];

    # macOS needs no runtime dependencies
    buildInputs = [];

    installPhase = ''
      runHook preInstall

      # macOS installation
      mkdir -p $out/Applications
      cp -R "Helium.app" $out/Applications/

      # Create CLI wrapper for macOS
      mkdir -p $out/bin
      makeWrapper "$out/Applications/Helium.app/Contents/MacOS/Helium" $out/bin/helium

      runHook postInstall
    '';

    passthru = {
      binaryPath = "Applications/Helium.app/Contents/MacOS/Helium";
      platform = "darwin";
      arch = if isAarch64 then "arm64" else "x86_64";
    };

    meta = with lib; {
      description = "Private, fast, and honest web browser based on ungoogled-chromium";
      homepage = "https://helium.computer";
      license = licenses.gpl3Only;
      platforms = platforms.darwin;
      mainProgram = "helium";
    };
  }
