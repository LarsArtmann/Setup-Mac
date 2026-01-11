#!/usr/bin/env bash
# Network & DNS Diagnostic Script for NixOS evo-x2
# Run this on the NixOS machine to diagnose DNS issues

set -e

echo "╔══════════════════════════════════════════════════════╗"
echo "║  NIXOS DNS & NETWORK DIAGNOSTIC TOOL                    ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
    fi
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "1. SYSTEM FILE DESCRIPTOR LIMITS"
echo "═══════════════════════════════════════════════════════"
ulimit -n && check "Current ulimit limit"
cat /proc/sys/fs/file-max 2>/dev/null && check "System max FD limit"
cat /proc/sys/fs/file-nr 2>/dev/null && check "Current FD usage"
echo ""

echo "2. RESOLVER CONFIGURATION"
echo "═══════════════════════════════════════════════════════"
echo "/etc/resolv.conf:"
cat /etc/resolv.conf
echo ""

echo "3. SYSTEMD-RESOLVED STATUS"
echo "═══════════════════════════════════════════════════════"
systemctl is-active systemd-resolved 2>/dev/null && check "systemd-resolved is running" || warn "systemd-resolved is not running"
if command -v resolvectl &> /dev/null; then
    echo ""
    resolvectl status 2>/dev/null || warn "resolvectl status failed"
fi
echo ""

echo "4. NETWORKMANAGER DNS CONFIGURATION"
echo "═══════════════════════════════════════════════════════"
nmcli dev show 2>/dev/null | grep -A 2 "DNS\|^DNS" || warn "nmcli not available or no DNS config"
echo ""

echo "5. IPV6 INTERFACE STATUS"
echo "═══════════════════════════════════════════════════════"
ip -6 addr show 2>/dev/null | grep -E "inet6|fe80" || warn "No IPv6 addresses found"
echo ""

echo "6. DNS RESOLUTION TESTS"
echo "═══════════════════════════════════════════════════════"
echo "Testing Quad9 DNS (9.9.9.10):"
time host cache.nixos.org 9.9.9.10 && check "Quad9 can resolve cache.nixos.org" || warn "Quad9 failed to resolve"
echo ""

echo "Testing Quad9 DNS (9.9.9.11):"
time host cache.nixos.org 9.9.9.11 && check "Quad9 secondary resolves cache.nixos.org" || warn "Quad9 secondary failed"
echo ""

echo "Testing Router DNS (10.43.255.55):"
time host cache.nixos.org 10.43.255.55 && check "Router DNS resolves cache.nixos.org" || warn "Router DNS failed"
echo ""

echo "7. DNSSEC VALIDATION TESTS"
echo "═══════════════════════════════════════════════════════"
if command -v dig &> /dev/null; then
    echo "Quad9 with DNSSEC:"
    dig @9.9.9.10 +dnssec cache.nixos.org | grep -E "flags|AD" || warn "dig command failed"
    echo ""
else
    warn "dig not installed, skipping DNSSEC tests"
fi
echo ""

echo "8. MTU & PATH MTU DISCOVERY"
echo "═══════════════════════════════════════════════════════"
ip link show | grep -E "^\d+:|mtu" | head -20
echo ""
echo "Testing path MTU:"
if command -v ping &> /dev/null; then
    ping -c 1 -M do -s 1472 cache.nixos.org 2>/dev/null && check "MTU 1472 works" || warn "MTU 1472 failed"
    ping -c 1 -M do -s 1473 cache.nixos.org 2>/dev/null && warn "MTU 1473 should fail but didn't" || check "MTU 1473 correctly blocked"
else
    warn "ping not available"
fi
echo ""

echo "9. NIX DAEMON SETTINGS"
echo "═══════════════════════════════════════════════════════"
nix show-config 2>/dev/null | grep -E "timeout|connections|max-jobs" || warn "Could not show nix config"
echo ""

echo "10. SECURITY SERVICES STATUS"
echo "═══════════════════════════════════════════════════════"
systemctl is-active fail2ban 2>/dev/null && check "Fail2ban is running" || warn "Fail2ban not running"
systemctl is-active clamav-daemon 2>/dev/null && check "ClamAV daemon is running" || warn "ClamAV daemon not running"
systemctl is-active clamav-freshclam 2>/dev/null && check "ClamAV updater is running" || warn "ClamAV updater not running"
echo ""

echo "11. DOCKER DNS CONFIGURATION"
echo "═══════════════════════════════════════════════════════"
if command -v docker &> /dev/null; then
    docker info 2>/dev/null | grep -i dns || warn "Could not get Docker DNS config"
    echo ""
    echo "Testing DNS from Docker container:"
    timeout 5 docker run --rm alpine sh -c "nslookup cache.nixos.org" 2>&1 | head -10 || warn "Docker DNS test failed"
else
    warn "Docker not available"
fi
echo ""

echo "12. PROXY & ENVIRONMENT VARIABLES"
echo "═══════════════════════════════════════════════════════"
env | grep -i proxy || warn "No proxy environment variables found"
echo ""

echo "13. ISP DNS BLOCKING TEST"
echo "═══════════════════════════════════════════════════════"
echo "Testing direct IP access (bypasses DNS):"
if command -v curl &> /dev/null; then
    time curl -I -m 5 https://151.101.193.91/ 2>&1 | head -5 && check "Direct IP to cache.nixos.org works" || warn "Direct IP access failed"
else
    warn "curl not available"
fi
echo ""

echo "14. NETWORK INTERFACE DETAILS"
echo "═══════════════════════════════════════════════════════"
ip addr show | grep -E "^\d+:|inet |inet6 " | head -30
echo ""

echo "15. RECOMMENDATIONS"
echo "═══════════════════════════════════════════════════════"

# Check for issues and provide recommendations
if grep -q "nameserver fe80:" /etc/resolv.conf; then
    warn "ISSUE: IPv6 link-local DNS present in resolv.conf"
    echo "  → Recommendation: Add 'networking.networkmanager.ipv6.dns.ipv4-only = true'"
fi

if systemctl is-active systemd-resolved &>/dev/null; then
    warn "ISSUE: systemd-resolved is running alongside NetworkManager DNS"
    echo "  → Recommendation: Disable systemd-resolved or configure NetworkManager to use it"
fi

if ! grep -q "9.9.9.10" /etc/resolv.conf; then
    warn "ISSUE: Quad9 DNS not being used"
    echo "  → Recommendation: Check NetworkManager DNS override in NixOS config"
fi

# Check FD limit
FD_LIMIT=$(ulimit -n)
if [ "$FD_LIMIT" -lt 4096 ]; then
    warn "ISSUE: File descriptor limit too low ($FD_LIMIT)"
    echo "  → Recommendation: Increase with 'systemd.extraConfig' or PAM limits"
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  DIAGNOSTIC COMPLETE                                       ║"
echo "╚══════════════════════════════════════════════════════╝"
