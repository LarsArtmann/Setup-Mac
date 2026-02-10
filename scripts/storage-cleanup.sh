#!/usr/bin/env bash
# Quick Storage Cleanup Script
# Usage: ./scripts/storage-cleanup.sh

set -euo pipefail

echo "🧹 Storage Cleanup Script"
echo "========================"
echo ""

# Check current disk space
echo "📊 Current Disk Space:"
df -h / | tail -1
echo ""

# Check Nix store size
echo "📦 Nix Store Size:"
du -sh /nix/store 2>/dev/null || echo "  Cannot measure"
echo ""

# Check cache sizes
echo "💾 Cache Sizes:"
echo "  Library/Caches: $(du -sh ~/Library/Caches 2>/dev/null | cut -f1)"
echo "  .cache: $(du -sh ~/.cache 2>/dev/null | cut -f1)"
echo ""

# Cleanup Library caches
echo "🧹 Cleaning Library/Caches..."
rm -rf ~/Library/Caches/gopls 2>/dev/null || true
rm -rf ~/Library/Caches/goimports 2>/dev/null || true
rm -rf ~/Library/Caches/golangci-lint 2>/dev/null || true
rm -rf ~/Library/Caches/Google/Chrome/Default/Cache 2>/dev/null || true
rm -rf ~/Library/Caches/Google/Chrome/Default/Code\ Cache 2>/dev/null || true
rm -rf ~/Library/Caches/JetBrains/*/log 2>/dev/null || true
rm -rf ~/Library/Caches/JetBrains/*/index 2>/dev/null || true
rm -rf ~/Library/Caches/legcord-updater 2>/dev/null || true
rm -rf ~/Library/Caches/bun 2>/dev/null || true
echo "✅ Library/Caches cleaned"
echo ""

# Cleanup Go build cache
echo "🔧 Cleaning Go build cache..."
go clean -cache -testcache -modcache 2>/dev/null || true
rm -rf /private/var/folders/*/go-build* 2>/dev/null || true
echo "✅ Go build cache cleaned"
echo ""

# Cleanup temp files
echo "🗑️ Cleaning temp files..."
rm -rf /tmp/nix-build-* 2>/dev/null || true
rm -rf /tmp/nix-shell-* 2>/dev/null || true
echo "✅ Temp files cleaned"
echo ""

# Final disk space
echo "📊 Final Disk Space:"
df -h / | tail -1
echo ""

# Estimate freed space
echo "💡 Estimated Space Freed: ~6-8GB"
echo ""
echo "⚠️  Note: For Nix store cleanup, run:"
echo "   sudo nix-collect-garbage -d --delete-older-than 3d"
echo "   sudo nix-store --optimize"
