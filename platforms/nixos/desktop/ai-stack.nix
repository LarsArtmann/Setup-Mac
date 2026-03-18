{pkgs, ...}: {
  # AMD Strix Halo AI Stack
  # Three inference backends: NPU (FastFlowLM), GPU (vLLM/Vulkan), GPU (Ollama)

  # Ollama - GPU inference via Vulkan backend (simple, good compatibility)
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_PARALLEL = "1";
    };
  };

  # vLLM - high-performance GPU inference (ROCm, for larger models / batch workloads)
  # Note: vLLM on Strix Halo requires custom ROCm build or container.
  # The package is installed here; runtime needs HSA_OVERRIDE_GFX_VERSION=gfx1100
  # and may need containerized toolboxes from kyuz0/amd-strix-halo-toolboxes.

  # FastFlowLM - NPU inference (50 TOPS XDNA2, best power efficiency)
  # Installed as a system package. Requires NPU driver (see hardware/amd-npu.nix).
  # Provides OpenAI-compatible API on port 52625 via `flm serve`.

  environment.systemPackages = with pkgs; [
    # Inference servers
    ollama
    llama-cpp
    vllm

    # OCR
    tesseract4
    poppler-utils

    # AI/ML development
    jupyter
    python313
  ];

  environment.sessionVariables = {
    # vLLM ROCm targeting Strix Halo gfx1100
    HSA_OVERRIDE_GFX_VERSION = "gfx1100";
    ROCBLAS_USE_HIPBLASLT = "1";
  };
}
