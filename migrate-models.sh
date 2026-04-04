#!/usr/bin/env bash
set -euo pipefail

echo "=== Stopping ollama ==="
systemctl stop ollama

echo "=== Moving /data/ollama to /data/models/ollama ==="
mv /data/ollama /data/models/ollama

echo "=== Fixing ownership ==="
chown -R ollama:ollama /data/models/ollama

echo "=== Updating user symlink ==="
rm -f ~/.ollama/models
ln -s /data/models/ollama/models ~/.ollama/models

echo "=== Removing duplicate GGUFs ==="
rm -f /data/models/llm/google_gemma-4-26B-A4B-it-Q4_K_M.gguf
rm -f /data/models/llm/google_gemma-4-31B-it-Q4_K_M.gguf
rm -f /data/models/llm/google_gemma-4-E2B-it-Q4_K_M.gguf
rm -f /data/models/llm/google_gemma-4-E4B-it-Q4_K_M.gguf

echo "=== Creating symlinks to ollama blobs ==="
ln -s /data/models/ollama/models/blobs/sha256-fa27aa3e591c0584da5250215ca83c175772d89d7fa1c533daa545ee142755c7 /data/models/llm/google_gemma-4-26B-A4B-it-Q4_K_M.gguf
ln -s /data/models/ollama/models/blobs/sha256-ef78230619509d4e7a9ea127cca9af04bad3f28c59d5cb648df0258fced39d54 /data/models/llm/google_gemma-4-31B-it-Q4_K_M.gguf
ln -s /data/models/ollama/models/blobs/sha256-5efe645db4e1909c7a1f4a9608df18e6c14383f5e86777fc49f769f9ba7d5fdf /data/models/llm/google_gemma-4-E2B-it-Q4_K_M.gguf
ln -s /data/models/ollama/models/blobs/sha256-6dfbdb0fff82025ef88a6ff912f91d141f722b5d95f14d61b10f0e08839185c8 /data/models/llm/google_gemma-4-E4B-it-Q4_K_M.gguf

echo "=== Removing broken Qwen symlink ==="
rm -f /data/models/llm/Qwen3.5-4B-UD-Q4_K_XL.gguf

echo "=== Starting ollama ==="
systemctl start ollama

echo "=== Done ==="
ollama list
ls -la /data/models/llm/
