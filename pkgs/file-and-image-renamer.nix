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
        || (lib.hasSuffix ".md" b && b != "go.mod" && b != "go.sum")
      );
    src = file-and-image-renamer-src;
  };

  vendorHash = "sha256-KSAkJXZ+40jkceXUv0+CFxUO9otFTOvMl3hq8mfCvXA=";

  proxyVendor = true;

  subPackages = ["cmd/file-renamer"];

  # Patch go.mod replace directives to point to nix store paths.
  # The local replace directives (/home/lars/projects/...) only work on the dev machine.
  # In the nix sandbox we substitute them with the actual source from flake inputs.
  postPatch = ''
    substituteInPlace go.mod \
      --replace-fail 'replace github.com/larsartmann/cmdguard => /home/lars/projects/cmdguard' 'replace github.com/larsartmann/cmdguard => ${cmdguard-src}' \
      --replace-fail 'replace github.com/larsartmann/go-output => /home/lars/projects/go-output' 'replace github.com/larsartmann/go-output => ${go-output-src}'
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
