#!/usr/bin/env bash
# Monitor GPU usage during Ollama inference
# Run this while making a request to Ollama to see real-time GPU utilization

set -euo pipefail

echo "=== Real-time Ollama GPU Monitor ==="
echo ""
echo "This monitors GPU utilization while Ollama processes requests."
echo "Make a request to Ollama in another terminal to see activity."
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Function to get current GPU usage
get_gpu_stats() {
    # Get GPU usage from /sys/class/drm (AMD GPU)
    if [[ -d /sys/class/drm/card0/device ]]; then
        local gpu_busy=""
        local vram_used=""
        local vram_total=""

        # Try to read GPU busy percentage
        if [[ -f /sys/class/drm/card0/device/gpu_busy_percent ]]; then
            gpu_busy=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo "N/A")
        fi

        # Try to read VRAM usage from amdgpu_top if available
        if command -v amdgpu_top >/dev/null 2>&1; then
            # Get GPU stats
            local stats=$(amdgpu_top --once 2>/dev/null || echo "")
            if [[ -n "$stats" ]]; then
                # Extract usage from amdgpu_top output
                echo "$stats" | head -20
                return
            fi
        fi

        # Fallback: read VRAM from /proc/meminfo or GPU info
        echo "GPU Busy: ${gpu_busy:-N/A}%"
    fi
}

# Function to get Ollama memory usage
get_ollama_mem() {
    local ollama_pid=$(pgrep -x ollama | head -1 || true)
    if [[ -n "$ollama_pid" ]]; then
        local mem_mb=$(ps -p "$ollama_pid" -o rss= 2>/dev/null || echo "0")
        mem_mb=$((mem_mb / 1024))
        echo "Ollama Memory: ${mem_mb} MB (PID: $ollama_pid)"
    else
        echo "Ollama: Not running"
    fi
}

# Function to get latest Ollama logs
get_ollama_logs() {
    local logs=$(journalctl -u ollama --no-pager -n 1 --since "1 second ago" | grep -v -- "--" | tail -1 || true)
    if [[ -n "$logs" ]]; then
        echo "Last Log: ${logs##* }"
    fi
}

# Main monitoring loop
counter=0
while true; do
    clear
    printf '\033[H'

    echo "=== GPU Monitoring ==="
    echo "Time: $(date '+%H:%M:%S')"
    echo ""

    get_gpu_stats
    echo ""
    get_ollama_mem
    echo ""
    get_ollama_logs
    echo ""

    # Show recent Ollama device usage
    echo "=== Recent Device Activity ==="
    journalctl -u ollama --no-pager -n 30 | grep -iE 'device.*=.*vulkan|GPULayers' | tail -5 | sed 's/^/  /'

    echo ""
    echo "Updates every 1 second. Ctrl+C to stop."

    sleep 1
    counter=$((counter + 1))
done
