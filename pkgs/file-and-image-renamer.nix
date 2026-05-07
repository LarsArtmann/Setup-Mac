{
  lib,
  buildGoModule,
  file-and-image-renamer-src,
  cmdguard-src,
  go-output-src,
}:
buildGoModule rec {
  pname = "file-and-image-renamer";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    filter = path: _type: let
      b = baseNameOf path;
    in
      !(
        b
        == "vendor"
        || b == ".git"
        || b == "docs"
        || b == ".crush"
        || b == "justfile"
        || b == "scripts"
        || b == ".envrc"
        || b == "env.local"
        || b == "integration-test.sh"
        || b == "batch-process-all.sh"
        || b == "process-remaining.sh"
        || b == "batch-processing.log"
        || lib.hasSuffix ".plist" b
        || lib.hasSuffix ".toml" b
        || lib.hasSuffix ".md" b
      );
    src = file-and-image-renamer-src;
  };

  vendorHash = "sha256-JPL3Am/8w3EccJaU/KN/NYyDEuLy+Y9GlSkV00i/DGc=";

  proxyVendor = true;

  subPackages = ["cmd/file-renamer"];

  postPatch = ''
    substituteInPlace go.mod \
      --replace-warn 'replace github.com/larsartmann/cmdguard => /home/lars/projects/cmdguard' 'replace github.com/larsartmann/cmdguard => ${cmdguard-src}' \
      --replace-warn 'replace github.com/larsartmann/go-output => /home/lars/projects/go-output' 'replace github.com/larsartmann/go-output => ${go-output-src}'
    if ! grep -q 'replace github.com/larsartmann/cmdguard => ${cmdguard-src}' go.mod; then
      echo -e '\nreplace github.com/larsartmann/cmdguard => ${cmdguard-src}' >> go.mod
    fi
    if ! grep -q 'replace github.com/larsartmann/go-output => ${go-output-src}' go.mod; then
      echo -e '\nreplace github.com/larsartmann/go-output => ${go-output-src}' >> go.mod
    fi

    # go-output sub-modules (Go workspace modules — separate go.mod per dir)
    for sub in enum escape table sort; do
      echo "require github.com/larsartmann/go-output/$sub v0.0.0" >> go.mod
      echo "replace github.com/larsartmann/go-output/$sub => ${go-output-src}/$sub" >> go.mod
    done
  '';

  ldflags = ["-s" "-w"];

  meta = with lib; {
    description = "AI-powered screenshot and image renaming tool using GLM-4.6V Vision API";
    homepage = "https://github.com/larsartmann/file-and-image-renamer";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "file-renamer";
  };
}
