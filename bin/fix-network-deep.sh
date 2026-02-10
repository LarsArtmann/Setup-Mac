#!/usr/bin/env bash
set -e

echo "🔧 DEEP FIX: NetworkManager → dhcpcd migration"
echo "==============================================="
echo ""

# Step 1: Reset /etc/resolv.conf to let resolvconf manage it
echo "📍 Step 1: Reset /etc/resolv.conf to resolvconf management..."
echo ""
echo "   Restoring original /etc/resolv.conf from backup..."
if [ -f /etc/resolv.conf.bak ]; then
  sudo cp /etc/resolv.conf.bak /etc/resolv.conf
  echo "   ✅ Restored from /etc/resolv.conf.bak"
elif [ -f /etc/resolv.conf.backup.* ]; then
  latest_backup=$(ls -t /etc/resolv.conf.backup.* | head -1)
  sudo cp "$latest_backup" /etc/resolv.conf
  echo "   ✅ Restored from $latest_backup"
else
  echo "   ℹ️  No backup found, recreating empty file..."
  sudo rm -f /etc/resolv.conf
fi

# Step 2: Stop NetworkManager to prevent conflicts
echo ""
echo "📍 Step 2: Stop NetworkManager service..."
sudo systemctl stop NetworkManager.service
sudo systemctl disable NetworkManager.service
echo "   ✅ NetworkManager stopped and disabled"

# Step 3: Enable dhcpcd
echo ""
echo "📍 Step 3: Enable dhcpcd service..."
sudo systemctl enable dhcpcd.service
echo "   ✅ dhcpcd enabled"

# Step 4: Show current state
echo ""
echo "📍 Current networking services state:"
echo "   NetworkManager:"
systemctl is-enabled NetworkManager.service || echo "     ❌ Disabled"
echo "   dhcpcd:"
systemctl is-enabled dhcpcd.service || echo "     ❌ Disabled"

# Step 5: Rebuild NixOS
echo ""
echo "📍 Step 4: Rebuilding NixOS with new networking config..."
echo "   This will:"
echo "   - Disable NetworkManager completely"
echo "   - Use dhcpcd for network management"
echo "   - Force Quad9 DNS only (no router DNS)"
echo "   - Disable IPv6 completely"
echo ""
echo "   ⚠️  This will take 15-30 minutes..."
echo ""

if sudo nixos-rebuild switch --flake .#evo-x2; then
  echo ""
  echo "✅ Build successful!"
  echo ""

  # Step 6: Verify DNS configuration
  echo "📍 Step 5: Verifying DNS configuration..."
  echo ""
  echo "   /etc/resolv.conf:"
  cat /etc/resolv.conf | grep -E "nameserver|search|options" || echo "     (empty or no matches)"
  echo ""
  echo "   Network services status:"
  echo "   - dhcpcd:"
  systemctl is-active dhcpcd.service || echo "     ❌ Not running"
  echo "   - network-setup:"
  systemctl is-active network-setup.service || echo "     ❌ Not running"
  echo "   - NetworkManager:"
  systemctl is-active NetworkManager.service 2>&1 || echo "     ✅ Stopped"
  echo ""

  # Step 7: Test DNS resolution
  echo "📍 Step 6: Testing DNS resolution..."
  if host cache.nixos.org > /dev/null 2>&1; then
    echo "   ✅ DNS resolution working"
    echo ""
    echo "🎉 ALL FIXES APPLIED SUCCESSFULLY!"
    echo ""
    echo "Summary of changes:"
    echo "  ✅ NetworkManager disabled"
    echo "  ✅ dhcpcd enabled as network manager"
    echo "  ✅ Quad9 DNS (9.9.9.10, 9.9.9.11) configured"
    echo "  ✅ Router DNS ignored"
    echo "  ✅ IPv6 DNS disabled"
    echo "  ✅ Nix connect-timeout: 120s"
    echo ""
    echo "Nix cache should now work without timeouts!"
  else
    echo "   ❌ DNS resolution FAILED"
    echo ""
    echo "⚠️  Build succeeded but DNS resolution is still broken"
    echo "   Check: systemctl status dhcpcd"
    echo "   Check: journalctl -u dhcpcd -n 50"
  fi
else
  echo ""
  echo "❌ Build failed!"
  echo ""
  echo "📋 Check the error messages above"
  echo ""
  echo "🔄 To restore NetworkManager (if this doesn't work):"
  echo "   sudo systemctl enable NetworkManager"
  echo "   sudo systemctl start NetworkManager"
  exit 1
fi
