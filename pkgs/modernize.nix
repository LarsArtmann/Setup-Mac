{pkgs}: let
  inherit (pkgs) lib;
in
  pkgs.buildGoModule rec {
    pname = "modernize";
    version = "0-unstable-2025-12-05";

    src = pkgs.fetchFromGitHub {
      owner = "golang";
      repo = "tools";
      rev = "ecc727ef4e92b7170abe1881910c4c8773800196";
      sha256 = "sha256-fPG8//DWA0mzqZkYasiBdB5hw5FDRkr/3+ZXm7fNHRg=";
    };

    # Build only the modernize subdirectory
    subPackages = ["go/analysis/passes/modernize/cmd/modernize"];

    # Disable tests for faster builds
    doCheck = false;

    # Vendor hash
    vendorHash = "sha256-FVtHrFgxgDBAfU4x4+zANNhGa3pfsh3XgEQaQYdV1Bs=";

    meta = with lib; {
      description = "Modernize tool for Go code - built from golang.org/x/tools with Go 1.26rc3";
      homepage = "https://pkg.go.dev/golang.org/x/tools/gopls/internal/analysis/modernize";
      license = licenses.bsd3;
      platforms = platforms.all;
    };
  }
