#!/usr/bin/env bash
set -euo pipefail

echo "=== Deploying NixOS config to evo-x2 ==="
nh os switch . 2>&1

echo ""
echo "=== Waiting 5s for services to settle ==="
sleep 5

echo ""
echo "=== dnsblockd status ==="
sudo systemctl status dnsblockd --no-pager || true

echo ""
echo "=== Ping 192.168.1.150 ==="
ping -c 2 -W 2 192.168.1.150 || true

echo ""
echo "=== IP addresses on enp1s0 ==="
ip addr show enp1s0 | grep "inet " || true

echo ""
echo "=== Failed units ==="
sudo systemctl --failed --no-pager || true
