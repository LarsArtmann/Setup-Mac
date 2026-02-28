{
  lib,
  stdenv,
  fetchurl,
  bun,
  makeWrapper,
  nodejs,
}:

stdenv.mkDerivation rec {
  pname = "portless";
  version = "0.4.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-DX5L9c2xZ86VIJd7SZisO30huffjhRSqkpu7UAN4Wwo=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bun nodejs ];

  # npm pack tarballs have a 'package' directory
  sourceRoot = "package";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/portless
    cp -r . $out/lib/node_modules/portless/

    # Install dependencies with bun (much faster than npm)
    cd $out/lib/node_modules/portless
    bun install --production --ignore-scripts

    # Create bin directory and wrapper
    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/portless \
      --add-flags "$out/lib/node_modules/portless/dist/cli.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Replace port numbers with stable, named .localhost URLs";
    homepage = "https://github.com/vercel-labs/portless";
    license = licenses.asl20;
    platforms = platforms.darwin ++ platforms.linux;
    mainProgram = "portless";
  };
}
