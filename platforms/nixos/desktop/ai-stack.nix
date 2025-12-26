{pkgs, ...}: {
  # AMD ROCm configuration for AI acceleration
  # Note: GPU hardware is configured in ../hardware/amd-gpu.nix
  # Note: AI environment variables moved to Home Manager (user-level)
  # (for Ollama service running as user)

  # Ollama service for AI models
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm; # Use AMD GPU version
    host = "127.0.0.1";
    port = 11434;
    environmentVariables = {
      HIP_VISIBLE_DEVICES = "0";
      ROCM_PATH = "${pkgs.rocmPackages.rocm-runtime}";
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
