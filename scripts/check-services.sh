#!/usr/bin/env bash
set -euo pipefail

echo "=== Service Status ==="
for svc in prometheus grafana homepage-dashboard prometheus-node-exporter prometheus-postgres-exporter prometheus-redis-exporter caddy dnsblockd unbound postgresql immich-server immich-machine-learning gitea ollama docker; do
  status=$(sudo systemctl is-active "$svc" 2>/dev/null || echo "unknown")
  printf "%-40s %s\n" "$svc" "$status"
done

echo ""
echo "=== Listening Ports ==="
sudo ss -tlnp 2>/dev/null | grep -E '(9091|3001|8082|9100|9187|9121|2019|80|443|2283|3000|53|9090|6379|11434)' || true

echo ""
echo "=== DNS Resolution ==="
for domain in home.lan grafana.lan gitea.lan immich.lan; do
  ip=$(host "$domain" 127.0.0.1 2>/dev/null | grep 'has address' | awk '{print $NF}' || echo "FAIL")
  printf "%-20s %s\n" "$domain" "$ip"
done

echo ""
echo "=== HTTP Health ==="
for url in "http://localhost:8082" "http://localhost:3001" "http://localhost:9091/-/healthy" "http://localhost:9100/metrics" "http://localhost:3000" "http://localhost:9090/health" "http://localhost:2019/config/"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url" 2>/dev/null || echo "000")
  printf "%-50s %s\n" "$url" "$code"
done

echo ""
echo "=== Failed Units ==="
sudo systemctl --failed --no-pager 2>/dev/null || true
