{pkgs, ...}: {
  # AMD ROCm configuration for AI acceleration
  # Note: GPU hardware is configured in ../hardware/amd-gpu.nix
  # Note: AI environment variables at service-level (services.ollama.environmentVariables)
  # This is the correct NixOS pattern for service-specific GPU configuration

  # Ollama service for AI models
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm; # Use AMD GPU version
    rocmOverrideGfx = "11.0.0"; # Sets HSA_OVERRIDE_GFX_VERSION automatically
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      # GPU selection
      HIP_VISIBLE_DEVICES = "0";

      # ROCm path
      ROCM_PATH = "${pkgs.rocmPackages.rocm-runtime}";

      # PyTorch-specific GPU architecture
      PYTORCH_ROCM_ARCH = "gfx1100";

      # Performance tuning (optional)
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_NUM_PARALLEL = "10";
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
    python311 # Python for AI/ML development
  ];
}
