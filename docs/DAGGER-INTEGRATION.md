# Dagger.io Integration for SystemNix

**Status**: ✅ Complete
**Date**: 2026-04-05
**Scope**: CI/CD automation for Nix flake validation and Go package builds

---

## Overview

This document describes the integration of [Dagger](https://dagger.io/) into SystemNix - a programmable CI/CD engine that runs pipelines as code in containers.

### Why Dagger?

- **Type Safety**: Full IDE support with Go (instead of YAML)
- **Local Testing**: Run CI pipelines locally before pushing
- **Automatic Caching**: BuildKit-powered caching for fast builds
- **Portability**: Same code runs locally and in any CI environment
- **Reproducibility**: Container-based execution ensures consistent results

---

## What Was Implemented

### 1. Dagger Module Configuration

**File**: `dagger.json`
```json
{
  "name": "systemnix",
  "sdk": "go",
  "source": "dagger",
  "engineVersion": "v0.18.5"
}
```

### 2. Dagger Go Module

**Directory**: `dagger/`

| File | Purpose |
|------|---------|
| `main.go` | Dagger functions for CI/CD pipelines |
| `go.mod` | Go module dependencies |
| `README.md` | Documentation for Dagger integration |

### 3. Dagger Functions Implemented

#### NixConfig Functions
- `Check()` - Run `nix flake check --no-build`
- `Deadnix()` - Run deadnix linter
- `Statix()` - Run statix linter
- `BuildDarwin()` - Test Darwin configuration (dry-run)
- `BuildNixos()` - Test NixOS configuration (dry-run)
- `Ci()` - Run full CI pipeline (all checks in parallel)

#### GoPackage Functions
- `Lint()` - Run golangci-lint on Go code
- `Test()` - Run Go tests
- `Build()` - Build Go binary

#### Systemnix Module Functions
- `DnsblockdBuild()` - Build dnsblockd binary
- `DnsblockdProcessorBuild()` - Build dnsblockd-processor binary
- `ModernizeBuild()` - Build modernize Go tool

### 4. Package Integration

**File**: `platforms/common/packages/base.nix`

Added dagger from NUR:
```nix
# Dagger - programmable CI/CD engine (from NUR)
nur.repos.dagger.dagger
```

### 5. Justfile Commands

**File**: `justfile`

Added 15+ new commands:

| Command | Description |
|---------|-------------|
| `just dagger-init` | Initialize Dagger module |
| `just dagger-ci` | Run full CI pipeline |
| `just dagger-check` | Run nix flake check |
| `just dagger-go-lint [pkg]` | Lint Go code |
| `just dagger-go-build [pkg]` | Build Go binary |
| `just dagger-go-test [pkg]` | Run Go tests |
| `just dagger-deadnix` | Run deadnix linter |
| `just dagger-statix` | Run statix linter |
| `just dagger-build-darwin` | Test Darwin build |
| `just dagger-build-nixos` | Test NixOS build |
| `just dagger-functions` | List Dagger functions |
| `just dagger-shell` | Open interactive shell |
| `just dagger-clean` | Clean Dagger caches |
| `just dagger-help` | Show help |

---

## Quick Start

### Installation

Dagger is installed automatically via `just switch`:

```bash
just switch
```

### Initialize Dagger

Generate the Go SDK from the module:

```bash
just dagger-init
```

### Run CI Locally

Test your changes before pushing:

```bash
# Full CI pipeline
just dagger-ci

# Individual checks
just dagger-check      # nix flake check
just dagger-deadnix    # deadnix linter
just dagger-statix     # statix linter
```

### Build Go Packages

```bash
# Lint
just dagger-go-lint dnsblockd
just dagger-go-lint dnsblockd-processor

# Build
just dagger-go-build dnsblockd

# Test
just dagger-go-test dnsblockd
```

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Dagger Engine                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  NixConfig  │  │  GoPackage  │  │   Checks    │         │
│  │  Functions  │  │  Functions  │  │   (CI/CD)   │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                  │
│         └────────────────┴────────────────┘                  │
│                          │                                  │
│                   ┌──────┴──────┐                          │
│                   │   BuildKit    │                          │
│                   │   (Docker)    │                          │
│                   └───────────────┘                          │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
           ┌──────────────┐    ┌──────────────┐
           │  Nix Tests   │    │  Go Builds   │
           │  (Container) │    │  (Container) │
           └──────────────┘    └──────────────┘
```

### Execution Flow

1. **Dagger CLI** parses `dagger.json` and loads the Go module
2. **Go SDK** generates types from function signatures
3. **GraphQL API** communicates with the Dagger Engine
4. **BuildKit** executes container operations with caching
5. **Results** are returned to the CLI

---

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/dagger.yml`:

```yaml
name: Dagger CI
on: [push, pull_request]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@v4
      - name: Run Dagger CI
        run: nix run github:dagger/dagger-for-github -- call nix --source=. ci
```

### Local Development Workflow

```bash
# Before committing
just dagger-ci

# Test specific changes
just dagger-check      # Validate Nix syntax
just dagger-go-lint    # Lint Go code
just dagger-go-test    # Run Go tests
```

---

## Use Cases

### 1. Pre-commit Validation

Run full CI before pushing:

```bash
just dagger-ci
```

### 2. Cross-platform Testing

Test Darwin builds on Linux (dry-run):

```bash
just dagger-build-darwin
```

### 3. Go Package CI

Automated lint, test, build for dnsblockd:

```bash
just dagger-go-lint dnsblockd
just dagger-go-test dnsblockd
just dagger-go-build dnsblockd
```

### 4. Nix Validation

Parallel execution of multiple linters:

```bash
just dagger-ci  # Runs deadnix, statix, and flake check in parallel
```

---

## Troubleshooting

### "dagger: command not found"

```bash
just switch  # Install dagger from NUR
```

### "failed to solve" errors

```bash
just dagger-clean  # Clean Dagger caches
```

### SDK not found

```bash
just dagger-init  # Regenerate Go SDK
```

### Container errors

Ensure Docker/Podman is running:

```bash
docker info  # or podman info
```

---

## Benefits for SystemNix

| Benefit | Description |
|---------|-------------|
| **Reproducibility** | Same CI runs locally and in CI environment |
| **Fast Feedback** | Test changes before pushing |
| **Caching** | Automatic caching of build artifacts |
| **Type Safety** | Go-based instead of YAML |
| **Cross-platform** | Test Darwin on Linux machines |
| **Parallelism** | Run checks in parallel automatically |

---

## Future Enhancements

Potential future improvements:

1. **Integration Tests** - Test NixOS services in containers
2. **Build Cache** - Share build cache between runs
3. **Multi-platform Builds** - Build for ARM64 and x86_64
4. **Release Automation** - Automated releases with Dagger
5. **Documentation** - Auto-generate docs from Dagger functions

---

## References

- [Dagger Documentation](https://docs.dagger.io/)
- [Dagger Go SDK](https://docs.dagger.io/getting-started/sdk/)
- [Daggerverse](https://daggerverse.dev/) - Module registry
- [NUR Dagger Package](https://github.com/nix-community/nur-combined/tree/master/repos/dagger)

---

## Files Modified

```
justfile                              # Added dagger commands
platforms/common/packages/base.nix     # Added dagger package
dagger.json                           # Dagger module config
dagger/main.go                        # Dagger functions
dagger/go.mod                        # Go dependencies
dagger/README.md                      # Dagger documentation
docs/DAGGER-INTEGRATION.md           # This document
```

---

**Summary**: Dagger integration provides a modern, programmable CI/CD solution for SystemNix that runs locally and in CI environments, with automatic caching and type-safe pipelines written in Go.
