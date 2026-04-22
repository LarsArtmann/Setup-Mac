{
  lib,
  buildNpmPackage,
  fetchzip,
}:
buildNpmPackage rec {
  pname = "jscpd";
  version = "4.0.9";

  src = fetchzip {
    url = "https://registry.npmjs.org/jscpd/-/jscpd-${version}.tgz";
    hash = "sha256-aF6cIYBnK/ffO/0LPjKZZ99LsG4jpSfE7NEwQAUqZFQ=";
  };

  postPatch = ''
    cp ${./jscpd-package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-oNXT0opwP+85dpH6IVLhcEi8k26qiGVzQSkeIAPnys4=";

  npmFlags = ["--legacy-peer-deps"];

  dontNpmBuild = true;

  meta = {
    description = "Copy/paste detector for programming source code";
    homepage = "https://github.com/kucherenko/jscpd";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "jscpd";
  };
}
