{pkgs}: let
  inherit (pkgs) lib python3Packages fetchFromGitHub;
  inherit (python3Packages) buildPythonApplication;
in
  buildPythonApplication rec {
    pname = "aw-watcher-utilization";
    version = "1.2.2";

    src = fetchFromGitHub {
      owner = "Alwinator";
      repo = "aw-watcher-utilization";
      tag = "v${version}";
      hash = "sha256-QStroCcMmwwb4c9zZKjQeJeqkF8sUojcyWEb+IsuBUw=";
    };

    pyproject = true;
    build-system = [ python3Packages.poetry-core ];

    dependencies = with python3Packages; [
      aw-client
      psutil
    ];

    pythonImportsCheck = [ "aw_watcher_utilization" ];

    meta = with lib; {
      description = "Monitors CPU, RAM, disk, network, and sensor usage for ActivityWatch";
      homepage = "https://github.com/Alwinator/aw-watcher-utilization";
      license = licenses.mpl20;
      platforms = platforms.all;
      mainProgram = "aw-watcher-utilization";
    };
  }
