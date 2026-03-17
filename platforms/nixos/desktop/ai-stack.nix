{pkgs, ...}: {
  # AMD Vulkan configuration for AI acceleration
  # Strix Halo (gfx1100/gfx1101) is not yet supported by ROCm in nixpkgs.
  # Vulkan via RADV works and provides GPU acceleration.
  # Note: GPU hardware is configured in ../hardware/amd-gpu.nix

  # Ollama service for AI models
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      # Performance tuning
      OLLAMA_FLASH_ATTENTION = "1";
      # Keep parallel low: only 62 GiB visible to OS (rest reserved for GPU/NPU),
      # BF16 model alone is 60 GiB. High parallelism = guaranteed OOM.
      OLLAMA_NUM_PARALLEL = "1";
    };
  };

  # AI/ML tools and libraries
  environment.systemPackages = with pkgs; [
    # Model management and serving
    ollama # Model server
    llama-cpp # Alternative inference
    vllm # High-performance inference server

    # OCR tools
    tesseract4 # Better OCR (includes tesseract binary)
    poppler-utils # PDF utilities

    # Development tools for AI
    jupyter # Interactive development
    python313 # Python for AI/ML development (3.11 doc build fails with Sphinx 9.1.0)
  ];
}
