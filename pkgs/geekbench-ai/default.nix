{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  gcc,
  glib,
  zlib,
  pkgs,
}:
stdenv.mkDerivation rec {
  pname = "geekbench-ai";
  version = "1.6.0";

  src = fetchurl {
    url = "https://cdn.geekbench.com/GeekbenchAI-${version}-Linux.tar.gz";
    sha256 = "6ba6a080bc8806f3c9f2082e5ca4b3a82c3f07028ff47ded5129b004e181c1f9";
  };

  nativeBuildInputs = [autoPatchelfHook];

  buildInputs = [gcc glib zlib];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/lib

    # Copy all libraries
    cp lib* $out/lib/

    # Copy all binaries
    cp banff banff_x86_64 banff_avx2 $out/bin/

    # Make binaries executable
    chmod +x $out/bin/*

    # Use banff_x86_64 as the main binary (no external AI libs needed)
    ln -sf $out/bin/banff_x86_64 $out/bin/geekbench-ai

    runHook postInstall
  '';

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  meta = {
    description = "AI benchmarking tool from Geekbench";
    homepage = "https://www.geekbench.com/ai";
    license = lib.licenses.unfree;
    maintainers = [];
    platforms = lib.platforms.linux;
  };
}
