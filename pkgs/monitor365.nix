{
  lib,
  stdenv,
  rustPlatform,
  pkg-config,
  cmake,
  libclang,
  llvmPackages,
  sqlite,
  dbus,
  lm_sensors,
  src,
}:

rustPlatform.buildRustPackage rec {
  pname = "monitor365";
  version = "0.1.0";

  inherit src;

  cargoHash = "";

  nativeBuildInputs = [
    pkg-config
    cmake
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    libclang.lib
    llvmPackages.libcxxClang
    sqlite
  ] ++ lib.optionals stdenv.isLinux [
    dbus
    lm_sensors
  ];

  LIBCLANG_PATH = "${libclang.lib}/lib";

  # Only build the CLI agent binary, not the server
  cargoBuildFlags = ["--package monitor365-cli"];

  # Only test the CLI package and its dependencies (not server, BDD, or plugin e2e)
  cargoTestFlags = ["--package monitor365-cli"];

  meta = with lib; {
    description = "Cross-platform personal device monitoring system (agent)";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "monitor365";
  };
}
