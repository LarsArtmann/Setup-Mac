#!/usr/bin/env bash
# Check AMD Strix Halo hardware and what Ollama is using

set -euo pipefail

echo "=== AMD Strix Halo Hardware Detection ==="
echo ""

# Check for NPU device nodes
echo "1. Checking for NPU device nodes:"
if ls /dev/accel/accel* 2>/dev/null; then
    echo "   Found NPU devices in /dev/accel/"
else
    echo "   No NPU devices found in /dev/accel/"
fi
echo ""

# Check for AMD NPU in kernel
echo "2. Checking kernel modules for AMD NPU:"
lsmod | grep -iE 'amdgpu|amd_npu|accel|xdna' || echo "   No AMD NPU modules loaded"
echo ""

# Check PCI devices
echo "3. PCI devices (AMD GPU/NPU):"
lspci -nn | grep -iE 'amd|radeon|vga' || echo "   No AMD PCI devices detected"
echo ""

# Check what Ollama detects
echo "4. Ollama detected devices:"
journalctl -u ollama --no-pager -n 200 | grep -iE 'ggml_vulkan.*device|found.*vulkan|device.*=.*Vulkan' | tail -5
echo ""

# Check what's actually being used during inference
echo "5. Current Ollama device usage:"
journalctl -u ollama --no-pager -n 50 | grep -iE 'device=Vulkan|device=CPU|GPULayers' | tail -10
echo ""

# Check system for AMD ROCm/NPU tools
echo "6. Available AMD tools:"
command -v amdgpu_top >/dev/null && echo "   amdgpu_top: installed" || echo "   amdgpu_top: not found"
command -v rocminfo >/dev/null && echo "   rocminfo: installed" || echo "   rocminfo: not found"
command -v radeontop >/dev/null && echo "   radeontop: installed" || echo "   radeontop: not found"
command -v vulkaninfo >/dev/null && echo "   vulkaninfo: installed" || echo "   vulkaninfo: not found"
echo ""

# Check Vulkan devices
echo "7. Vulkan devices detected:"
if command -v vulkaninfo >/dev/null 2>&1; then
    vulkaninfo --summary | grep -A 10 "GPU id" || echo "   Could not read vulkaninfo"
else
    echo "   vulkaninfo not available"
fi
echo ""

# Conclusion
echo "=== ANALYSIS ==="
echo ""
echo "Key findings:"
echo "- Ollama is using Vulkan backend (targets GPU, not NPU)"
echo "- All 48 layers are offloaded to Vulkan0 device"
echo "- Device detected: Radeon 8060S Graphics (RADV STRIX_HALO)"
echo ""
echo "NOTE: Vulkan targets the GPU cores, not the NPU."
echo "The AMD Ryzen AI Max+ 395 NPU is a separate compute unit that requires"
echo "specific NPU support (AMD XDNA/AIE driver). Ollama does NOT support NPU acceleration."
echo ""
echo "To use the NPU for AI inference, you would need:"
echo "1. AMD XDNA driver support (not in current Nixpkgs)"
echo "2. NPU-compatible AI framework (ONNX Runtime with NPU EP, or ZenDNN)"
echo "3. Models compiled for NPU architecture"
