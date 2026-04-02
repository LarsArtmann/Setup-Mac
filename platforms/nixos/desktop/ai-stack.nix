{pkgs, ...}: let
  # llama.cpp with ROCm + rocWMMA for Strix Halo (gfx1151)
  # rocWMMA provides 2x prompt processing via wavefront matrix multiply-accumulate
  # MFMA enables matrix fused multiply-add for quantized matmul kernels
  llama-cpp-rocwmma =
    (pkgs.llama-cpp.override {
      rocmSupport = true;
    }).overrideAttrs (finalAttrs: {
      cmakeFlags =
        finalAttrs.cmakeFlags
        ++ [
          "-DGGML_HIP_ROCWMMA_FATTN=ON"
          "-DGGML_HIP_MMQ_MFMA=ON"
        ];
    });
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

  environment.sessionVariables = {
    # ROCm targeting Strix Halo gfx1151 (natively supported on kernel 6.19+)
    # HSA_OVERRIDE_GFX_VERSION removed - gfx1151 is auto-detected
    ROCBLAS_USE_HIPBLASLT = "1";
  };
}
