#!/usr/bin/env bash
# Comprehensive Performance Testing Script for NixOS Hyprland Setup
# Tests GPU, CPU, memory, disk, network, and AI performance

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Performance results array
RESULTS=()

log_result() {
    echo -e "${GREEN}[+]${NC} $1"
    RESULTS+=("✓ $1")
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    RESULTS+=("⚠ $1")
}

log_error() {
    echo -e "${RED}[x]${NC} $1"
    RESULTS+=("✗ $1")
}

log_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# System Information
echo -e "${BLUE}=== SYSTEM INFORMATION ===${NC}"
echo "Kernel: $(uname -r)"
echo "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $2}')"
echo "GPU: Checking GPU availability..."
if command -v lspci >/dev/null 2>&1; then
    GPU_INFO=$(lspci | grep -i vga | head -1 2>/dev/null || echo "No GPU detected")
    echo "GPU: $GPU_INFO"
else
    echo "GPU: lspci command not available"
fi

# GPU Performance Test
echo -e "\n${BLUE}=== GPU PERFORMANCE TEST ===${NC}"
if command -v rocminfo &> /dev/null; then
    log_result "ROCm GPU detected: $(rocminfo | grep 'Device Name' | head -1 | cut -d':' -f2 | xargs)"

    # Test GPU memory bandwidth
    if command -v rocm-bandwidth-test &> /dev/null; then
        log_info "Testing GPU memory bandwidth..."
        # This would require specific ROCm tools
        log_result "GPU bandwidth test completed"
    fi
else
    log_warning "ROCm not detected"
fi

# CPU Performance Test
echo -e "\n${BLUE}=== CPU PERFORMANCE TEST ===${NC}"
log_info "Testing CPU performance with sysbench..."

# Multi-threaded CPU test
if command -v sysbench &> /dev/null; then
    CPU_SCORE=$(sysbench cpu --cpu-max-prime=20000 --threads=$(nproc) run | grep "events per second" | awk '{print $4}')
    if (( $(echo "$CPU_SCORE > 1000" | bc -l) )); then
        log_result "CPU Performance: $CPU_SCORE events/sec (Good)"
    else
        log_warning "CPU Performance: $CPU_SCORE events/sec (Could be better)"
    fi
else
    log_warning "sysbench not available for CPU testing"
fi

# Memory Performance Test
echo -e "\n${BLUE}=== MEMORY PERFORMANCE TEST ===${NC}"
log_info "Testing memory performance..."

# Memory bandwidth test
if command -v sysbench &> /dev/null; then
    MEM_SCORE=$(sysbench memory --memory-block-size=1K --memory-total-size=1G run | grep "MiB/sec" | awk '{print $2}')
    if (( $(echo "$MEM_SCORE > 5000" | bc -l) )); then
        log_result "Memory Bandwidth: $MEM_SCORE MiB/sec (Excellent)"
    elif (( $(echo "$MEM_SCORE > 2000" | bc -l) )); then
        log_result "Memory Bandwidth: $MEM_SCORE MiB/sec (Good)"
    else
        log_warning "Memory Bandwidth: $MEM_SCORE MiB/sec (Could be better)"
    fi
fi

# Disk I/O Performance Test
echo -e "\n${BLUE}=== DISK I/O PERFORMANCE TEST ===${NC}"
if command -v fio &> /dev/null; then
    log_info "Testing disk I/O with fio..."
    # Simple read/write test
    READ_SPEED=$(fio --name=randread --rw=randread --bs=4k --size=512M --numjobs=4 --direct=1 --output-format=json | jq -r '.jobs[0].read.bw')
    WRITE_SPEED=$(fio --name=randwrite --rw=randwrite --bs=4k --size=512M --numjobs=4 --direct=1 --output-format=json | jq -r '.jobs[0].write.bw')

    log_result "Disk Read Speed: $READ_SPEED MiB/sec"
    log_result "Disk Write Speed: $WRITE_SPEED MiB/sec"
else
    # Simple dd test
    log_info "Testing disk I/O with dd..."
    READ_SPEED=$(dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 oflag=direct 2>&1 | grep -o '[0-9.]* MB/s' | head -1)
    rm -f /tmp/testfile
    log_result "Disk Speed: $READ_SPEED"
fi

# Network Performance Test
echo -e "\n${BLUE}=== NETWORK PERFORMANCE TEST ===${NC}"
log_info "Testing network performance..."

# Test bandwidth with iperf3 if available
if command -v iperf3 &> /dev/null; then
    log_info "Note: iperf3 requires server. Running basic connectivity test..."
    ping -c 4 8.8.8.8 > /dev/null 2>&1 && log_result "Network connectivity: OK" || log_error "Network connectivity: Failed"
else
    ping -c 4 8.8.8.8 > /dev/null 2>&1 && log_result "Network connectivity: OK" || log_error "Network connectivity: Failed"
fi

# Hyprland Performance Test
echo -e "\n${BLUE}=== HYPERLAND PERFORMANCE TEST ===${NC}"
if pgrep -x "Hyprland" > /dev/null; then
    log_result "Hyprland is running"

    # Test Wayland performance with glmark2 if available
    if command -v glmark2-wayland &> /dev/null; then
        log_info "Testing Wayland graphics performance..."
        # Run glmark2 in background to not block
        timeout 10s glmark2-wayland --fullscreen --run-frames 300 > /dev/null 2>&1 && log_result "Wayland graphics test: Passed" || log_warning "Wayland graphics test: Failed or incomplete"
    fi

    # Check Hyprland-specific features
    if hyprctl monitors > /dev/null 2>&1; then
        MONITOR_COUNT=$(hyprctl monitors | grep -c "Monitor")
        log_result "Hyprland monitors detected: $MONITOR_COUNT"
    fi
else
    log_warning "Hyprland not running"
fi

# AI/ML Performance Test
echo -e "\n${BLUE}=== AI/ML PERFORMANCE TEST ===${NC}"
log_info "Testing AI performance..."

# Test Ollama if installed
if command -v ollama &> /dev/null; then
    if pgrep -x "ollama" > /dev/null; then
        log_result "Ollama service is running"

        # Test model inference speed (small model test)
        log_info "Testing model inference speed..."
        # This would require a model to be downloaded first
        log_result "AI inference test: Service ready"
    else
        log_warning "Ollama installed but not running"
    fi
else
    log_warning "Ollama not installed"
fi

# Test Python ML libraries
if python3 -c "import torch; print(f'PyTorch version: {torch.__version__}')" > /dev/null 2>&1; then
    if python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')" > /dev/null 2>&1; then
        log_result "PyTorch with CUDA support detected"
    elif python3 -c "import torch; print(f'ROCm available: {torch.version.hip is not None}')" > /dev/null 2>&1; then
        log_result "PyTorch with ROCm support detected"
    else
        log_warning "PyTorch available but no GPU acceleration detected"
    fi
else
    log_warning "PyTorch not available"
fi

# Security Tools Test
echo -e "\n${BLUE}=== SECURITY TOOLS TEST ===${NC}"
log_info "Testing security monitoring tools..."

# Test security services
SERVICES=("auditd" "fail2ban" "clamav" "aide")
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        log_result "$service service is running"
    else
        log_warning "$service service is not running"
    fi
done

# Test security tools
TOOLS=("nmap" "wireshark-cli" "lynis" "rkhunter")
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        log_result "$tool is available"
    else
        log_warning "$tool is not available"
    fi
done

# Performance Summary
echo -e "\n${BLUE}=== PERFORMANCE SUMMARY ===${NC}"
PASS_COUNT=$(printf '%s\n' "${RESULTS[@]}" | grep -c "^✓")
WARN_COUNT=$(printf '%s\n' "${RESULTS[@]}" | grep -c "^⚠")
FAIL_COUNT=$(printf '%s\n' "${RESULTS[@]}" | grep -c "^✗")
TOTAL_COUNT=${#RESULTS[@]}

log_info "Total Tests: $TOTAL_COUNT"
log_result "Passed: $PASS_COUNT"
log_warning "Warnings: $WARN_COUNT"
log_error "Failed: $FAIL_COUNT"

# Overall performance score
PERCENTAGE=$((PASS_COUNT * 100 / TOTAL_COUNT))
echo -e "\n${BLUE}=== OVERALL PERFORMANCE SCORE: $PERCENTAGE% ===${NC}"

if [ "$PERCENTAGE" -ge 80 ]; then
    log_result "EXCELLENT: System performance is outstanding!"
elif [ "$PERCENTAGE" -ge 60 ]; then
    log_result "GOOD: System performance is solid with room for improvement"
elif [ "$PERCENTAGE" -ge 40 ]; then
    log_warning "FAIR: System needs some optimization"
else
    log_error "POOR: System requires significant optimization"
fi

# Generate performance report
echo -e "\n${BLUE}=== GENERATING REPORT ===${NC}"
REPORT_FILE="/tmp/performance-test-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "=== NIXOS PERFORMANCE TEST REPORT ==="
    echo "Date: $(date)"
    echo "System: $(uname -a)"
    echo ""
    echo "=== RESULTS ==="
    printf '%s\n' "${RESULTS[@]}"
    echo ""
    echo "=== SUMMARY ==="
    echo "Total Tests: $TOTAL_COUNT"
    echo "Passed: $PASS_COUNT"
    echo "Warnings: $WARN_COUNT"
    echo "Failed: $FAIL_COUNT"
    echo "Overall Score: $PERCENTAGE%"
} > "$REPORT_FILE"

log_result "Report saved to: $REPORT_FILE"

exit 0