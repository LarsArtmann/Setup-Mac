{
  lib,
  buildGoModule,
  go-replaces,
}: {
  pname,
  src,
  description,
  homepage ? "https://github.com/LarsArtmann/${pname}",
  mainProgram ? pname,
  vendorHash,
  postPatch ? "",
  buildInputs ? [],
  nativeBuildInputs ? [],
  preBuild ? "",
  modTidy ? false,
  doCheck ? false,
  ldflags ? ["-s" "-w"],
  subPackages ? [],
  version ? "0.0.0",
}:
buildGoModule {
  inherit pname version src vendorHash buildInputs nativeBuildInputs doCheck ldflags subPackages;

  proxyVendor = true;

  env = {
    GOPRIVATE = "github.com/LarsArtmann/*";
    GONOSUMCHECK = "github.com/LarsArtmann/*";
    GONOSUMDB = "github.com/LarsArtmann/*";
  };

  postPatch = ''
    # Remove existing replace directives that point to absolute or parent paths
    sed -i '/^replace\s\+github\.com\/[Ll]ars[Aa]rtmann.*=> \/.*$/d' go.mod
    sed -i '/^replace\s\+github\.com\/[Ll]ars[Aa]rtmann.*=> \.\.\//d' go.mod
    # Remove LarsArtmann entries from replace blocks
    sed -i '/^replace ($/,/^)$/{
      /github\.com\/[Ll]ars[Aa]rtmann/d
    }' go.mod
    # Append fresh replace directives from go-replaces
    echo '${go-replaces}' >> go.mod
    # Remove self-replace (don't replace the main module with itself)
    sed -i '/replace github\.com\/[Ll]ars[Aa]rtmann\/${pname} =>/d' go.mod
    ${lib.optionalString modTidy ''
      # Prune replace directives for modules not in require to avoid go mod tidy errors
      awk '
      BEGIN { in_req=0 }
      /^require \(/ { in_req=1; next }
      in_req && /^\)/ { in_req=0; next }
      in_req { gsub(/ .*/, "", $0); req[$0]=1 }
      !/^replace / { print; next }
      /^replace / {
        # Extract module path: "replace github.com/... => ..."
        mod = $2
        if (mod in req) print
        else if (/=> \.\//) print
        next
      }
      ' go.mod > go.mod.tmp && mv go.mod.tmp go.mod
    ''}
    ${postPatch}
  '';

  inherit preBuild;

  meta = with lib; {
    inherit description homepage mainProgram;
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
