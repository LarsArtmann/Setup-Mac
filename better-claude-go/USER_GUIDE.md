# Better Claude - User Guide

## Overview

Better Claude is a sophisticated command-line configuration management tool designed to optimize your Claude AI workflow. It provides profile-based configuration management with built-in backup capabilities, validation, and observability through OpenTelemetry instrumentation.

## Features

- **Profile-Based Configuration**: Switch between development, production, and personal settings
- **Automatic Backups**: Create timestamped backups before making changes
- **Configuration Validation**: Ensure settings are applied correctly
- **Dry-Run Mode**: Preview changes without applying them
- **OpenTelemetry Integration**: Built-in observability and tracing
- **Functional Programming**: Built with immutable patterns using samber/lo

## Installation

### Prerequisites

- Go 1.24.4 or higher
- Claude CLI installed and configured
- Bun package manager (for updates)

### Building from Source

```bash
git clone <repository-url>
cd better-claude-go
go build -o better-claude .
```

### Using Pre-built Binary

Download the latest release binary for your platform from the releases page.

## Quick Start

1. **Check available options:**
   ```bash
   ./better-claude --help
   ```

2. **Apply personal configuration (default):**
   ```bash
   ./better-claude configure
   ```

3. **Preview changes with dry-run:**
   ```bash
   ./better-claude --dry-run configure
   ```

4. **Create backup before changes:**
   ```bash
   ./better-claude --backup configure
   ```

## Command Reference

### Global Flags

- `--dry-run`: Preview changes without applying them
- `--backup`: Create backup before applying changes
- `--profile <profile>`: Specify configuration profile (dev/prod/personal)
- `--config <file>`: Use custom config file (default: ~/.claude.yaml)

### Commands

#### configure

Apply configuration for the specified profile.

```bash
# Apply personal profile (default)
./better-claude configure

# Apply development profile
./better-claude configure --profile dev

# Apply with backup and dry-run
./better-claude configure --backup --dry-run --profile prod
```

#### backup

Create a backup of the current Claude configuration.

```bash
# Create backup with default profile name
./better-claude backup

# Create backup for specific profile
./better-claude backup --profile dev
```

#### restore

Restore Claude configuration from a backup file.

```bash
# List available backups
./better-claude restore

# Restore from specific backup
./better-claude restore claude-config-dev-20240713_193218.json

# Preview restore without applying
./better-claude restore --dry-run backup-file.json
```

## Configuration Profiles

### Development Profile (`dev` or `development`)

Optimized for high-performance development work:

- **Theme**: dark-daltonized
- **Parallel Tasks**: 50 (high concurrency)
- **Notification Channel**: iterm2_with_bell
- **Idle Threshold**: 500ms (responsive)
- **Auto Updates**: disabled
- **Diff Tool**: bat
- **Telemetry**: enabled with detailed metrics

**Environment Variables:**
- `EDITOR=nano`
- `CLAUDE_CODE_ENABLE_TELEMETRY=1`
- `OTEL_METRICS_EXPORTER=otlp`
- `OTEL_LOGS_EXPORTER=otlp`
- `OTEL_EXPORTER_OTLP_PROTOCOL=grpc`
- `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317`
- `OTEL_METRIC_EXPORT_INTERVAL=5000`
- `OTEL_LOGS_EXPORT_INTERVAL=2500`

### Production Profile (`prod` or `production`)

Conservative settings for production environments:

- **Theme**: dark-daltonized
- **Parallel Tasks**: 10 (conservative)
- **Notification Channel**: iterm2_with_bell
- **Idle Threshold**: 2000ms (stable)
- **Auto Updates**: disabled
- **Diff Tool**: bat
- **Telemetry**: disabled for privacy

**Environment Variables:**
- `EDITOR=nano`
- `CLAUDE_CODE_ENABLE_TELEMETRY=0`
- `OTEL_METRICS_EXPORTER=none`
- `OTEL_LOGS_EXPORTER=none`

### Personal Profile (`personal` or `default`)

Balanced settings for personal use:

- **Theme**: dark-daltonized
- **Parallel Tasks**: 20 (balanced)
- **Notification Channel**: iterm2_with_bell
- **Idle Threshold**: 1000ms (responsive)
- **Auto Updates**: disabled
- **Diff Tool**: bat
- **Telemetry**: enabled with standard metrics

**Environment Variables:**
- `EDITOR=nano`
- `CLAUDE_CODE_ENABLE_TELEMETRY=1`
- `OTEL_METRICS_EXPORTER=otlp`
- `OTEL_LOGS_EXPORTER=otlp`
- `OTEL_EXPORTER_OTLP_PROTOCOL=grpc`
- `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317`
- `OTEL_METRIC_EXPORT_INTERVAL=10000`
- `OTEL_LOGS_EXPORT_INTERVAL=5000`

## Advanced Usage

### Environment Variables

You can override default settings using environment variables:

```bash
# Use custom OTEL endpoint
export OTEL_EXPORTER_OTLP_ENDPOINT=http://my-collector:4317
./better-claude configure --profile dev

# Disable telemetry temporarily
export CLAUDE_CODE_ENABLE_TELEMETRY=0
./better-claude configure
```

### Configuration File

Create a custom configuration file in YAML format:

```yaml
# ~/.claude.yaml
theme: "dark-daltonized"
parallelTasksCount: "25"
preferredNotifChannel: "desktop"
messageIdleNotifThresholdMs: "750"
autoUpdates: "false"
diffTool: "delta"

env:
  EDITOR: "code"
  CLAUDE_CODE_ENABLE_TELEMETRY: "1"
```

### Backup Management

Backups are created with the format: `claude-config-{profile}-{timestamp}.json`

Example: `claude-config-dev-20240713_193218.json`

To list all backups:
```bash
ls -la ~/claude-config-*.json
```

### Integration with Scripts

Better Claude can be integrated into shell scripts:

```bash
#!/bin/bash

# Apply development configuration
./better-claude configure --profile dev

# Start development work
claude chat --model=claude-3-5-sonnet-20241022

# Switch back to personal configuration
./better-claude configure --profile personal
```

## Troubleshooting

### Common Issues

1. **Command not found**: Ensure the binary is in your PATH or use the full path
2. **Permission denied**: Make sure the binary has execute permissions (`chmod +x better-claude`)
3. **Configuration not applied**: Check that Claude CLI is properly installed and configured
4. **Backup creation fails**: Ensure you have write permissions in your home directory

### Debug Mode

Use the `--dry-run` flag to see what changes would be made:

```bash
./better-claude --dry-run configure --profile dev
```

### Logging

Better Claude uses structured logging. To see detailed logs:

```bash
# Set log level (if supported by your environment)
export LOG_LEVEL=debug
./better-claude configure
```

### OpenTelemetry Issues

If you encounter OTEL-related errors:

1. Ensure your OTEL collector is running (if using telemetry)
2. Check the endpoint configuration
3. Temporarily disable telemetry: `export CLAUDE_CODE_ENABLE_TELEMETRY=0`

## Security Considerations

- Better Claude only modifies Claude CLI configuration files
- Backups are stored locally in your home directory
- No sensitive data is transmitted externally
- OpenTelemetry data is sent to your configured collector only

## Performance Tips

1. **Use appropriate profiles**: Development profile for active coding, production for stable environments
2. **Adjust parallel tasks**: Higher values for more powerful machines
3. **Monitor telemetry**: Use OTEL data to optimize your workflow
4. **Regular backups**: Create backups before major configuration changes

## Contributing

Better Claude follows functional programming principles and uses:

- **Domain-Driven Design** for clear separation of concerns
- **Immutable patterns** with samber/lo for data transformations
- **Interface-based design** for testability
- **OpenTelemetry** for observability

## Support

For issues, feature requests, or contributions, please refer to the project repository.

## Version Information

- **Version**: 2.0.0
- **Go Version**: 1.24.4
- **Architecture**: Modern Go with functional programming patterns
- **Dependencies**: Minimal external dependencies for security and performance