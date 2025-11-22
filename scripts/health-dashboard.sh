#!/usr/bin/env bash
# System Health Check Script for Setup-Mac
# Provides color-coded system status information

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Status indicators
OK="${GREEN}✅${NC}"
WARN="${YELLOW}⚠️${NC}"
ERROR="${RED}❌${NC}"
INFO="${BLUE}ℹ️${NC}"

echo -e "${CYAN}🏥 System Health Dashboard${NC}"
echo -e "${CYAN}=========================${NC}"
echo ""

# Nix Configuration Status
echo -e "${PURPLE}🔧 Nix Configuration:${NC}"
current_gen=$(darwin-rebuild --list-generations 2>/dev/null | head -n 1 | awk '{print $1}' || echo "Unknown")
profile_path=$(readlink /run/current-system 2>/dev/null || echo "Unknown")
fish_path=$(which fish 2>/dev/null)

echo -e "  • Generation: ${INFO} $current_gen"
echo -e "  • Profile: ${INFO} $profile_path"
if [ -n "$fish_path" ]; then
    echo -e "  • Fish Shell: $OK $fish_path"
else
    echo -e "  • Fish Shell: $ERROR Not found"
fi
echo ""

# Disk Space
echo -e "${PURPLE}💾 Disk Space:${NC}"
root_info=$(df -h / | awk 'NR==2 {print $4 " free (" $5 " used)"}')
home_info=$(df -h ~ | awk 'NR==2 {print $4 " free (" $5 " used)"}')
nix_store_size=$(nix store du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo "Unknown")

echo -e "  • Root: ${INFO} $root_info"
echo -e "  • Home: ${INFO} $home_info"
echo -e "  • Nix Store: ${INFO} $nix_store_size"
echo ""

# Memory Usage
echo -e "${PURPLE}🧠 Memory Usage:${NC}"
free_gb=$(vm_stat 2>/dev/null | grep 'Pages free' | awk '{printf "%.1f GB\n", $3 * 4096 / 1024/1024/1024}' || echo "Unknown")
pressure_info=$(memory_pressure 2>/dev/null | grep 'System-wide memory free percentage' | awk '{print $5}' || echo "Unknown")

echo -e "  • Free: ${INFO} $free_gb"
echo -e "  • Pressure: ${INFO} $pressure_info"
echo ""

# CPU Info
echo -e "${PURPLE}🔥 CPU Info:${NC}"
load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
uptime_info=$(uptime | awk '{print $3,$4}' | sed 's/,//')

echo -e "  • Load Average: ${INFO} $load_avg"
echo -e "  • Uptime: ${INFO} $uptime_info"
echo ""

# Network Status
echo -e "${PURPLE}🌐 Network Status:${NC}"
interface_count=$(ifconfig -a 2>/dev/null | grep '^[a-z]' | wc -l | tr -d ' ')
gateway=$(route -n get default 2>/dev/null | grep 'gateway' | awk '{print $2}' || echo "No gateway")

echo -e "  • Interfaces: ${INFO} $interface_count active"
echo -e "  • Gateway: ${INFO} $gateway"
echo ""

# Services Status
echo -e "${PURPLE}🔍 Services:${NC}"
netdata_status=$(pgrep netdata > /dev/null && echo "Running" || echo "Stopped")
ssh_agent_status=$(pgrep ssh-agent > /dev/null && echo "Running" || echo "Stopped")
fish_config_status=$([ -f ~/.config/fish/config.fish ] && echo "Present" || echo "Missing")

if [ "$netdata_status" = "Running" ]; then
    echo -e "  • Netdata: $OK $netdata_status"
else
    echo -e "  • Netdata: $WARN $netdata_status"
fi

if [ "$ssh_agent_status" = "Running" ]; then
    echo -e "  • SSH Agent: $OK $ssh_agent_status"
else
    echo -e "  • SSH Agent: $ERROR $ssh_agent_status"
fi

if [ "$fish_config_status" = "Present" ]; then
    echo -e "  • Fish Config: $OK $fish_config_status"
else
    echo -e "  • Fish Config: $ERROR $fish_config_status"
fi
echo ""

# Development Environment
echo -e "${PURPLE}👨‍💻 Development:${NC}"
gitleaks_status=$([ -f .pre-commit-config.yaml ] && grep -q gitleaks .pre-commit-config.yaml && echo "Configured" || echo "Not configured")
ssh_keys_count=$(ssh-add -l 2>/dev/null | wc -l | tr -d ' ')

if [ "$gitleaks_status" = "Configured" ]; then
    echo -e "  • Gitleaks: $OK $gitleaks_status"
else
    echo -e "  • Gitleaks: $WARN $gitleaks_status"
fi

echo -e "  • SSH Keys: ${INFO} $ssh_keys_count loaded"
echo ""

# Quick Actions
echo -e "${PURPLE}💡 Quick Actions:${NC}"
echo -e "  • Start monitoring: ${CYAN}just netdata-start${NC}"
echo -e "  • Clean system: ${CYAN}just clean${NC}"
echo -e "  • Update system: ${CYAN}just update${NC}"
echo -e "  • Test config: ${CYAN}just test${NC}"
echo ""

# Resource Usage Recommendations
echo -e "${PURPLE}📊 Resource Usage Tips:${NC}"
echo -e "  • ${INFO} Netdata: Low overhead (~100-150MB RAM), suitable for continuous monitoring"
echo -e "  • ${WARN} ntopng: High overhead (2GB+ RAM), use only for network troubleshooting"
echo -e "  • ${OK} Recommendation: Keep Netdata running, start ntopng on-demand"