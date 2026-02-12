{
  lib,
  stdenv,
  fetchurl,
  bun,
  makeWrapper,
  nodejs,
}:

stdenv.mkDerivation rec {
  pname = "jscpd";
  version = "4.0.8";

  src = fetchurl {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-WgtPz/LdgqaIGt2hJjrH4loahhNKpuzkvi5BozRyLug=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bun nodejs ];

  # npm pack tarballs have a 'package' directory
  sourceRoot = "package";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/jscpd
    cp -r . $out/lib/node_modules/jscpd/

    # Install dependencies with bun (much faster than npm)
    cd $out/lib/node_modules/jscpd
    bun install --production --ignore-scripts

    # Create bin directory and wrapper
    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/jscpd \
      --add-flags "$out/lib/node_modules/jscpd/bin/jscpd"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Copy/paste detector for programming source code";
    homepage = "https://github.com/kucherenko/jscpd";
    license = licenses.mit;
    platforms = platforms.all;
    mainProgram = "jscpd";
  };
}
