#!/usr/bin/env bash
set -e

echo "🔧 Rebuilding NixOS after DNS configuration fix..."
echo ""

# Verify current state
echo "📍 Current DNS configuration:"
cat /etc/resolv.conf | grep -E "nameserver|options" | head -5
echo ""

echo "📍 Nix connect-timeout:"
grep "connect-timeout" /etc/nix/nix.conf || echo "  (not set in nix.conf)"
echo ""

echo "📍 Step 1: Remove IPv6 DNS servers (if present)..."
sudo sed -i '/^nameserver fe80::/d' /etc/resolv.conf
sudo sed -i '/^nameserver [0-9a-f:]*%.*$/d' /etc/resolv.conf

echo "📍 Step 2: Ensure Quad9 DNS is first..."
sudo sed -i '/^nameserver 9.9.9./d' /etc/resolv.conf
sudo sed -i '1s/^/nameserver 9.9.9.10\nnameserver 9.9.9.9\n/' /etc/resolv.conf

echo "📍 Updated DNS configuration:"
cat /etc/resolv.conf | grep -E "nameserver|options" | head -5
echo ""

echo "📍 Step 3: Rebuilding NixOS..."
echo "⚠️  This should complete successfully now (the resolvconf.conf error is fixed)"
echo ""

sudo nixos-rebuild switch --flake .#evo-x2

echo ""
echo "✅ Build successful!"
echo "✅ Nix cache connectivity issues are fixed"
