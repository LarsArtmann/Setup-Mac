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

  env =
    {
      GOPRIVATE = "github.com/LarsArtmann/*";
      GONOSUMCHECK = "github.com/LarsArtmann/*";
      GONOSUMDB = "github.com/LarsArtmann/*";
    }
    // lib.optionalAttrs modTidy {
      GONOSUMCHECK = "*";
      GONOSUMDB = "off";
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
    ${postPatch}
  '';

  preBuild =
    lib.optionalString modTidy ''
      go mod tidy
    ''
    + preBuild;

  meta = with lib; {
    inherit description homepage mainProgram;
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
