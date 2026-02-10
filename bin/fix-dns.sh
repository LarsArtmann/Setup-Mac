#!/usr/bin/env bash
set -e

echo "🔧 Fixing Nix cache DNS issues..."
echo ""

# Step 1: Backup current config
echo "📍 Step 1: Backup DNS config..."
sudo cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%s)

# Step 2: Remove IPv6 DNS servers
echo "📍 Step 2: Remove IPv6 DNS servers..."
sudo sed -i '/^nameserver fe80::/d' /etc/resolv.conf
sudo sed -i '/^nameserver [0-9a-f:]*%.*$/d' /etc/resolv.conf

# Step 3: Ensure Quad9 DNS is first
echo "📍 Step 3: Set Quad9 as primary DNS..."
sudo sed -i '/^nameserver 9.9.9./d' /etc/resolv.conf
sudo sed -i '1s/^/nameserver 9.9.9.10\nnameserver 9.9.9.9\n/' /etc/resolv.conf

# Step 4: Show new DNS config
echo "📍 New DNS configuration:"
cat /etc/resolv.conf | grep -E "nameserver|options"

# Step 5: Increase Nix timeout
echo ""
echo "📍 Step 4: Increase Nix connect-timeout..."
sudo sed -i 's/^connect-timeout = 5/connect-timeout = 120/' /etc/nix/nix.conf || echo "  (connect-timeout not found in nix.conf)"

# Step 6: Show Nix timeout
echo "📍 Nix connect-timeout:"
grep "connect-timeout" /etc/nix/nix.conf || echo "  (not set in nix.conf)"

# Step 7: Rebuild
echo ""
echo "📍 Step 5: Rebuilding NixOS (this may take 15-30 min)..."
sudo nixos-rebuild switch --flake .#evo-x2

echo ""
echo "✅ Fix complete!"
