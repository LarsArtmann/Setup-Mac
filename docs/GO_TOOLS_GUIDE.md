# Go Development Tools Guide

This guide covers the comprehensive Go development toolchain included in the Setup-Mac configuration. All tools are managed through Nix and can be auto-updated using `gup`.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core Go Tools](#core-go-tools)
- [Auto-Update System](#auto-update-system)
- [Justfile Commands](#justfile-commands)
- [Development Workflow](#development-workflow)
- [Configuration Management](#configuration-management)
- [Troubleshooting](#troubleshooting)

## Overview

The Setup-Mac configuration includes 10 essential Go development tools plus the `gup` auto-updater:

### Core Tools (10 total)
1. **golangci-lint** - Fast linters runner for Go
2. **gofumpt** - Stricter gofmt for code formatting
3. **gopls** - Go language server for IDE integration
4. **gotests** - Generate Go tests automatically
5. **wire** - Compile-time dependency injection
6. **mockgen** - Generate mocks for Go interfaces
7. **protoc-gen-go** - Protocol buffer compiler for Go
8. **buf** - Modern protobuf toolchain
9. **delve** - Go debugger
10. **gup** - Auto-update Go binaries installed via 'go install'

## Installation

### Via Nix (Recommended)
The tools are automatically installed when you rebuild your nix-darwin configuration:

```bash
# Rebuild nix-darwin configuration
just switch
```

### Manual Installation
If you prefer to install tools manually:

```bash
# Install all tools manually
just go-update-tools-manual

# Or install individual tools
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/gopls@latest
# ... etc
```

## Core Go Tools

### 1. golangci-lint
Fast linters runner that runs multiple linters in parallel.

```bash
# Run linters on current directory
just go-lint

# Run linters on specific package
just go-lint ./cmd/...

# Run specific linters only
golangci-lint run --enable=gosec,errcheck
```

**Configuration**: Create `.golangci.yml` in your project root for custom configuration.

### 2. gofumpt
Stricter version of gofmt that enforces additional formatting rules.

```bash
# Format current directory
just go-format

# Format specific files
gofumpt -l -w main.go

# Check formatting without writing
gofumpt -l .
```

### 3. gopls
Go language server that provides IDE features like auto-completion, go-to-definition, etc.

```bash
# Check gopls functionality
just go-check

# Get gopls version
gopls version

# Run gopls check on specific directory
gopls check ./pkg/...
```

**IDE Integration**: Most editors automatically detect and use gopls.

### 4. gotests
Generate Go tests automatically based on function signatures.

```bash
# Generate tests for a package
just go-gen-tests ./pkg/mypackage

# Generate tests for all functions
gotests -all -w ./...

# Generate tests with testify template
gotests -template testify -all -w ./pkg/...
```

### 5. wire
Google's compile-time dependency injection tool for Go.

```bash
# Generate wire code
just go-wire

# Generate wire code for specific directory
wire ./cmd/server/

# Check wire configuration
wire check
```

**Setup**: Create `wire.go` files with provider sets and injectors.

### 6. mockgen
Generate mocks for Go interfaces to use in testing.

```bash
# Generate mock from source file
just go-gen-mocks user.go user_mock.go

# Generate mock from package
mockgen database/sql/driver Conn,Driver

# Generate mock with package mode
mockgen . UserService
```

### 7. protoc-gen-go
Protocol buffer compiler plugin for Go.

```bash
# Generate Go code from protobuf
protoc --go_out=. --go_opt=paths=source_relative user.proto

# Used with buf (recommended)
just go-proto-gen
```

### 8. buf
Modern replacement for protoc with better tooling.

```bash
# Generate protobuf code
just go-proto-gen

# Lint protobuf files
just go-proto-lint

# Format protobuf files
buf format --write

# Build protobuf files
buf build
```

**Configuration**: Create `buf.yaml` and `buf.gen.yaml` files in your project.

### 9. delve
Powerful debugger for Go programs.

```bash
# Debug a binary
just go-debug ./bin/myapp

# Debug tests
just go-debug-test ./pkg/mypackage

# Debug with specific args
dlv exec ./bin/myapp -- --config=dev.yaml

# Attach to running process
dlv attach <pid>
```

**Common Commands in Delve**:
- `break main.main` - Set breakpoint
- `continue` - Continue execution
- `step` - Step into function
- `next` - Step over function
- `print var` - Print variable value

### 10. gup
Auto-updater for Go binaries installed via `go install`.

```bash
# Update all Go binaries
just go-auto-update

# Check which binaries need updates
just go-check-updates

# List all installed binaries
just go-list-binaries
```

## Auto-Update System

The auto-update system uses `gup` to keep all Go development tools current.

### Key Commands

```bash
# Auto-update all Go binaries (recommended)
just go-auto-update

# Check which tools need updates
just go-check-updates

# Export current tool list for reproducible installs
just go-export-config

# Import tools from configuration (useful for new machines)
just go-import-config
```

### Configuration Export/Import

Export your current Go tool configuration:

```bash
just go-export-config
```

This creates a `gup.conf` file at `~/Library/Application Support/gup/gup.conf` that lists all your installed Go binaries.

On a new machine, run:

```bash
just go-import-config
```

This installs all tools listed in the configuration file.

## Justfile Commands

### Development Workflow Commands

```bash
# Complete Go development workflow
just go-dev ./...           # Format, lint, test, build

# Individual steps
just go-format              # Format code with gofumpt
just go-lint                # Run golangci-lint
just go-check               # Run gopls check
```

### Code Generation Commands

```bash
just go-gen-tests package       # Generate tests
just go-gen-mocks src dest      # Generate mocks
just go-wire                    # Generate wire code
just go-proto-gen               # Generate protobuf code
just go-proto-lint              # Lint protobuf files
```

### Debugging Commands

```bash
just go-debug binary            # Debug binary
just go-debug-test package      # Debug tests
```

### Maintenance Commands

```bash
just go-auto-update             # Update all tools
just go-check-updates           # Check for updates
just go-list-binaries           # List installed tools
just go-tools-version           # Show tool versions
just go-setup                   # Complete environment setup
```

### Configuration Commands

```bash
just go-export-config           # Export tool configuration
just go-import-config           # Import tool configuration
just go-update-tools-manual     # Manual tool update
```

## Development Workflow

### Recommended Daily Workflow

1. **Start of day**: Check for updates
   ```bash
   just go-check-updates
   ```

2. **Before committing**: Run full workflow
   ```bash
   just go-dev ./...
   ```

3. **Weekly**: Update all tools
   ```bash
   just go-auto-update
   ```

### Project Setup Workflow

1. **Clone project and setup tools**:
   ```bash
   just go-setup
   ```

2. **Import existing tool configuration** (if available):
   ```bash
   just go-import-config
   ```

3. **Generate initial tests** (for new packages):
   ```bash
   just go-gen-tests ./pkg/mypackage
   ```

### CI/CD Integration

Add these commands to your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Format and Lint Go Code
  run: |
    just go-format
    just go-lint

- name: Run Tests with Coverage
  run: |
    go test -race -coverprofile=coverage.out ./...
```

## Configuration Management

### Tool Configurations

Each tool can be configured via configuration files in your project:

- **golangci-lint**: `.golangci.yml`
- **buf**: `buf.yaml`, `buf.gen.yaml`
- **wire**: `wire.go` files with `//go:build wireinject`

### Environment Variables

Set these in your shell configuration:

```bash
export GOBIN=$HOME/go/bin
export PATH=$PATH:$GOBIN
```

### IDE Integration

Most tools integrate automatically with popular IDEs:

- **VS Code**: Install Go extension, gopls is auto-detected
- **GoLand**: Built-in support for most tools
- **Vim/Neovim**: Use vim-go or coc-go plugins

## Troubleshooting

### Common Issues

#### 1. Tool Not Found
```bash
# Check if tool is in PATH
which golangci-lint

# Reinstall missing tool
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

#### 2. Outdated Tool Version
```bash
# Check current versions
just go-tools-version

# Update all tools
just go-auto-update
```

#### 3. gup Permission Errors
```bash
# Check Go binary permissions
ls -la $GOBIN

# Fix permissions if needed
chmod +x $GOBIN/*
```

#### 4. Wire Generation Fails
```bash
# Check wire configuration
wire check

# Ensure wire.go files have correct build tags
// +build wireinject
```

#### 5. Protobuf Generation Issues
```bash
# Check buf configuration
buf lint

# Verify proto files syntax
buf build
```

### Getting Help

```bash
# Show all available Go commands
just help | grep "go-"

# Get help for specific tools
golangci-lint --help
gofumpt --help
wire --help
dlv help
```

### Tool Documentation

- [golangci-lint](https://golangci-lint.run/)
- [gofumpt](https://github.com/mvdan/gofumpt)
- [gopls](https://pkg.go.dev/golang.org/x/tools/gopls)
- [gotests](https://github.com/cweill/gotests)
- [wire](https://github.com/google/wire)
- [mockgen](https://github.com/uber-go/mock)
- [buf](https://buf.build/)
- [delve](https://github.com/go-delve/delve)
- [gup](https://github.com/nao1215/gup)

## Performance Tips

1. **Use gup for batch updates** instead of updating tools individually
2. **Run golangci-lint with specific linters** for faster feedback during development
3. **Use gopls caching** by keeping your editor/IDE open
4. **Generate tests incrementally** rather than for entire codebase at once
5. **Use buf instead of protoc** for better performance and caching

## Security Considerations

- All tools are installed from official repositories
- gup verifies checksums when updating binaries
- Tools are installed to user-specific directories (`$GOBIN`)
- Regular updates ensure security patches are applied
- Configuration files should not contain sensitive information

---

**Last Updated**: July 2025
**Maintained By**: Setup-Mac Configuration System