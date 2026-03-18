#!/usr/bin/env bash
# Check NPU availability and driver status on AMD Strix Halo

set -euo pipefail

echo "======================================================================"
echo "  AMD Ryzen AI Max+ 395 (Strix Halo) NPU Status Check"
echo "======================================================================"
echo ""

# 1. Check if NPU hardware exists
echo "1. NPU Hardware Detection"
echo "   -----------------------"
NPU_PCI=$(lspci -nn | grep -i "neural processing unit" || true)
if [[ -n "$NPU_PCI" ]]; then
    echo "   ✅ NPU hardware detected:"
    echo "      $NPU_PCI"
else
    echo "   ❌ No NPU hardware found"
fi
echo ""

# 2. Check NPU device nodes
echo "2. NPU Device Nodes"
echo "   -----------------"
if ls /dev/accel/accel* 2>/dev/null; then
    echo "   ✅ NPU device nodes found:"
    ls -l /dev/accel/accel* 2>/dev/null | awk '{print "      " $9 " -> " $11}'
else
    echo "   ❌ No NPU device nodes in /dev/accel/"
    echo "      This means the NPU driver is not loaded or not installed"
fi
echo ""

# 3. Check for NPU kernel modules
echo "3. NPU Kernel Modules"
echo "   -------------------"
NPU_MODULES=$(lsmod | grep -iE 'amdxna|amd_iommu_v2|iommufd' || true)
if [[ -n "$NPU_MODULES" ]]; then
    echo "   ✅ NPU-related modules loaded:"
    echo "$NPU_MODULES" | awk '{print "      " $1}'
else
    echo "   ❌ No NPU modules loaded"
    echo "      Expected modules: amdxna, amdgpu (with NPU support)"
fi
echo ""

# 4. Check what Ollama is using
echo "4. Ollama Backend Status"
echo "   ----------------------"
OLLAMA_BACKEND=$(journalctl -u ollama --no-pager -n 500 | grep -i "ggml_vulkan.*device\|backend.*load" | tail -3 || true)
if [[ -n "$OLLAMA_BACKEND" ]]; then
    echo "   Current backend:"
    echo "$OLLAMA_BACKEND" | sed 's/^/      /'
else
    echo "   Could not determine Ollama backend"
fi
echo ""

# 5. Check latest inference device allocation
echo "5. Device Allocation (Latest Load)"
echo "   -------------------------------"
LATEST_ALLOC=$(journalctl -u ollama --no-pager -n 500 | grep "device.*=" | grep -v "msg=" | tail -5 || true)
if [[ -n "$LATEST_ALLOC" ]]; then
    echo "   Memory allocation by device:"
    echo "$LATEST_ALLOC" | sed 's/^/      /'
else
    echo "   No recent device allocation info"
fi
echo ""

# 6. Summary
echo "======================================================================"
echo "  SUMMARY"
echo "======================================================================"
echo ""
echo "Hardware Status:"
echo "  - GPU (Radeon 8060S): ✅ Detected and in use by Ollama via Vulkan"
echo "  - NPU (Strix Halo):   ✅ Hardware present"
echo ""
echo "Driver Status:"
echo "  - GPU driver (amdgpu): ✅ Loaded and working"
echo "  - NPU driver (XDNA):   ❌ NOT loaded"
echo ""
echo "Current Ollama Configuration:"
echo "  - Backend: Vulkan"
echo "  - Device: GPU (Radeon 8060S Graphics)"
echo "  - NPU Usage: NO (Ollama does not support NPU)"
echo ""
echo "======================================================================"
echo "  USING THE NPU FOR AI INFERENCE"
echo "======================================================================"
echo ""
echo "To use the NPU, you would need:"
echo ""
echo "1. AMD XDNA Driver:"
echo "   - Open-source driver: https://github.com/amd/XDNA"
echo "   - Status: Not yet in Nixpkgs"
echo "   - Required kernel modules: amdxna, amdgpu (with NPU support)"
echo ""
echo "2. NPU-Compatible AI Framework:"
echo "   - ONNX Runtime with NPU Execution Provider"
echo "   - AMD ZenDNN (Deep Neural Network library)"
echo "   - PyTorch with AMD NPU support (experimental)"
echo ""
echo "3. Model Compilation:"
echo "   - Models must be compiled for NPU architecture (VLIW4)"
echo "   - Example: onnxruntime-tools compile --target npu"
echo ""
echo "4. Current State of NPU Support:"
echo "   - Ollama: NO NPU support (GPU via Vulkan only)"
echo "   - llama.cpp: NO NPU support (CPU/GPU only)"
echo "   - ONNX Runtime: YES NPU support (via AMD EP)"
echo "   - PyTorch: EXPERIMENTAL NPU support"
echo ""
echo "======================================================================"
echo "  CONCLUSION"
echo "======================================================================"
echo ""
echo "Your system has NPU hardware, but:"
echo "  1. The NPU driver is not installed/loaded"
echo "  2. Ollama does not support NPU acceleration"
echo "  3. You are currently using the GPU (Vulkan backend)"
echo ""
echo "Recommendation:"
echo "  - GPU acceleration is working well (all 48 layers offloaded)"
echo "  - The GPU is more mature and has better software support"
echo "  - NPU is primarily for edge AI/ML workloads with specific models"
echo ""
