{ lib }:

let
  # Platform detection utilities
  isDarwin = system: (lib.strings.hasInfix "darwin" system);
  isNixos = system: (lib.strings.hasInfix "linux" system);
  isAarch64 = system: (lib.strings.hasInfix "aarch64" system);
  isX86_64 = system: (lib.strings.hasInfix "x86_64" system);

  # Platform-specific package selectors
  selectPackage = system: darwinPkg: linuxPkg:
    if isDarwin system then darwinPkg else linuxPkg;

  # Platform-specific configuration selector
  selectConfig = system: darwinConfig: linuxConfig:
    if isDarwin system then darwinConfig else linuxConfig;

  # Platform-specific path handling
  getHomePath = system: username:
    if isDarwin system then "/Users/${username}" else "/home/${username}";

  # Application directories by platform
  getAppDir = system:
    if isDarwin system then "/Applications/Nix Apps" else "/run/current-system/sw/bin";

  # Shell detection
  getShellPath = system: shell:
    if isDarwin system then "/run/current-system/sw/bin/${shell}" else "/run/current-system/sw/bin/${shell}";

in {
  inherit
    isDarwin
    isNixos
    isAarch64
    isX86_64
    selectPackage
    selectConfig
    getHomePath
    getAppDir
    getShellPath;
}