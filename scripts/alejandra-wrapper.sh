#!/usr/bin/env bash
# Wrapper script for alejandra that formats the current directory when called without arguments
set -euo pipefail

if [[ $# -eq 0 ]]; then
  # No arguments - format the current directory
  alejandra .
else
  # Forward arguments to alejandra
  alejandra "$@"
fi
