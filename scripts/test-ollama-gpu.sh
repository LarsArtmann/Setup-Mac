#!/usr/bin/env bash
# Test Ollama GPU usage by running inference and monitoring GPU activity

set -euo pipefail

echo "=== Ollama GPU Usage Test ==="
echo ""
echo "This script will:"
echo "1. Make a request to Ollama"
echo "2. Monitor GPU activity during inference"
echo "3. Show device allocation from logs"
echo ""

# Check if Ollama is running
if ! systemctl is-active --quiet ollama; then
    echo "ERROR: Ollama is not running"
    echo "Start with: sudo systemctl start ollama"
    exit 1
fi

# Get available models
echo "Fetching available models..."
MODELS=$(curl -s http://127.0.0.1:11434/api/tags 2>/dev/null | jq -r '.models[].name' 2>/dev/null || true)

if [[ -z "$MODELS" ]]; then
    echo "ERROR: No models available or Ollama not responding"
    exit 1
fi

echo "Available models:"
echo "$MODELS" | head -5
echo ""

# Select a model (default to first one)
MODEL=$(echo "$MODELS" | head -1)
echo "Using model: $MODEL"
echo ""

# Capture logs before inference
echo "Checking current Ollama device usage..."
journalctl -u ollama --no-pager -n 20 | grep -iE 'device.*=.*vulkan|GPULayers' | tail -3 || echo "No recent device activity"
echo ""

# Make a test request
echo "Making test inference request..."
echo ""

# Start monitoring in background
monitor_pid=""
monitor_log="/tmp/ollama-test-monitor.log"

(
    for i in {1..30}; do
        timestamp=$(date '+%H:%M:%S')
        # Check GPU activity
        if [[ -f /sys/class/drm/card0/device/gpu_busy_percent ]]; then
            gpu_busy=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo "0")
            echo "[$timestamp] GPU Busy: $gpu_busy%" >> "$monitor_log"
        fi
        
        # Check Ollama process memory
        ollama_pid=$(pgrep -x ollama | head -1 || true)
        if [[ -n "$ollama_pid" ]]; then
            mem_kb=$(ps -p "$ollama_pid" -o rss= 2>/dev/null || echo "0")
            mem_mb=$((mem_kb / 1024))
            echo "[$timestamp] Ollama Memory: ${mem_mb} MB" >> "$monitor_log"
        fi
        
        sleep 0.5
    done
) &
monitor_pid=$!

# Make the request
REQUEST_START=$(date +%s)

# Use Python to make the request (more reliable than curl)
python3 << 'PYEOF'
import requests
import json
import sys

try:
    response = requests.post(
        'http://127.0.0.1:11434/api/generate',
        json={
            'model': 'glm-4.7-flash-q8-fixed:latest',
            'prompt': 'Explain quantum computing in one paragraph.',
            'stream': False
        },
        timeout=60
    )
    
    if response.status_code == 200:
        result = response.json()
        tokens = result.get('eval_count', 0)
        duration = result.get('total_duration', 0) / 1e9
        print(f"✅ Inference completed successfully")
        print(f"   Tokens generated: {tokens}")
        print(f"   Duration: {duration:.2f}s")
        if duration > 0:
            tps = tokens / duration
            print(f"   Tokens/sec: {tps:.2f}")
    else:
        print(f"❌ Request failed: {response.status_code}")
        sys.exit(1)
        
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
PYEOF

REQUEST_END=$(date +%s)
REQUEST_DURATION=$((REQUEST_END - REQUEST_START))

# Wait for monitor to finish
wait $monitor_pid 2>/dev/null || true

echo ""
echo "=== Test Results ==="
echo "Request duration: ${REQUEST_DURATION}s"
echo ""

# Show monitor output
echo "GPU Activity During Inference:"
echo "-------------------------------"
if [[ -f "$monitor_log" ]]; then
    cat "$monitor_log" | grep "GPU Busy" || echo "No GPU data collected"
    echo ""
    echo "Memory Usage:"
    cat "$monitor_log" | grep "Ollama Memory" || echo "No memory data collected"
    rm -f "$monitor_log"
else
    echo "No monitoring data collected"
fi

echo ""
echo "=== Device Allocation From Logs ==="
echo "Showing device memory allocation for this inference..."
sleep 2  # Give time for logs to be written
journalctl -u ollama --no-pager --since "2 minutes ago" | grep -iE 'device.*=.*vulkan|GPULayers|model weights|kv cache' | tail -15 | sed 's/^/  /'

echo ""
echo "=== Analysis ==="
echo ""
echo "If you see GPU activity above 0%, Ollama is using GPU acceleration."
echo "All 48 model layers should be allocated to Vulkan0 (GPU)."
echo ""
echo "Expected behavior:"
echo "  - GPU Busy: Should spike during inference (10-80%)"
echo "  - Model weights: ~30GB on Vulkan0"
echo "  - KV cache: ~20GB on Vulkan0"
echo "  - All 48 layers: Offloaded to GPU"
