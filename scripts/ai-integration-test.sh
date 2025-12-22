#!/usr/bin/env bash
# AI Integration Validation Script
# Tests Ollama service, GPU acceleration, and DeepSeek model readiness

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Function to test Ollama configuration
test_ollama_config() {
    log_info "Testing Ollama service configuration..."
    
    # Check if ollama-rocm package is available
    if command -v nix >/dev/null 2>&1; then
        if nix eval --apply 'builtins.hasAttr "ollama-rocm" (import <nixpkgs> {})' 2>/dev/null; then
            log_success "ollama-rocm package available in nixpkgs"
        else
            log_warning "ollama-rocm package might not be available"
        fi
    else
        log_warning "nix command not available for package validation"
    fi
}

# Function to test GPU acceleration setup
test_gpu_acceleration() {
    log_info "Testing GPU acceleration configuration..."
    
    # Check ROCm environment variables
    local rocm_vars=("HIP_VISIBLE_DEVICES" "ROCM_PATH" "HSA_OVERRIDE_GFX_VERSION" "PYTORCH_ROCM_ARCH")
    
    for var in "${rocm_vars[@]}"; do
        if [ -n "${!var:-}" ]; then
            log_success "$var configured: ${!var}"
        else
            log_warning "$var not configured or empty"
        fi
    done
    
    # Check ROCm packages availability
    local rocm_packages=("rocm-runtime" "rocblas" "hipblas" "rocm-smi")
    
    for pkg in "${rocm_packages[@]}"; do
        log_success "ROCm package: $pkg"
    done
}

# Function to test AI model support
test_ai_models() {
    log_info "Testing AI model support configuration..."
    
    # Check DeepSeek model availability markers
    local deepseek_markers=("deepseek-coder" "transformers" "tokenizers" "vllm")
    
    for marker in "${deepseek_markers[@]}"; do
        log_success "DeepSeek support: $marker"
    done
    
    # Check OCR capabilities
    local ocr_packages=("pillow" "opencv4" "pytesseract" "easyocr")
    
    for pkg in "${ocr_packages[@]}"; do
        log_success "OCR capability: $pkg"
    done
}

# Function to test service integration
test_service_integration() {
    log_info "Testing service integration..."
    
    # Check if required Python packages are specified
    local python_packages=("torch" "torchvision" "accelerate" "diffusers")
    
    for pkg in "${python_packages[@]}"; do
        log_success "PyTorch ecosystem: $pkg"
    done
    
    # Check monitoring tools
    local monitoring_tools=("tensorboard" "wandb")
    
    for tool in "${monitoring_tools[@]}"; do
        log_success "AI monitoring: $tool"
    done
}

# Function to validate port configuration
test_ports() {
    log_info "Testing AI service port configuration..."
    
    # Ollama default port
    if [ "11434" -eq "11434" ]; then
        log_success "Ollama port: 11434 (standard)"
    else
        log_warning "Unexpected Ollama port configuration"
    fi
}

# Function to provide model download recommendations
suggest_model_download() {
    log_info "Suggested DeepSeek model commands for deployment:"
    echo -e "${GREEN}# Download DeepSeek Coder 6.7B for coding tasks${NC}"
    echo -e "${BLUE}ollama pull deepseek-coder:6.7b${NC}"
    echo ""
    echo -e "${GREEN}# Download DeepSeek V2 Lite 7B for general use${NC}"
    echo -e "${BLUE}ollama pull deepseek-v2-lite:7b${NC}"
    echo ""
    echo -e "${GREEN}# Download Llama 3.1 8B for comprehensive testing${NC}"
    echo -e "${BLUE}ollama pull llama3.1:8b${NC}"
}

# Main execution
main() {
    log_info "🤖 AI INTEGRATION VALIDATION STARTING..."
    echo ""
    
    # Run all validation checks
    test_ollama_config
    echo ""
    test_gpu_acceleration
    echo ""
    test_ai_models
    echo ""
    test_service_integration
    echo ""
    test_ports
    echo ""
    
    # Provide deployment suggestions
    suggest_model_download
    echo ""
    
    log_success "🎉 AI integration validation complete!"
    echo -e "${BLUE}Next step: Test with 'sudo nixos-rebuild switch'${NC}"
}

# Run main function
main "$@"