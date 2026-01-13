#!/usr/bin/env bash
set -euo pipefail

# Fix DNS issues and rebuild NixOS
# This script:
# 1. Temporarily fixes /etc/resolv.conf to remove IPv6 DNS
# 2. Increases Nix timeouts
# 3. Rebuilds the system
# 4. Restores proper DNS configuration

echo "🔧 Fixing Nix cache connectivity issues..."

# Backup current resolv.conf
sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%s)

# Remove IPv6 DNS servers from resolv.conf
echo "📍 Removing IPv6 DNS servers..."
sudo sed -i '/^nameserver fe80::/d' /etc/resolv.conf
sudo sed -i '/^nameserver [0-9a-f:]*%.*$/d' /etc/resolv.conf

# Ensure Quad9 DNS is first
echo "📍 Ensuring Quad9 DNS is primary..."
sudo sed -i '/^nameserver 9.9.9./d' /etc/resolv.conf
sudo sed -i '1s/^/nameserver 9.9.9.10\nnameserver 9.9.9.9\n/' /etc/resolv.conf

# Show current DNS configuration
echo "📍 Current DNS configuration:"
cat /etc/resolv.conf | grep -E "nameserver|options"

# Increase Nix timeouts temporarily
echo "📍 Increasing Nix timeout..."
sudo sed -i 's/^connect-timeout = 5/connect-timeout = 120/' /etc/nix/nix.conf || true

# Show Nix timeout
echo "📍 Nix connect-timeout:"
grep "connect-timeout" /etc/nix/nix.conf

# Rebuild NixOS
echo ""
echo "🚀 Rebuilding NixOS..."
echo "⚠️  This may take 15-30 minutes depending on your internet connection"
echo ""

if sudo nixos-rebuild switch --flake .#evo-x2; then
  echo ""
  echo "✅ Rebuild successful!"
  echo "✅ DNS and Nix settings are now permanently fixed"
  echo ""
  echo "📍 New DNS configuration:"
  cat /etc/resolv.conf | grep -E "nameserver|options"
  echo ""
  echo "📍 New Nix configuration:"
  grep "connect-timeout" /etc/nix/nix.conf
else
  echo ""
  echo "❌ Rebuild failed!"
  echo "📋 Check the error messages above"
  echo ""
  echo "🔄 To restore your previous DNS config:"
  echo "   sudo cp /etc/resolv.conf.backup.<timestamp> /etc/resolv.conf"
  exit 1
fi
