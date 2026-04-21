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

  cargoLock = {
    lockFile = src + "/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

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

  # Only build the CLI binary (the agent), not the server
  cargoBuildFlags = ["--package monitor365-cli"];

  # Skip BDD tests (need cucumber runtime) — only run unit tests
  cargoTestFlags = ["--workspace" "--exclude" "monitor365-bdd-tests"];

  meta = with lib; {
    description = "Cross-platform personal device monitoring system (agent)";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "monitor365";
  };
}
