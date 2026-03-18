#!/usr/bin/env bash
# Real-time GPU monitoring for Ollama inference
# Shows actual GPU utilization during inference

set -euo pipefail

echo "=== Ollama GPU Usage Monitor ==="
echo ""
echo "This script monitors GPU activity while Ollama runs inference."
echo "Starting amdgpu_top in watch mode (refresh every 1 second)..."
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""

# Check if amdgpu_top is available
if ! command -v amdgpu_top &>/dev/null; then
    echo "ERROR: amdgpu_top not found"
    echo "Install with: nix-shell -p amdgpu_top"
    exit 1
fi

# Start amdgpu_top in continuous mode
# Shows GPU usage, VRAM, and other metrics
exec amdgpu_top --once
