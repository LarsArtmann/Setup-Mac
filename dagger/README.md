# SystemNix Dagger Module

This directory contains the Dagger Go module for SystemNix CI/CD pipelines.

## Files

- `main.go` - Dagger functions for Nix and Go CI/CD
- `go.mod` - Go module dependencies (auto-generated)

## Usage

See the main project documentation at `docs/DAGGER-INTEGRATION.md`.

## Quick Commands

```bash
# Initialize Dagger module
dagger develop

# Run CI pipeline
dagger call nix --source=. ci

# List functions
dagger functions
```

## Architecture

The module provides three main types:

1. **Systemnix** - Root module with factory functions
2. **NixConfig** - Nix flake validation functions
3. **GoPackage** - Go build/test/lint functions

## Development

When modifying `main.go`, run `dagger develop` to regenerate the SDK.
