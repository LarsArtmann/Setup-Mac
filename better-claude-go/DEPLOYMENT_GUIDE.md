# Better Claude - Deployment Guide

## Overview

This guide covers the deployment, distribution, and production setup of Better Claude, a configuration management tool for Claude AI. The application is designed for cross-platform deployment with minimal dependencies.

## System Requirements

### Minimum Requirements

- **Operating System**: macOS 10.15+, Linux (Ubuntu 18.04+, CentOS 7+), Windows 10+
- **Memory**: 64MB RAM
- **Storage**: 50MB available space
- **Dependencies**: Claude CLI must be installed and configured

### Recommended Requirements

- **Memory**: 128MB RAM for optimal performance
- **Network**: Internet connection for package updates (if enabled)
- **Shell**: bash, zsh, or compatible shell for optimal experience

## Build Process

### Prerequisites

Ensure you have the following installed:

```bash
# Go 1.24.4 or higher
go version

# Git for version control
git --version

# Optional: UPX for binary compression
upx --version
```

### Building for Production

#### Standard Build

```bash
# Clone repository
git clone <repository-url>
cd better-claude-go

# Build optimized binary
go build -ldflags="-s -w" -o better-claude .

# Verify build
./better-claude --help
```

#### Cross-Platform Builds

```bash
# macOS (Intel)
GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o better-claude-darwin-amd64 .

# macOS (Apple Silicon)
GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o better-claude-darwin-arm64 .

# Linux (x86_64)
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o better-claude-linux-amd64 .

# Linux (ARM64)
GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o better-claude-linux-arm64 .

# Windows (x86_64)
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o better-claude-windows-amd64.exe .
```

#### Optimized Build with Compression

```bash
# Build and compress (requires UPX)
go build -ldflags="-s -w" -o better-claude .
upx --best --lzma better-claude

# Verify compressed binary still works
./better-claude --help
```

### Build Flags Explained

- `-ldflags="-s -w"`: Strip debug information and symbol table
- `-s`: Omit symbol table and debug information
- `-w`: Omit DWARF symbol table

## Distribution Methods

### 1. Direct Binary Distribution

#### Single Binary Approach

```bash
# Create distribution directory
mkdir -p dist/better-claude-v2.0.0

# Copy binary and documentation
cp better-claude dist/better-claude-v2.0.0/
cp USER_GUIDE.md dist/better-claude-v2.0.0/
cp README.md dist/better-claude-v2.0.0/
cp LICENSE dist/better-claude-v2.0.0/

# Create installation script
cat > dist/better-claude-v2.0.0/install.sh << 'EOF'
#!/bin/bash
set -e

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="better-claude"

echo "Installing Better Claude..."

# Check if running as root for system-wide install
if [[ $EUID -ne 0 ]] && [[ "$1" != "--user" ]]; then
    echo "Run with sudo for system-wide install, or use --user for user install"
    exit 1
fi

if [[ "$1" == "--user" ]]; then
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
fi

# Copy binary
cp "$BINARY_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

# Add to PATH if user install
if [[ "$1" == "--user" ]]; then
    echo "Binary installed to $INSTALL_DIR"
    echo "Ensure $INSTALL_DIR is in your PATH"
else
    echo "Binary installed to $INSTALL_DIR"
fi

echo "Installation complete! Run '$BINARY_NAME --help' to get started."
EOF

chmod +x dist/better-claude-v2.0.0/install.sh

# Create archive
cd dist
tar -czf better-claude-v2.0.0.tar.gz better-claude-v2.0.0/
```

#### Package Creation

```bash
# Create DEB package structure
mkdir -p dist/deb/better-claude_2.0.0/DEBIAN
mkdir -p dist/deb/better-claude_2.0.0/usr/local/bin
mkdir -p dist/deb/better-claude_2.0.0/usr/share/doc/better-claude

# Copy files
cp better-claude dist/deb/better-claude_2.0.0/usr/local/bin/
cp USER_GUIDE.md README.md dist/deb/better-claude_2.0.0/usr/share/doc/better-claude/

# Create control file
cat > dist/deb/better-claude_2.0.0/DEBIAN/control << EOF
Package: better-claude
Version: 2.0.0
Section: utils
Priority: optional
Architecture: amd64
Maintainer: Better Claude Team
Description: Configuration management tool for Claude AI
 Better Claude provides profile-based configuration management
 for Claude AI with backup capabilities and observability.
EOF

# Build DEB package
dpkg-deb --build dist/deb/better-claude_2.0.0
```

### 2. Container Distribution

#### Dockerfile

```dockerfile
# Build stage
FROM golang:1.24.4-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o better-claude .

# Runtime stage
FROM alpine:3.18

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from build stage
COPY --from=builder /app/better-claude .

# Create non-root user
RUN adduser -D -s /bin/sh claude

USER claude
WORKDIR /home/claude

ENTRYPOINT ["/root/better-claude"]
```

#### Docker Build and Distribution

```bash
# Build container
docker build -t better-claude:2.0.0 .

# Tag for distribution
docker tag better-claude:2.0.0 your-registry/better-claude:2.0.0
docker tag better-claude:2.0.0 your-registry/better-claude:latest

# Push to registry
docker push your-registry/better-claude:2.0.0
docker push your-registry/better-claude:latest
```

### 3. Package Manager Distribution

#### Homebrew Formula

```ruby
# Formula/better-claude.rb
class BetterClaude < Formula
  desc "Configuration management tool for Claude AI"
  homepage "https://github.com/your-org/better-claude-go"
  url "https://github.com/your-org/better-claude-go/archive/v2.0.0.tar.gz"
  sha256 "YOUR_SHA256_HERE"
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "-o", bin/"better-claude"
  end

  test do
    assert_match "Better Claude", shell_output("#{bin}/better-claude --help")
  end
end
```

## Production Deployment

### Environment Setup

#### System Service (Linux)

```bash
# Create systemd service file
sudo tee /etc/systemd/system/better-claude-daemon.service << EOF
[Unit]
Description=Better Claude Configuration Daemon
After=network.target

[Service]
Type=oneshot
User=claude
Group=claude
ExecStart=/usr/local/bin/better-claude configure --profile production
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl enable better-claude-daemon
sudo systemctl start better-claude-daemon
```

#### Cron-based Configuration Management

```bash
# Add to crontab for regular configuration updates
crontab -e

# Add line to check configuration daily at 2 AM
0 2 * * * /usr/local/bin/better-claude configure --profile production --backup
```

### Configuration Management

#### Production Configuration File

```yaml
# /etc/better-claude/config.yaml
theme: "dark-daltonized"
parallelTasksCount: "10"
preferredNotifChannel: "none"
messageIdleNotifThresholdMs: "2000"
autoUpdates: "false"
diffTool: "diff"

env:
  EDITOR: "nano"
  CLAUDE_CODE_ENABLE_TELEMETRY: "0"
  OTEL_METRICS_EXPORTER: "none"
  OTEL_LOGS_EXPORTER: "none"
```

#### Environment Variables

```bash
# Production environment variables
export BETTER_CLAUDE_CONFIG="/etc/better-claude/config.yaml"
export BETTER_CLAUDE_PROFILE="production"
export CLAUDE_CODE_ENABLE_TELEMETRY="0"
```

### Monitoring and Observability

#### OpenTelemetry Configuration

```yaml
# otel-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  logging:
    loglevel: debug
  prometheus:
    endpoint: "0.0.0.0:8889"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
```

#### Health Check Script

```bash
#!/bin/bash
# health-check.sh

BINARY="/usr/local/bin/better-claude"
LOG_FILE="/var/log/better-claude.log"

# Check if binary exists and is executable
if [[ ! -x "$BINARY" ]]; then
    echo "ERROR: Binary not found or not executable: $BINARY"
    exit 1
fi

# Check if binary responds to --help
if ! "$BINARY" --help > /dev/null 2>&1; then
    echo "ERROR: Binary failed health check"
    exit 1
fi

# Check configuration validity
if ! "$BINARY" --dry-run configure > /dev/null 2>&1; then
    echo "WARNING: Configuration validation failed"
    exit 2
fi

echo "OK: Better Claude is healthy"
exit 0
```

## Security Considerations

### Binary Security

1. **Code Signing**: Sign binaries for distribution
   ```bash
   # macOS code signing
   codesign -s "Developer ID Application: Your Name" better-claude

   # Verify signature
   codesign -v better-claude
   ```

2. **Checksum Verification**: Provide checksums for integrity
   ```bash
   # Generate checksums
   sha256sum better-claude-* > checksums.txt

   # GPG sign checksums
   gpg --armor --detach-sign checksums.txt
   ```

### Runtime Security

1. **Principle of Least Privilege**: Run with minimal permissions
2. **File System Permissions**: Restrict access to configuration files
3. **Network Security**: Use HTTPS for any external communications

### Security Hardening

```bash
# Set secure file permissions
chmod 755 /usr/local/bin/better-claude
chmod 644 /etc/better-claude/config.yaml

# Create dedicated user
useradd -r -s /bin/false claude

# Use SELinux policies (if applicable)
setsebool -P allow_claude_exec on
```

## Performance Optimization

### Binary Optimization

1. **Profile-Guided Optimization**:
   ```bash
   # Build with PGO (if profiles available)
   go build -pgo=auto -ldflags="-s -w" -o better-claude .
   ```

2. **Memory Management**:
   - Use `GOGC` environment variable to tune garbage collection
   - Monitor memory usage in production

### Deployment Optimization

1. **CDN Distribution**: Use CDN for binary distribution
2. **Regional Mirrors**: Provide regional download mirrors
3. **Incremental Updates**: Consider delta updates for large deployments

## Troubleshooting Deployment Issues

### Common Issues

1. **Permission Denied**:
   ```bash
   # Fix permissions
   chmod +x better-claude
   chown $USER:$USER better-claude
   ```

2. **Missing Dependencies**:
   ```bash
   # Check dependencies
   ldd better-claude  # Linux
   otool -L better-claude  # macOS
   ```

3. **Configuration Issues**:
   ```bash
   # Validate configuration
   ./better-claude --dry-run configure
   ```

### Debug Information

Enable detailed logging for troubleshooting:

```bash
# Enable debug logging
export BETTER_CLAUDE_LOG_LEVEL=debug
./better-claude configure
```

## Rollback Procedures

### Version Rollback

```bash
# Keep previous version
mv /usr/local/bin/better-claude /usr/local/bin/better-claude.bak
cp better-claude-previous /usr/local/bin/better-claude

# Test rollback
better-claude --help
```

### Configuration Rollback

```bash
# Use built-in restore functionality
better-claude restore previous-backup.json

# Or manual restoration
cp ~/.claude.json.backup ~/.claude.json
```

## Maintenance

### Update Procedures

1. **Automated Updates** (if enabled):
   ```bash
   # Update binary
   curl -L https://releases.example.com/better-claude/latest -o better-claude-new
   chmod +x better-claude-new
   mv better-claude better-claude-old
   mv better-claude-new better-claude
   ```

2. **Configuration Migration**:
   - Test new version with existing configuration
   - Backup before applying updates
   - Validate after updates

### Monitoring

Set up monitoring for:
- Binary health and responsiveness
- Configuration drift
- Backup creation success
- Performance metrics (if telemetry enabled)

## Support and Maintenance

### Log Analysis

```bash
# Check application logs
journalctl -u better-claude-daemon

# Monitor real-time logs
tail -f /var/log/better-claude.log
```

### Performance Monitoring

Use OpenTelemetry metrics to monitor:
- Command execution time
- Configuration apply success rate
- Error rates and types
- Resource usage patterns

This deployment guide ensures robust, secure, and maintainable deployment of Better Claude across various environments and platforms.