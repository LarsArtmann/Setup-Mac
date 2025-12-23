{ pkgs, lib, ... }:

{
  # AMD ROCm configuration for AI acceleration
  # Note: GPU hardware is configured in ../hardware/amd-gpu.nix
  environment.variables = {
    HIP_VISIBLE_DEVICES = "0";
    ROCM_PATH = "${pkgs.rocmPackages.rocm-runtime}";
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # For RDNA3
    PYTORCH_ROCM_ARCH = "gfx1100";  # For Ryzen AI Max+ 395
  };

  # Ollama service for AI models
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;  # Use AMD GPU version
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
    ollama  # Model server
    llama-cpp  # Alternative inference

    # OCR tools
    tesseract  # OCR engine
    tesseract4  # Better OCR
    poppler-utils  # PDF utilities

    # Development tools for AI
    jupyter  # Interactive development
  ];
}
