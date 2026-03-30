#!/usr/bin/env bash
set -euo pipefail

echo "=== Step 1: Kill stuck nixos-rebuild processes ==="
sudo pkill -f nixos-rebuild 2>/dev/null || true
sudo pkill -f "systemd-machine-id-setup" 2>/dev/null || true
sleep 1

echo ""
echo "=== Step 2: Remove stale activation locks ==="
sudo rm -f /run/nixos-rebuild-switch.lock /run/nixos-rebuild-test.lock /run/nixos-rebuild-build.lock 2>/dev/null || true

echo ""
echo "=== Step 3: Stop failing services before activation ==="
sudo systemctl stop dnsblockd 2>/dev/null || true
sudo systemctl stop systemd-tmpfiles-resetup 2>/dev/null || true
sudo systemctl stop unbound 2>/dev/null || true
sleep 1

echo ""
echo "=== Step 4: Remove stale secondary IP if present ==="
sudo ip addr del 192.168.1.163/24 dev enp1s0 2>/dev/null || true

echo ""
echo "=== Step 5: Deploy ==="
cd /home/lars/Setup-Mac
nh os switch .

echo ""
echo "=== Step 6: Verify ==="
sleep 3
echo "--- dnsblockd ---"
sudo systemctl status dnsblockd --no-pager || true
echo ""
echo "--- unbound ---"
sudo systemctl status unbound --no-pager || true
echo ""
echo "--- Ping 192.168.1.163 ---"
ping -c 3 -W 2 192.168.1.163 || true
echo ""
echo "--- Failed units ---"
sudo systemctl --failed --no-pager || true
