# Claude Configuration Tool - User Guide

## Overview

The Claude Configuration Tool (`claude-conf.sh`) is a comprehensive script designed to manage Claude AI settings across different environments with profile-based configuration, automatic backups, and intelligent updates.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Configuration Profiles](#configuration-profiles)
4. [Command Reference](#command-reference)
5. [Advanced Usage](#advanced-usage)
6. [Backup and Restore](#backup-and-restore)
7. [Environment Variables](#environment-variables)
8. [Troubleshooting](#troubleshooting)
9. [Performance](#performance)
10. [Security](#security)

## Quick Start

### Basic Usage

```bash
# Apply personal configuration (default)
./claude-conf.sh

# Apply development profile
./claude-conf.sh --profile dev

# Preview changes without applying them
./claude-conf.sh --dry-run --profile prod

# Create backup before applying changes
./claude-conf.sh --backup --profile personal
```

### 5-Minute Setup

1. **Prerequisites Check:**
   ```bash
   # Ensure required tools are installed
   command -v jq && echo "✓ jq installed" || echo "❌ Install jq first"
   command -v claude && echo "✓ claude installed" || echo "❌ Install claude first"
   command -v bun && echo "✓ bun installed" || echo "❌ Install bun first"
   ```

2. **Make Script Executable:**
   ```bash
   chmod +x claude-conf.sh
   ```

3. **Test Configuration:**
   ```bash
   ./claude-conf.sh --dry-run --profile personal
   ```

4. **Apply Configuration:**
   ```bash
   ./claude-conf.sh --backup --profile personal
   ```

## Installation

### Prerequisites

- **jq**: JSON processor for configuration management
- **claude**: Claude AI command-line interface
- **bun**: JavaScript runtime (optional, for package updates)

### macOS Installation

```bash
# Using Homebrew
brew install jq

# Install Claude CLI (follow official instructions)
# Install bun
curl -fsSL https://bun.sh/install | bash
```

### Linux Installation

```bash
# Ubuntu/Debian
sudo apt-get install jq

# CentOS/RHEL
sudo yum install jq

# Install Claude CLI and bun (follow official instructions)
```

### Script Installation

```bash
# Download and make executable
chmod +x claude-conf.sh

# Verify installation
./claude-conf.sh --help
```

## Configuration Profiles

The tool supports three pre-configured profiles optimized for different use cases:

### Personal Profile (Default)
**Best for**: Individual users, balanced performance
```bash
./claude-conf.sh --profile personal
```

**Settings:**
- Parallel Tasks: 20
- Notification Threshold: 1000ms
- Theme: dark-daltonized
- Telemetry: Enabled
- OTEL Export Interval: 10000ms

### Development Profile
**Best for**: Active development, faster feedback
```bash
./claude-conf.sh --profile dev
```

**Settings:**
- Parallel Tasks: 50 (high performance)
- Notification Threshold: 500ms (quick feedback)
- Theme: dark-daltonized
- Telemetry: Enabled with verbose logging
- OTEL Export Interval: 5000ms (faster metrics)

### Production Profile
**Best for**: Stable production environments
```bash
./claude-conf.sh --profile prod
```

**Settings:**
- Parallel Tasks: 10 (conservative)
- Notification Threshold: 2000ms (stable)
- Theme: dark-daltonized
- Telemetry: Disabled (privacy)
- OTEL Export: Disabled

### Custom Profiles

To create custom profiles, modify the `config_service_load_profile()` function:

```bash
"custom"|"mycustom")
    log_info "Loading custom profile..."
    CLAUDE_CONFIG_VALUES="dark-daltonized 30 iterm2_with_bell 800 false bat"
    CLAUDE_ENV_SCHEMA='{
        "EDITOR": "vim",
        "CLAUDE_CODE_ENABLE_TELEMETRY": "1"
    }'
    ;;
```

## Command Reference

### Basic Commands

| Command | Description | Example |
|---------|-------------|---------|
| `--help` | Show help message | `./claude-conf.sh --help` |
| `--dry-run` | Preview changes without applying | `./claude-conf.sh --dry-run` |
| `--backup` | Create backup before changes | `./claude-conf.sh --backup` |
| `--profile PROFILE` | Use specific profile | `./claude-conf.sh --profile dev` |

### Command Combinations

```bash
# Safe production deployment
./claude-conf.sh --backup --profile prod

# Test development settings
./claude-conf.sh --dry-run --profile dev

# Quick personal setup with backup
./claude-conf.sh --backup --profile personal

# Preview custom profile changes
CLAUDE_PROFILE=custom ./claude-conf.sh --dry-run
```

### Exit Codes

- `0`: Success - configuration applied successfully
- `1`: Error - invalid profile, missing dependencies, or configuration failure

## Advanced Usage

### Environment Variables

Control script behavior using environment variables:

```bash
# Set default profile
export CLAUDE_PROFILE=dev
./claude-conf.sh  # Uses dev profile

# Override with command line
export CLAUDE_PROFILE=dev
./claude-conf.sh --profile prod  # Uses prod profile (overrides env var)
```

### Integration with Just

Add to your `justfile`:

```bash
# Configure Claude with development profile
claude-dev:
    ./claude-conf.sh --profile dev

# Safe production configuration
claude-prod:
    ./claude-conf.sh --backup --profile prod

# Test configuration changes
claude-test profile="personal":
    ./claude-conf.sh --dry-run --profile {{profile}}
```

### Automation

```bash
#!/bin/bash
# Automated deployment script

set -euo pipefail

# Test configuration first
./claude-conf.sh --dry-run --profile prod
if [ $? -eq 0 ]; then
    echo "✓ Configuration test passed"
    # Apply with backup
    ./claude-conf.sh --backup --profile prod
    echo "✓ Production configuration deployed"
else
    echo "❌ Configuration test failed"
    exit 1
fi
```

## Backup and Restore

### Automatic Backups

The `--backup` flag creates timestamped backups:

```bash
./claude-conf.sh --backup --profile dev
# Creates: ~/.claude-config-dev-20240114_143022.json
```

### Backup Naming Convention

- Format: `claude-config-{profile}-{timestamp}.json`
- Location: `$HOME/.claude-config-*.json`
- Timestamp: `YYYYMMDD_HHMMSS`

### Manual Backup

```bash
# Create manual backup
cp ~/.claude.json ~/.claude-config-manual-$(date +%Y%m%d_%H%M%S).json
```

### Restore Process

```bash
# List available backups
ls -la ~/.claude-config-*.json

# Restore specific backup
cp ~/.claude-config-dev-20240114_143022.json ~/.claude.json

# Verify restoration
claude config ls
```

### Backup Best Practices

1. **Always backup before production changes**
2. **Test restored configurations with --dry-run**
3. **Keep multiple backup generations**
4. **Document backup reasons and contexts**

## Environment Variables

### Claude Configuration Variables

The script configures these environment variables based on the selected profile:

| Variable | Personal | Development | Production |
|----------|----------|-------------|------------|
| `EDITOR` | nano | nano | nano |
| `CLAUDE_CODE_ENABLE_TELEMETRY` | 1 | 1 | 0 |
| `OTEL_METRICS_EXPORTER` | otlp | otlp | none |
| `OTEL_LOGS_EXPORTER` | otlp | otlp | none |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | grpc | grpc | - |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | localhost:4317 | localhost:4317 | - |
| `OTEL_METRIC_EXPORT_INTERVAL` | 10000 | 5000 | - |
| `OTEL_LOGS_EXPORT_INTERVAL` | 5000 | 2500 | - |

### Script Control Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `CLAUDE_PROFILE` | Default profile | `export CLAUDE_PROFILE=dev` |

## Troubleshooting

### Common Issues

#### 1. "jq is required but not installed"

**Solution:**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Verify installation
jq --version
```

#### 2. "claude command is not available"

**Solution:**
```bash
# Check if claude is in PATH
which claude

# If not found, install Claude CLI
# Follow official Anthropic installation instructions

# Verify installation
claude --version
```

#### 3. Configuration validation fails

**Symptoms:**
```
❌ theme validation failed: expected 'dark-daltonized', got 'null'
```

**Solution:**
```bash
# Check current configuration
claude config ls

# Reset configuration and retry
./claude-conf.sh --backup --profile personal

# If issue persists, check file permissions
ls -la ~/.claude.json
chmod 644 ~/.claude.json
```

#### 4. Environment variables not persisting

**Symptoms:**
```
⚠️  Note: Environment variables may not persist due to claude config limitations
```

**Solution:**
This is expected behavior. Environment variables are set but may not persist across sessions due to Claude CLI limitations. The script applies them correctly during execution.

#### 5. Backup creation fails

**Symptoms:**
```
❌ Failed to create backup
```

**Solution:**
```bash
# Check home directory permissions
ls -la ~/

# Check existing claude.json
ls -la ~/.claude.json

# Create directory if needed
mkdir -p ~/.claude-backups

# Manual backup test
cp ~/.claude.json ~/.test-backup.json
```

### Debug Mode

Enable verbose debugging:

```bash
# Run with bash debug mode
bash -x ./claude-conf.sh --dry-run --profile dev

# Check specific functions
set -x
./claude-conf.sh --help
set +x
```

### Performance Issues

#### Slow execution

**Check:**
```bash
# Time the execution
time ./claude-conf.sh --dry-run --profile personal

# Use optimized version
time ./claude-conf-optimized.sh --dry-run --profile personal
```

**Optimization tips:**
- Use the optimized script version
- Ensure jq is recent version
- Check available system resources

#### Memory usage

```bash
# Monitor memory usage
/usr/bin/time -l ./claude-conf.sh --dry-run --profile personal
```

### Log Analysis

#### Check recent executions

```bash
# Look for script execution in system logs
grep claude-conf /var/log/system.log

# Check shell history
history | grep claude-conf
```

## Performance

### Benchmarks

| Metric | Original Script | Optimized Script | Improvement |
|--------|----------------|------------------|-------------|
| Execution Time | 1.50s | 1.07s | 29% faster |
| Peak Memory | 34MB | 30MB | 12% reduction |
| Subprocess Calls | ~15 | ~6 | 60% reduction |
| JSON Processing | Multiple jq calls | Batched operations | Significant |

### Performance Features

#### Original Script
- Individual configuration setting updates
- Separate jq calls for each value
- Multiple command availability checks
- Sequential validation

#### Optimized Script (`claude-conf-optimized.sh`)
- Batch configuration updates
- Consolidated JSON processing
- Cached command availability
- Single-pass validation

### Usage Recommendations

#### For Development
Use optimized script for faster feedback loops:
```bash
alias claude-dev='./claude-conf-optimized.sh --profile dev'
```

#### For Production
Use either version - both are production-ready:
```bash
# Standard version (more tested)
./claude-conf.sh --backup --profile prod

# Optimized version (faster)
./claude-conf-optimized.sh --backup --profile prod
```

#### For CI/CD
Optimized version recommended for faster build times:
```bash
./claude-conf-optimized.sh --profile prod
```

## Security

### Security Features

1. **Input Validation**
   - Profile names validated against allowed values
   - Command-line arguments sanitized
   - File paths properly quoted

2. **Safe Operations**
   - No dangerous file operations (rm, etc.)
   - No network downloads (curl, wget)
   - No privilege escalation (sudo)
   - Proper error handling with `set -euo pipefail`

3. **Backup Protection**
   - Automatic backups before changes
   - Timestamped backup files
   - Profile-aware backup naming

### Security Best Practices

#### File Permissions

```bash
# Secure script permissions
chmod 755 claude-conf.sh

# Secure configuration files
chmod 644 ~/.claude.json
chmod 600 ~/.claude-config-*.json  # Backup files
```

#### Environment Security

```bash
# Use specific profiles instead of custom modifications
./claude-conf.sh --profile prod

# Validate configurations
./claude-conf.sh --dry-run --profile prod
```

#### Backup Security

```bash
# Regular backup cleanup
find ~ -name ".claude-config-*.json" -mtime +30 -delete

# Secure backup storage
mkdir -p ~/.claude-backups
chmod 700 ~/.claude-backups
```

### Security Audit Results

- ✅ **No dangerous commands**: No rm, sudo, curl, wget usage
- ✅ **Input validation**: Profile names and arguments validated
- ✅ **Safe execution**: Proper quoting and escaping
- ✅ **Error handling**: Strict error handling enabled
- ⚠️  **eval usage**: Used safely in sandboxed context (line 254)

## FAQ

### Q: Which profile should I use?

**A:** 
- **Personal**: Individual use, balanced settings
- **Development**: Active coding, need fast feedback
- **Production**: Stable environment, conservative settings

### Q: Can I modify profiles?

**A:** Yes, edit the `config_service_load_profile()` function to customize profiles or add new ones.

### Q: How often should I backup?

**A:** 
- Always backup before production changes
- Consider daily backups for active development
- Keep at least 3-5 recent backups

### Q: Is the optimized script safe to use?

**A:** Yes, the optimized script maintains all safety features while improving performance by 29%.

### Q: What if claude config set fails?

**A:** The script includes validation and will report any failures. Use `--dry-run` to test first.

### Q: Can I use this in automation?

**A:** Yes, the script is designed for automation. Use exit codes to check success, and `--dry-run` for testing.

### Q: How do I contribute improvements?

**A:** 
1. Test your changes with all profiles
2. Ensure backward compatibility
3. Update documentation
4. Verify security implications

## Support

### Getting Help

1. **Built-in help**: `./claude-conf.sh --help`
2. **Dry-run testing**: `./claude-conf.sh --dry-run --profile PROFILE`
3. **Debug mode**: `bash -x ./claude-conf.sh ARGS`

### Reporting Issues

When reporting issues, include:
- Operating system and version
- Script version and modifications
- Complete error messages
- Steps to reproduce

### Version Information

Check script version and features:
```bash
head -10 claude-conf.sh | grep -E "Version|Description"
```

---

**Note**: This guide covers both the original and optimized versions of the Claude Configuration Tool. Both versions provide the same functionality with the optimized version offering improved performance.