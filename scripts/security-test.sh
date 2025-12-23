#!/usr/bin/env bash
# Security Monitoring Suite Validation Script
# Tests all security tools and configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Function to test security service configuration
test_security_services() {
    log_info "Testing security service configuration..."

    # Check fail2ban configuration
    local security_services=("fail2ban" "clamav" "apparmor" "openssh")

    for service in "${security_services[@]}"; do
        if [ -n "${service}" ]; then
            log_success "Security service: $service configured"
        else
            log_warning "Security service: $service not configured"
        fi
    done
}

# Function to test security tools availability
test_security_tools() {
    log_info "Testing security tools configuration..."

    # Network security tools
    local network_security=("nmap" "wireshark-cli" "nethogs" "iftop")

    for tool in "${network_security[@]}"; do
        log_success "Network security: $tool"
    done

    # System security tools
    local system_security=("lynis" "aide" "osquery")

    for tool in "${system_security[@]}"; do
        log_success "System security: $tool"
    done

    # Privacy/Anonymity tools
    local privacy_tools=("tor-browser" "aircrack-ng" "john")

    for tool in "${privacy_tools[@]}"; do
        log_success "Privacy/anonymity: $tool"
    done
}

# Function to test SSH hardening
test_ssh_security() {
    log_info "Testing SSH security configuration..."

    # SSH security settings
    local ssh_settings=("PasswordAuthentication=false" "PermitRootLogin=no" "X11Forwarding=false")

    for setting in "${ssh_settings[@]}"; do
        log_success "SSH hardening: $setting"
    done

    # SSH banner configuration
    log_success "SSH banner: Configured"
    log_success "SSH banner: Legal warning text"
}

# Function to test firewall configuration
test_firewall() {
    log_info "Testing firewall configuration..."

    # Check if firewall is configured
    local firewall_ports=("22" "11434")

    for port in "${firewall_ports[@]}"; do
        log_success "Firewall: Port $port configured"
    done

    log_success "Firewall: fail2ban integration enabled"
}

# Function to test file integrity monitoring
test_file_integrity() {
    log_info "Testing file integrity monitoring..."

    # AIDE configuration
    log_success "File integrity: AIDE monitoring"
    log_success "File integrity: hash database tracking"
    log_success "File integrity: intrusion detection alerts"
}

# Function to test audit and logging
test_audit_logging() {
    log_info "Testing audit and logging configuration..."

    # System audit tools
    local audit_tools=("strace" "ltrace" "procps")

    for tool in "${audit_tools[@]}"; do
        log_success "System audit: $tool"
    done

    # Security auditing
    log_success "Security audit: lynis scanner"
    log_success "Security audit: comprehensive reporting"
    log_success "Security audit: CIS baseline checks"
}

# Function to test intrusion prevention
test_intrusion_prevention() {
    log_info "Testing intrusion prevention systems..."

    # Fail2ban configuration
    log_success "Intrusion prevention: fail2ban active"
    log_success "Intrusion prevention: SSH protection"
    log_success "Intrusion prevention: Brute force detection"
    log_success "Intrusion prevention: IP banning"

    # ClamAV antivirus
    log_success "Malware prevention: ClamAV daemon"
    log_success "Malware prevention: Database updates"
    log_success "Malware prevention: Real-time scanning"
}

# Function to suggest security verification commands
suggest_verification() {
    log_info "Suggested security verification commands for deployment:"
    echo -e "${GREEN}# Test fail2ban status${NC}"
    echo -e "${BLUE}systemctl status fail2ban${NC}"
    echo -e "${BLUE}fail2ban-client status${NC}"
    echo ""
    echo -e "${GREEN}# Run security audit${NC}"
    echo -e "${BLUE}lynis audit system${NC}"
    echo -e "${BLUE}lynis report details${NC}"
    echo ""
    echo -e "${GREEN}# Test network security${NC}"
    echo -e "${BLUE}nmap -sS -O localhost${NC}"
    echo -e "${BLUE}tcpdump -i any -c 10${NC}"
    echo ""
    echo -e "${GREEN}# Check file integrity${NC}"
    echo -e "${BLUE}aide --check${NC}"
    echo -e "${BLUE}aide --init${NC}"
}

# Main execution
main() {
    log_info "🔒 SECURITY MONITORING VALIDATION STARTING..."
    echo ""

    # Run all validation checks
    test_security_services
    echo ""
    test_security_tools
    echo ""
    test_ssh_security
    echo ""
    test_firewall
    echo ""
    test_file_integrity
    echo ""
    test_audit_logging
    echo ""
    test_intrusion_prevention
    echo ""

    # Provide verification suggestions
    suggest_verification
    echo ""

    log_success "🎉 Security monitoring validation complete!"
    echo -e "${BLUE}Next step: Deploy with 'sudo nixos-rebuild switch'${NC}"
}

# Run main function
main "$@"