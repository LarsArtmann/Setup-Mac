#!/usr/bin/env bash
set -euo pipefail

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Restarting dnsblockd service..."
sudo systemctl restart dnsblockd

sleep 3

echo "Checking dnsblockd status..."
sudo systemctl status dnsblockd --no-pager || true

echo ""
echo "Pinging 192.168.1.150..."
ping -c 2 -W 2 192.168.1.150
