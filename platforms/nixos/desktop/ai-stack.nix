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
  # Note: Official image is CUDA-only (cu12.8). GPU training requires NVIDIA.
  # On AMD Strix Halo: chat, data recipes, dataset creation, and model export work on CPU.
  # For GPU inference, use host Ollama (localhost:11434) with exported GGUF models.
  # Track ROCm image: https://github.com/unslothai/unsloth/issues (no official ROCm image yet)
  virtualisation.oci-containers.containers.unsloth-studio = {
    autoStart = true;
    image = "unsloth/unsloth:latest";
    ports = ["127.0.0.1:8888:8888"];
    environmentFiles = ["${unslothDataDir}/unsloth.env"];
    volumes = [
      "${unslothDataDir}/workspace:/workspace/work"
      "${unslothDataDir}/models:/root/.cache/huggingface"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${unslothDataDir} 0755 root root -"
    "d ${unslothDataDir}/workspace 0755 root root -"
    "d ${unslothDataDir}/models 0755 root root -"
  ];

  environment.sessionVariables = {
    # ROCm targeting Strix Halo gfx1151 (natively supported on kernel 6.19+)
    # HSA_OVERRIDE_GFX_VERSION removed - gfx1151 is auto-detected
    ROCBLAS_USE_HIPBLASLT = "1";
  };
}
