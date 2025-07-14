# Claude Configuration Tool - Production Deployment Guide

## Overview

This guide provides comprehensive instructions for deploying the Claude Configuration Tool in production environments. It covers system requirements, installation procedures, security considerations, monitoring, and maintenance practices.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Installation Methods](#installation-methods)
4. [Production Configuration](#production-configuration)
5. [Security Hardening](#security-hardening)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Backup and Recovery](#backup-and-recovery)
8. [Maintenance and Updates](#maintenance-and-updates)
9. [Troubleshooting](#troubleshooting)
10. [Performance Optimization](#performance-optimization)

## System Requirements

### Minimum Requirements

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **Operating System** | macOS 10.15+, Linux (Ubuntu 18.04+, CentOS 7+) | Bash 4.0+ required |
| **Memory** | 64MB available RAM | Peak usage ~34MB |
| **Disk Space** | 50MB free space | Includes backups and logs |
| **CPU** | 1 vCPU (any architecture) | <1% CPU usage typical |
| **Network** | Internet access for updates | Optional for operation |

### Required Dependencies

| Tool | Version | Installation |
|------|---------|--------------|
| **bash** | 4.0+ | System default |
| **jq** | 1.6+ | `brew install jq` / `apt install jq` |
| **claude** | Latest | Follow Anthropic instructions |
| **bun** | 1.0+ (optional) | Package updates only |

### Supported Platforms

- ✅ **macOS**: 10.15 (Catalina) through 14.x (Sonoma)
- ✅ **Linux**: Ubuntu 18.04+, CentOS 7+, RHEL 7+, Amazon Linux 2
- ✅ **Docker**: Official containers available
- ❌ **Windows**: Not supported (use WSL2)

## Pre-Deployment Checklist

### Environment Preparation

```bash
# 1. Verify system compatibility
bash --version
uname -a

# 2. Install dependencies
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y jq

# CentOS/RHEL
sudo yum install -y jq

# 3. Install Claude CLI
# Follow official Anthropic documentation

# 4. Verify installations
jq --version
claude --version

# 5. Check permissions
ls -la ~/.claude.json
mkdir -p ~/.claude-backups && chmod 700 ~/.claude-backups
```

### Security Review

```bash
# Verify script integrity
sha256sum claude-conf.sh
# Expected: [provide checksum after release]

# Check permissions
ls -la claude-conf.sh
# Should be: -rwxr-xr-x (755)

# Audit dependencies
which jq claude bun
```

### Network Configuration

```bash
# Test connectivity (if using telemetry)
curl -I http://localhost:4317 || echo "OTEL collector not running (optional)"

# Check Claude API access
claude auth status
```

## Installation Methods

### Method 1: Direct Installation (Recommended)

```bash
# 1. Download script
wget https://raw.githubusercontent.com/[repo]/claude-conf.sh
# OR
curl -O https://raw.githubusercontent.com/[repo]/claude-conf.sh

# 2. Verify and make executable
chmod +x claude-conf.sh

# 3. Test installation
./claude-conf.sh --help

# 4. Run dry-run test
./claude-conf.sh --dry-run --profile prod

# 5. Deploy to production location
sudo cp claude-conf.sh /usr/local/bin/claude-conf
sudo chmod +x /usr/local/bin/claude-conf
```

### Method 2: System Package Installation

```bash
# Create system package (example for .deb)
mkdir -p claude-conf-2.0.0/usr/local/bin
cp claude-conf.sh claude-conf-2.0.0/usr/local/bin/claude-conf
chmod +x claude-conf-2.0.0/usr/local/bin/claude-conf

# Build package
dpkg-deb --build claude-conf-2.0.0

# Install package
sudo dpkg -i claude-conf-2.0.0.deb
```

### Method 3: Docker Deployment

```dockerfile
# Dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    bash \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install bun (optional)
RUN curl -fsSL https://bun.sh/install | bash

# Install Claude CLI
# [Add Claude CLI installation steps]

COPY claude-conf.sh /usr/local/bin/claude-conf
RUN chmod +x /usr/local/bin/claude-conf

# Create non-root user
RUN useradd -m -s /bin/bash claude
USER claude
WORKDIR /home/claude

ENTRYPOINT ["/usr/local/bin/claude-conf"]
```

```bash
# Build and run
docker build -t claude-conf:2.0.0 .
docker run --rm -v ~/.claude.json:/home/claude/.claude.json claude-conf:2.0.0 --help
```

### Method 4: Ansible Deployment

```yaml
# claude-conf-deploy.yml
---
- name: Deploy Claude Configuration Tool
  hosts: all
  become: yes
  tasks:
    - name: Install dependencies
      package:
        name: jq
        state: present

    - name: Copy script
      copy:
        src: claude-conf.sh
        dest: /usr/local/bin/claude-conf
        mode: '0755'
        owner: root
        group: root

    - name: Verify installation
      command: /usr/local/bin/claude-conf --help
      register: help_output

    - name: Display help
      debug:
        msg: "{{ help_output.stdout }}"
```

```bash
# Deploy with Ansible
ansible-playbook -i inventory claude-conf-deploy.yml
```

## Production Configuration

### Profile Selection Strategy

#### Development Environment
```bash
# High-performance settings for active development
./claude-conf.sh --profile dev

# Features:
# - 50 parallel tasks (maximum throughput)
# - 500ms notification threshold (quick feedback)
# - Full telemetry enabled (detailed metrics)
# - Fast OTEL export intervals (5s metrics, 2.5s logs)
```

#### Staging Environment
```bash
# Balanced settings for testing
./claude-conf.sh --profile personal

# Features:
# - 20 parallel tasks (moderate performance)
# - 1000ms notification threshold (balanced)
# - Telemetry enabled (monitoring)
# - Standard OTEL intervals (10s metrics, 5s logs)
```

#### Production Environment
```bash
# Conservative settings for stability
./claude-conf.sh --backup --profile prod

# Features:
# - 10 parallel tasks (stable performance)
# - 2000ms notification threshold (conservative)
# - Telemetry disabled (privacy/performance)
# - No OTEL exports (minimal overhead)
```

### Environment-Specific Configurations

#### High-Load Production

```bash
# Custom high-performance production profile
# Edit claude-conf.sh to add:

"prod-high"|"production-high")
    log_info "Loading high-performance production profile..."
    CLAUDE_CONFIG_VALUES="dark-daltonized 30 iterm2_with_bell 1500 false bat"
    CLAUDE_ENV_SCHEMA='{
        "EDITOR": "nano",
        "CLAUDE_CODE_ENABLE_TELEMETRY": "0"
    }'
    ;;
```

#### Restricted Security Environment

```bash
"prod-secure"|"production-secure")
    log_info "Loading secure production profile..."
    CLAUDE_CONFIG_VALUES="dark-daltonized 5 iterm2_with_bell 3000 false bat"
    CLAUDE_ENV_SCHEMA='{
        "EDITOR": "nano",
        "CLAUDE_CODE_ENABLE_TELEMETRY": "0"
    }'
    ;;
```

### Configuration Management

#### GitOps Workflow

```bash
# 1. Store configurations in Git
git clone https://github.com/company/claude-configs.git
cd claude-configs

# 2. Environment-specific branches
git checkout production
git checkout staging
git checkout development

# 3. Deploy with CI/CD
# .github/workflows/deploy.yml
name: Deploy Claude Config
on:
  push:
    branches: [production]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to production
        run: |
          ./claude-conf.sh --backup --profile prod
```

#### Configuration Validation

```bash
# Pre-deployment validation script
#!/bin/bash
set -euo pipefail

echo "🔍 Validating Claude configuration..."

# Test dry-run
./claude-conf.sh --dry-run --profile prod
if [ $? -ne 0 ]; then
    echo "❌ Dry-run validation failed"
    exit 1
fi

# Validate dependencies
command -v jq >/dev/null || { echo "❌ jq not found"; exit 1; }
command -v claude >/dev/null || { echo "❌ claude not found"; exit 1; }

# Check current config
claude config ls | jq . >/dev/null || { echo "❌ Invalid current config"; exit 1; }

echo "✅ Validation passed"
```

## Security Hardening

### File Permissions

```bash
# Secure script permissions
sudo chown root:root /usr/local/bin/claude-conf
sudo chmod 755 /usr/local/bin/claude-conf

# Secure configuration files
chmod 644 ~/.claude.json
chmod 600 ~/.claude-config-*.json  # Backup files
chmod 700 ~/.claude-backups/       # Backup directory
```

### Network Security

```bash
# Restrict OTEL endpoints to localhost (production)
# Modify CLAUDE_ENV_SCHEMA in production profile:
"OTEL_EXPORTER_OTLP_ENDPOINT": "http://127.0.0.1:4317"

# Or disable completely for air-gapped environments:
"OTEL_METRICS_EXPORTER": "none"
"OTEL_LOGS_EXPORTER": "none"
```

### Access Controls

```bash
# Create dedicated user for Claude operations
sudo useradd -m -s /bin/bash claude-user
sudo usermod -a -G claude-group claude-user

# Restrict file access
sudo chown claude-user:claude-group ~/.claude.json
sudo chmod 640 ~/.claude.json
```

### Audit Logging

```bash
# Enable audit logging wrapper
#!/bin/bash
# /usr/local/bin/claude-conf-audited
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
USER=$(whoami)
COMMAND="$*"

echo "$TIMESTAMP $USER: claude-conf $COMMAND" >> /var/log/claude-conf.log
exec /usr/local/bin/claude-conf "$@"
```

### Security Scanning

```bash
# Regular security checks
#!/bin/bash
# security-check.sh

echo "🔍 Security audit for Claude Configuration Tool"

# Check for unauthorized modifications
EXPECTED_HASH="[sha256-hash]"
CURRENT_HASH=$(sha256sum /usr/local/bin/claude-conf | cut -d' ' -f1)

if [ "$EXPECTED_HASH" != "$CURRENT_HASH" ]; then
    echo "⚠️  WARNING: Script hash mismatch!"
    echo "Expected: $EXPECTED_HASH"
    echo "Current:  $CURRENT_HASH"
fi

# Check permissions
PERMS=$(stat -c "%a" /usr/local/bin/claude-conf)
if [ "$PERMS" != "755" ]; then
    echo "⚠️  WARNING: Incorrect permissions: $PERMS"
fi

# Check for suspicious processes
pgrep -f claude-conf && echo "⚠️  Claude-conf processes running"

echo "✅ Security check complete"
```

## Monitoring and Logging

### Application Monitoring

#### Health Check Endpoint

```bash
#!/bin/bash
# health-check.sh
# Returns 0 if healthy, 1 if unhealthy

set -euo pipefail

# Test basic functionality
timeout 30 ./claude-conf.sh --dry-run --profile prod >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Status: Healthy"
    exit 0
else
    echo "Status: Unhealthy"
    exit 1
fi
```

#### Prometheus Metrics

```bash
# metrics-exporter.sh
#!/bin/bash

METRICS_FILE="/tmp/claude-conf-metrics.txt"

# Execution time metric
START_TIME=$(date +%s.%N)
./claude-conf.sh --dry-run --profile prod >/dev/null 2>&1
END_TIME=$(date +%s.%N)
DURATION=$(echo "$END_TIME - $START_TIME" | bc)

# Memory usage
MEMORY_MB=$(ps -o rss= -p $$ | awk '{print $1/1024}')

# Generate Prometheus metrics
cat > "$METRICS_FILE" << EOF
# HELP claude_conf_execution_seconds Time spent executing claude-conf
# TYPE claude_conf_execution_seconds gauge
claude_conf_execution_seconds $DURATION

# HELP claude_conf_memory_mb Memory usage in MB
# TYPE claude_conf_memory_mb gauge
claude_conf_memory_mb $MEMORY_MB

# HELP claude_conf_last_run_timestamp Last execution timestamp
# TYPE claude_conf_last_run_timestamp gauge
claude_conf_last_run_timestamp $(date +%s)
EOF
```

### Log Management

#### Structured Logging

```bash
# Add to claude-conf.sh for structured logs
log_structured() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%dT%H:%M:%S.%3NZ')

    echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"profile\":\"$CURRENT_PROFILE\"}" >> /var/log/claude-conf.jsonl
}
```

#### Log Rotation

```bash
# /etc/logrotate.d/claude-conf
/var/log/claude-conf.log /var/log/claude-conf.jsonl {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 claude-user claude-group
}
```

#### Centralized Logging

```bash
# Ship logs to ELK stack
filebeat.inputs:
- type: log
  paths:
    - /var/log/claude-conf.jsonl
  json.keys_under_root: true
  json.add_error_key: true
  fields:
    service: claude-conf
    environment: production
```

## Backup and Recovery

### Automated Backup Strategy

#### Daily Backups

```bash
#!/bin/bash
# daily-backup.sh

set -euo pipefail

BACKUP_DIR="/opt/claude-backups"
DATE=$(date '+%Y-%m-%d')
BACKUP_PATH="$BACKUP_DIR/$DATE"

mkdir -p "$BACKUP_PATH"

# Backup current configuration
cp ~/.claude.json "$BACKUP_PATH/claude.json"

# Backup script
cp /usr/local/bin/claude-conf "$BACKUP_PATH/claude-conf.sh"

# Create metadata
cat > "$BACKUP_PATH/metadata.json" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "version": "2.0.0",
    "profile": "production"
}
EOF

# Compress backup
tar -czf "$BACKUP_PATH.tar.gz" -C "$BACKUP_DIR" "$DATE"
rm -rf "$BACKUP_PATH"

# Cleanup old backups (keep 30 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Backup created: $BACKUP_PATH.tar.gz"
```

#### Cron Configuration

```bash
# Add to crontab
# Daily backup at 2 AM
0 2 * * * /opt/scripts/daily-backup.sh >> /var/log/claude-backup.log 2>&1

# Weekly verification at 3 AM Sunday
0 3 * * 0 /opt/scripts/verify-backups.sh >> /var/log/claude-backup.log 2>&1
```

### Disaster Recovery

#### Recovery Procedures

```bash
#!/bin/bash
# disaster-recovery.sh

set -euo pipefail

BACKUP_DIR="/opt/claude-backups"
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.tar.gz | head -1)

echo "🔄 Starting disaster recovery..."
echo "Using backup: $LATEST_BACKUP"

# Extract backup
TEMP_DIR=$(mktemp -d)
tar -xzf "$LATEST_BACKUP" -C "$TEMP_DIR"

# Find extracted directory
BACKUP_CONTENT=$(find "$TEMP_DIR" -maxdepth 1 -type d | tail -1)

# Restore configuration
cp "$BACKUP_CONTENT/claude.json" ~/.claude.json
chmod 644 ~/.claude.json

# Restore script
sudo cp "$BACKUP_CONTENT/claude-conf.sh" /usr/local/bin/claude-conf
sudo chmod 755 /usr/local/bin/claude-conf

# Verify restoration
echo "🧪 Verifying restoration..."
/usr/local/bin/claude-conf --dry-run --profile prod

if [ $? -eq 0 ]; then
    echo "✅ Disaster recovery completed successfully"
else
    echo "❌ Disaster recovery failed - manual intervention required"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"
```

#### Recovery Testing

```bash
#!/bin/bash
# test-recovery.sh

echo "🧪 Testing disaster recovery procedures..."

# Create test environment
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Simulate disaster
cp ~/.claude.json ./original-config.json
echo '{"test": "corrupted"}' > ~/.claude.json

# Run recovery
/opt/scripts/disaster-recovery.sh

# Verify recovery worked
if claude config ls >/dev/null 2>&1; then
    echo "✅ Recovery test passed"
    cp ./original-config.json ~/.claude.json
else
    echo "❌ Recovery test failed"
    cp ./original-config.json ~/.claude.json
    exit 1
fi

# Cleanup
cd / && rm -rf "$TEST_DIR"
```

## Maintenance and Updates

### Update Procedures

#### Script Updates

```bash
#!/bin/bash
# update-claude-conf.sh

set -euo pipefail

CURRENT_VERSION="2.0.0"
SCRIPT_URL="https://raw.githubusercontent.com/[repo]/main/claude-conf.sh"

echo "🔄 Checking for Claude Configuration Tool updates..."

# Download latest version info
LATEST_VERSION=$(curl -s "$SCRIPT_URL" | grep "VERSION:" | cut -d' ' -f3)

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "✅ Already running latest version: $CURRENT_VERSION"
    exit 0
fi

echo "📦 New version available: $LATEST_VERSION"

# Create backup
cp /usr/local/bin/claude-conf "/usr/local/bin/claude-conf.backup.$(date +%Y%m%d)"

# Download new version
curl -o "/tmp/claude-conf.new" "$SCRIPT_URL"

# Verify download
if ! bash -n "/tmp/claude-conf.new"; then
    echo "❌ Downloaded script has syntax errors"
    exit 1
fi

# Test new version
chmod +x "/tmp/claude-conf.new"
if ! "/tmp/claude-conf.new" --help >/dev/null; then
    echo "❌ New script fails basic tests"
    exit 1
fi

# Install new version
sudo mv "/tmp/claude-conf.new" /usr/local/bin/claude-conf
sudo chmod 755 /usr/local/bin/claude-conf

echo "✅ Updated to version $LATEST_VERSION"
```

#### Dependency Updates

```bash
#!/bin/bash
# update-dependencies.sh

echo "📦 Updating Claude Configuration Tool dependencies..."

# Update jq
if command -v brew >/dev/null; then
    brew upgrade jq
elif command -v apt-get >/dev/null; then
    sudo apt-get update && sudo apt-get upgrade -y jq
fi

# Update Claude CLI
if command -v bun >/dev/null; then
    bun update -g @anthropic-ai/claude-code
fi

# Verify updates
echo "✅ Dependency versions:"
jq --version
claude --version
bun --version 2>/dev/null || echo "bun not installed"
```

### Health Monitoring

#### Automated Health Checks

```bash
#!/bin/bash
# health-monitor.sh

set -euo pipefail

HEALTH_LOG="/var/log/claude-conf-health.log"
ALERT_EMAIL="admin@company.com"

log_health() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$HEALTH_LOG"
}

check_health() {
    # Test script execution
    if timeout 60 claude-conf --dry-run --profile prod >/dev/null 2>&1; then
        log_health "HEALTHY: Script execution successful"
        return 0
    else
        log_health "UNHEALTHY: Script execution failed"
        return 1
    fi
}

# Run health check
if ! check_health; then
    echo "❌ Health check failed - sending alert"

    # Send alert email
    mail -s "Claude Configuration Tool Health Alert" "$ALERT_EMAIL" << EOF
The Claude Configuration Tool health check has failed.

Host: $(hostname)
Time: $(date)
Log: tail -20 $HEALTH_LOG

Please investigate immediately.
EOF

    exit 1
fi

echo "✅ Health check passed"
```

#### Performance Monitoring

```bash
#!/bin/bash
# performance-monitor.sh

PERF_LOG="/var/log/claude-conf-performance.log"

# Measure execution time
start_time=$(date +%s.%N)
claude-conf --dry-run --profile prod >/dev/null 2>&1
end_time=$(date +%s.%N)

execution_time=$(echo "$end_time - $start_time" | bc)
memory_usage=$(ps -o rss= -p $$ | awk '{print $1/1024}')

# Log performance metrics
echo "$(date '+%Y-%m-%d %H:%M:%S') execution_time=${execution_time}s memory_usage=${memory_usage}MB" >> "$PERF_LOG"

# Alert if performance degrades
if (( $(echo "$execution_time > 5.0" | bc -l) )); then
    echo "⚠️  Performance alert: Execution time $execution_time seconds exceeds threshold"
fi
```

## Troubleshooting

### Common Issues

#### Issue 1: Permission Denied

**Symptoms:**
```
bash: ./claude-conf.sh: Permission denied
```

**Solutions:**
```bash
# Fix permissions
chmod +x claude-conf.sh

# Check ownership
ls -la claude-conf.sh
sudo chown $USER:$USER claude-conf.sh
```

#### Issue 2: Missing Dependencies

**Symptoms:**
```
jq is required but not installed
claude command is not available
```

**Solutions:**
```bash
# Install jq
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# Install Claude CLI
# Follow Anthropic documentation
npm install -g @anthropic-ai/claude-code
```

#### Issue 3: Configuration Validation Fails

**Symptoms:**
```
❌ theme validation failed: expected 'dark-daltonized', got 'null'
```

**Solutions:**
```bash
# Check current configuration
claude config ls

# Reset configuration
rm ~/.claude.json
claude config reset

# Re-run with backup
./claude-conf.sh --backup --profile prod
```

#### Issue 4: Backup Creation Fails

**Symptoms:**
```
Failed to create backup: Permission denied
```

**Solutions:**
```bash
# Check home directory permissions
ls -la ~/

# Create backup directory
mkdir -p ~/.claude-backups
chmod 700 ~/.claude-backups

# Check available space
df -h ~
```

### Diagnostic Tools

#### System Information Collector

```bash
#!/bin/bash
# collect-diagnostics.sh

echo "🔍 Collecting Claude Configuration Tool diagnostics..."

DIAG_DIR="/tmp/claude-conf-diagnostics-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$DIAG_DIR"

# System information
uname -a > "$DIAG_DIR/system-info.txt"
whoami > "$DIAG_DIR/user-info.txt"
id >> "$DIAG_DIR/user-info.txt"

# Dependency versions
{
    echo "=== Dependency Versions ==="
    bash --version 2>/dev/null || echo "bash: not found"
    jq --version 2>/dev/null || echo "jq: not found"
    claude --version 2>/dev/null || echo "claude: not found"
    bun --version 2>/dev/null || echo "bun: not found"
} > "$DIAG_DIR/dependencies.txt"

# Configuration files
cp ~/.claude.json "$DIAG_DIR/claude-config.json" 2>/dev/null || echo "No config file" > "$DIAG_DIR/claude-config.json"

# Recent logs
tail -100 /var/log/claude-conf.log > "$DIAG_DIR/recent-logs.txt" 2>/dev/null || echo "No logs found" > "$DIAG_DIR/recent-logs.txt"

# File permissions
ls -la ~/.claude* > "$DIAG_DIR/file-permissions.txt" 2>/dev/null || echo "No files found" > "$DIAG_DIR/file-permissions.txt"

# Script location and permissions
which claude-conf > "$DIAG_DIR/script-location.txt" 2>/dev/null || echo "Script not in PATH" > "$DIAG_DIR/script-location.txt"
ls -la $(which claude-conf) >> "$DIAG_DIR/script-location.txt" 2>/dev/null || true

# Test execution
./claude-conf.sh --help > "$DIAG_DIR/help-output.txt" 2>&1 || echo "Help command failed"

# Create archive
tar -czf "${DIAG_DIR}.tar.gz" -C "/tmp" "$(basename "$DIAG_DIR")"
rm -rf "$DIAG_DIR"

echo "✅ Diagnostics collected: ${DIAG_DIR}.tar.gz"
```

#### Performance Profiler

```bash
#!/bin/bash
# profile-performance.sh

echo "🔬 Profiling Claude Configuration Tool performance..."

# Multiple runs for accuracy
RUNS=10
PROFILE_LOG="/tmp/claude-conf-profile.log"

echo "timestamp,run,execution_time,memory_peak" > "$PROFILE_LOG"

for i in $(seq 1 $RUNS); do
    echo "Run $i/$RUNS..."

    # Measure execution time and memory
    /usr/bin/time -l ./claude-conf.sh --dry-run --profile prod 2>/tmp/time-output.txt >/dev/null

    # Parse time output
    real_time=$(grep "real" /tmp/time-output.txt | awk '{print $1}')
    memory_peak=$(grep "maximum resident set size" /tmp/time-output.txt | awk '{print $1}')

    # Log results
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$i,$real_time,$memory_peak" >> "$PROFILE_LOG"

    sleep 1
done

# Calculate statistics
echo "📊 Performance Statistics:"
awk -F',' 'NR>1 {sum+=$3; count++} END {print "Average execution time: " sum/count "s"}' "$PROFILE_LOG"
awk -F',' 'NR>1 {sum+=$4; count++} END {print "Average memory usage: " sum/count/1024/1024 "MB"}' "$PROFILE_LOG"

echo "Full results: $PROFILE_LOG"
```

## Performance Optimization

### Production Tuning

#### System-Level Optimizations

```bash
# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize bash for performance
export BASH_ENV=""
export ENV=""

# Use faster temporary directory
export TMPDIR="/tmp"
```

#### Script Optimizations

```bash
# Use optimized version for production
cp claude-conf-optimized.sh /usr/local/bin/claude-conf

# Or apply manual optimizations:
# 1. Cache command availability checks
# 2. Batch JSON operations
# 3. Reduce subprocess calls
# 4. Optimize I/O operations
```

#### Resource Limits

```bash
# Set resource limits for production
ulimit -t 60    # Max CPU time: 60 seconds
ulimit -v 1048576  # Max virtual memory: 1GB
ulimit -f 10240    # Max file size: 10MB
```

### Monitoring Performance

#### Performance Baselines

| Metric | Target | Alert Threshold |
|--------|--------|----------------|
| Execution Time | <2s | >5s |
| Memory Usage | <50MB | >100MB |
| CPU Usage | <5% | >20% |
| Success Rate | 99%+ | <95% |

#### Continuous Performance Testing

```bash
#!/bin/bash
# continuous-perf-test.sh

PERF_THRESHOLD=3.0  # seconds
MEMORY_THRESHOLD=100  # MB

while true; do
    start_time=$(date +%s.%N)
    claude-conf --dry-run --profile prod >/dev/null 2>&1
    end_time=$(date +%s.%N)

    execution_time=$(echo "$end_time - $start_time" | bc)

    if (( $(echo "$execution_time > $PERF_THRESHOLD" | bc -l) )); then
        echo "⚠️  Performance degradation detected: ${execution_time}s"
        # Alert logic here
    fi

    sleep 300  # Test every 5 minutes
done
```

---

## Support and Maintenance

### Support Channels

1. **Documentation**: Refer to USER_GUIDE.md for detailed usage instructions
2. **Issues**: Report bugs via GitHub issues
3. **Updates**: Monitor release notes for updates
4. **Security**: Report security issues privately

### Maintenance Schedule

| Task | Frequency | Responsibility |
|------|-----------|----------------|
| Health checks | Hourly | Automated |
| Log rotation | Daily | System |
| Backups | Daily | Automated |
| Dependency updates | Weekly | Ops team |
| Security patches | As needed | Security team |
| Performance review | Monthly | Ops team |

### Success Metrics

- **Uptime**: 99.9%+ availability
- **Performance**: <2s average execution time
- **Reliability**: <0.1% failure rate
- **Security**: Zero security incidents

This deployment guide provides comprehensive instructions for production deployment of the Claude Configuration Tool. Follow the procedures carefully and adapt them to your specific environment and requirements.

---

**Note**: This guide assumes standard Unix-like environments. Windows deployments require additional consideration and testing.