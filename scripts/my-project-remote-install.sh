#!/usr/bin/env bash

set -euo pipefail

# Use SSH for private Go modules
export GOPRIVATE="github.com/larsartmann/*,github.com/LarsArtmann/*"

echo "Installing remote Go tools..."

go install github.com/larsartmann/buildflow/cmd/buildflow@latest
go install github.com/larsartmann/branching-flow/cmd/context-analyzer@latest
go install github.com/LarsArtmann/ast-state-analyzer/cmd/ast-state-analyzer@latest

echo "✅ Installation complete!"

