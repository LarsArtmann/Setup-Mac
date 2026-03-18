#!/usr/bin/env bash
# Simple GPU activity check without making inference requests

set -euo pipefail

echo "=== Current GPU Status ==="
echo ""

# Check if GPU busy file exists
if [[ -f /sys/class/drm/card0/device/gpu_busy_percent ]]; then
    GPU_BUSY=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo "0")
    echo "GPU Utilization: ${GPU_BUSY}%"
else
    echo "GPU Utilization: Not available"
fi

echo ""

# Check GPU clock frequencies
if [[ -f /sys/class/drm/card0/device/gpu_clock_frequency ]]; then
    GPU_FREQ=$(cat /sys/class/drm/card0/device/gpu_clock_frequency 2>/dev/null || echo "0")
    GPU_FREQ_MHZ=$((GPU_FREQ / 1000000))
    echo "GPU Frequency: ${GPU_FREQ_MHZ} MHz"
fi

echo ""

# Check VRAM usage
if [[ -f /sys/class/drm/card0/device/mem_info_vram_total ]]; then
    VRAM_TOTAL=$(cat /sys/class/drm/card0/device/mem_info_vram_total 2>/dev/null || echo "0")
    VRAM_TOTAL_GB=$((VRAM_TOTAL / 1024 / 1024 / 1024))
    echo "VRAM Total: ${VRAM_TOTAL_GB} GB"
fi

if [[ -f /sys/class/drm/card0/device/mem_info_vram_used ]]; then
    VRAM_USED=$(cat /sys/class/drm/card0/device/mem_info_vram_used 2>/dev/null || echo "0")
    VRAM_USED_GB=$((VRAM_USED / 1024 / 1024 / 1024))
    VRAM_PERCENT=$((VRAM_USED * 100 / VRAM_TOTAL))
    echo "VRAM Used: ${VRAM_USED_GB} GB (${VRAM_PERCENT}%)"
fi

echo ""
echo "=== Ollama Device Allocation (Latest) ==="
echo ""

# Show the most recent device allocation
journalctl -u ollama --no-pager -n 200 | grep -E 'device.*=.*Vulkan|device.*=.*CPU|GPULayers=' | tail -20 | sed 's/^/  /'

echo ""
echo "=== Summary ==="
echo ""
echo "To verify GPU usage:"
echo "1. Check that 'device=Vulkan0' appears in Ollama logs"
echo "2. Check GPULayers count (how many layers on GPU)"
echo "3. Look at VRAM usage during inference"
echo ""
echo "Current Ollama device allocation shows:"
echo "  - Vulkan0: GPU device (Radeon 8060S)"
echo "  - CPU: Fallback for remaining layers"
echo ""
