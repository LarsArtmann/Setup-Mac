{
  pkgs,
  config,
  ...
}: let
  # llama.cpp with ROCm + rocWMMA for Strix Halo (gfx1151)
  # rocWMMA provides 2x prompt processing via wavefront matrix multiply-accumulate
  # MFMA enables matrix fused multiply-add for quantized matmul kernels
  # Upstream llama.cpp doesn't find_package rocwmma or add its include dirs,
  # so we patch the HIP backend CMakeLists to add target_include_directories
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
in {
  # AMD Strix Halo AI Stack
  # Inference backends: NPU (FastFlowLM), GPU (Ollama/ROCm), CPU (llama-cpp)

  # System-wide memlock for ROCm/HIP large GTT buffer allocations
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

  # Ollama - GPU inference via ROCm backend (hipBLASLt for optimized GEMM)
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

  # FastFlowLM - NPU inference (50 TOPS XDNA2, best power efficiency)
  # Installed as a system package. Requires NPU driver (see hardware/amd-npu.nix).
  # Provides OpenAI-compatible API on port 52625 via `flm serve`.

  environment.systemPackages = with pkgs; [
    # Inference servers
    ollama
    llama-cpp-rocwmma # llama.cpp with ROCm + rocWMMA for Strix Halo

    # OCR
    tesseract4
    poppler-utils

    # AI/ML development
    jupyter
    python313
  ];

  # Unsloth Studio - no-code AI model training & inference web UI
  # Native ROCm GPU acceleration on AMD Strix Halo (gfx1151)
  # Uses Python venv with PyTorch ROCm + unsloth[amd] for direct GPU access
  systemd.services.unsloth-studio = {
    description = "Unsloth Studio - AI Model Training & Inference UI";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    path = with pkgs; [python313 git gcc gnumake cmake ninja cacert rocmPackages.rocm-smi];
    environment = {
      HOME = unslothDataDir;
      PYTHONDONTWRITEBYTECODE = "1";
    };
    preStart = ''
      if [ ! -f ${unslothDataDir}/venv/bin/unsloth ]; then
        ${pkgs.python313}/bin/python -m venv ${unslothDataDir}/venv
        ${unslothDataDir}/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel
        ${unslothDataDir}/venv/bin/pip install --no-cache-dir \
          torch torchvision torchaudio \
          --index-url https://download.pytorch.org/whl/rocm6.3
        ${unslothDataDir}/venv/bin/pip install --no-cache-dir \
          "unsloth[amd] @ git+https://github.com/unslothai/unsloth"
      fi
    '';
    serviceConfig = {
      Type = "simple";
      ExecStart = "${unslothDataDir}/venv/bin/unsloth studio -H 127.0.0.1 -p 8888";
      User = "lars";
      Group = "video";
      WorkingDirectory = "${unslothDataDir}/workspace";
      Restart = "on-failure";
      RestartSec = "10s";
      SupplementaryGroups = ["render"];
      TimeoutStartSec = "900";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${unslothDataDir} 0755 lars users -"
    "d ${unslothDataDir}/workspace 0755 lars users -"
    "d ${unslothDataDir}/models 0755 lars users -"
  ];

  environment.sessionVariables = {
    # ROCm targeting Strix Halo gfx1151 (natively supported on kernel 6.19+)
    # HSA_OVERRIDE_GFX_VERSION removed - gfx1151 is auto-detected
    ROCBLAS_USE_HIPBLASLT = "1";
  };
}
