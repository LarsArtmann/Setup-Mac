{
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.rocmPackages) rocwmma;
  llama-cpp-rocwmma =
    (pkgs.llama-cpp.override {
      rocmSupport = true;
    }).overrideAttrs (finalAttrs: {
      buildInputs =
        finalAttrs.buildInputs
        ++ [rocwmma];
      cmakeFlags =
        finalAttrs.cmakeFlags
        ++ [
          "-DGGML_HIP_ROCWMMA_FATTN=ON"
          "-DGGML_HIP_MMQ_MFMA=ON"
        ];
      postPatch =
        (finalAttrs.postPatch or "")
        + ''
          sed -i '/target_link_libraries(ggml-hip PRIVATE/a\  target_include_directories(ggml-hip SYSTEM PRIVATE ${rocwmma}/include)' \
            ggml/src/ggml-hip/CMakeLists.txt
        '';
    });

  unslothDataDir = "/var/lib/unsloth";
  studioVenvPython = "${unslothDataDir}/.unsloth/studio/unsloth_studio/bin/python";
in {
  # AMD Strix Halo AI Stack
  # Inference backends: NPU (FastFlowLM), GPU (Ollama/ROCm), CPU (llama-cpp)

  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "memlock";
      value = "unlimited";
    }
    {
      domain = "*";
      type = "soft";
      item = "memlock";
      value = "unlimited";
    }
  ];

  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_PARALLEL = "1";
      ROCBLAS_USE_HIPBLASLT = "1";
    };
  };

  environment.systemPackages = with pkgs; [
    ollama
    llama-cpp-rocwmma
    tesseract4
    poppler-utils
    jupyter
    python313
  ];

  # Unsloth Studio - no-code AI model training & inference web UI
  # Native ROCm GPU acceleration on AMD Strix Halo (gfx1151)
  #
  # setup.sh creates an inner venv at $HOME/.unsloth/studio/unsloth_studio/
  # with ~100 pip packages + a Node.js-built frontend. This is inherently
  # impure (PyPI + npm downloads) so it runs as a oneshot service, not a
  # Nix derivation.
  #
  # Three-phase lifecycle:
  #   1. unsloth-setup (oneshot) — creates outer venv + runs setup.sh for inner venv
  #   2. unsloth-studio (simple)  — runs the web UI, gated by ConditionPathExists
  #   3. On first boot, studio is skipped until setup finishes, then systemd
  #      starts it on the next restart or via systemctl restart

  systemd.services.unsloth-setup = {
    description = "Unsloth Studio - First-time setup";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [
      python313 git gcc gnumake cmake ninja cacert bash
      curl nodejs_22 gawk coreutils
    ];
    environment = {
      HOME = unslothDataDir;
      PYTHONDONTWRITEBYTECODE = "1";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "unsloth-setup" ''
        set -euo pipefail

        if [ ! -f ${unslothDataDir}/venv/bin/unsloth ]; then
          echo "Creating Python venv..."
          ${pkgs.python313}/bin/python -m venv ${unslothDataDir}/venv
          ${unslothDataDir}/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel
          echo "Installing PyTorch ROCm 6.3 (~4.9GB)..."
          ${unslothDataDir}/venv/bin/pip install --no-cache-dir \
            torch torchvision torchaudio \
            --index-url https://download.pytorch.org/whl/rocm6.3
          echo "Installing unsloth[amd]..."
          ${unslothDataDir}/venv/bin/pip install --no-cache-dir \
            "unsloth[amd] @ git+https://github.com/unslothai/unsloth"
          echo "CLI install complete."
        else
          echo "Unsloth CLI already installed, skipping."
        fi

        if [ ! -f ${studioVenvPython} ]; then
          echo "Running unsloth studio setup..."
          rm -rf ${unslothDataDir}/.nvm
          HOME=${unslothDataDir} ${unslothDataDir}/venv/bin/unsloth studio setup
          echo "Studio setup complete."
        else
          echo "Studio inner venv already exists, skipping."
        fi
      '';
      User = "lars";
      Group = "users";
      TimeoutStartSec = "3600";
    };
  };

  systemd.services.unsloth-studio = {
    description = "Unsloth Studio - AI Model Training & Inference UI";
    after = ["network.target" "unsloth-setup.service"];
    requires = ["unsloth-setup.service"];
    wants = ["unsloth-setup.service"];
    wantedBy = ["multi-user.target"];
    environment.HOME = unslothDataDir;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${unslothDataDir}/venv/bin/unsloth studio -H 127.0.0.1 -p 8888";
      User = "lars";
      Group = "video";
      WorkingDirectory = "${unslothDataDir}/workspace";
      Restart = "on-failure";
      RestartSec = "10s";
      SupplementaryGroups = ["render"];
      TimeoutStartSec = "60";
      ConditionPathExists = studioVenvPython;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${unslothDataDir} 0755 lars users -"
    "d ${unslothDataDir}/workspace 0755 lars users -"
    "d ${unslothDataDir}/models 0755 lars users -"
  ];

  environment.sessionVariables = {
    ROCBLAS_USE_HIPBLASLT = "1";
  };
}
