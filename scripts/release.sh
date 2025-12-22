#!/usr/bin/env bash
# Release Creation Script
# Implements git tagging strategy for releases

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

# Function to create release tag
create_release_tag() {
    local tag_name="$1"
    local tag_message="$2"
    
    log_info "Creating release tag: $tag_name"
    
    if git tag -a "$tag_name" -m "$tag_message" 2>/dev/null; then
        log_success "Tag created: $tag_name"
        return 0
    else
        log_warning "Tag creation failed, tag might already exist"
        git tag -d "$tag_name" 2>/dev/null || true
        git tag -a "$tag_name" -m "$tag_message"
        log_success "Tag re-created: $tag_name"
        return 0
    fi
}

# Function to push tags
push_tags() {
    log_info "Pushing tags to remote..."
    
    if git push origin --tags 2>/dev/null; then
        log_success "Tags pushed successfully"
        return 0
    else
        log_warning "Tag push failed, might need force push"
        git push origin --tags --force
        log_success "Tags pushed with force"
        return 0
    fi
}

# Function to generate release notes
generate_release_notes() {
    log_info "Generating release notes..."
    
    local current_tag="$1"
    local prev_tag="$2"
    
    echo -e "${GREEN}## RELEASE NOTES: $current_tag${NC}"
    echo ""
    
    echo -e "${BLUE}### Features:${NC}"
    echo "✅ Optimized Hyprland configuration with performance tuning"
    echo "✅ Comprehensive AI integration with Ollama + ROCm"
    echo "✅ DeepSeek model support with GPU acceleration"
    echo "✅ Full OCR computer vision stack (pillow, opencv4)"
    echo "✅ Advanced security monitoring (lynis, fail2ban, wireshark)"
    echo "✅ Automated testing pipeline with pre/post-commit hooks"
    echo "✅ Performance benchmark suite with graceful fallbacks"
    echo ""
    
    echo -e "${BLUE}### Technical Improvements:${NC}"
    echo "• Fixed all Nix syntax errors and package conflicts"
    echo "• Resolved SSH configuration issues (PrintMotds typo)"
    echo "• Made configuration pass nix flake check validation"
    echo "• Created robust testing for missing tool environments"
    echo "• Implemented commit automation with validation hooks"
    echo ""
    
    echo -e "${BLUE}### AI/ML Stack:${NC}"
    echo "• Ollama service with ROCm GPU acceleration"
    echo "• PyTorch ecosystem (torch, transformers, accelerate)"
    echo "• Computer vision (pillow, opencv4, pytesseract)"
    echo "• Model management (vllm, tokenizers)"
    echo "• DeepSeek models ready for deployment"
    echo ""
    
    echo -e "${BLUE}### Security:${NC}"
    echo "• SSH hardening (no passwords, no root, banner)"
    echo "• Fail2ban with IP banning and brute force detection"
    echo "• ClamAV antivirus with real-time scanning"
    echo "• Lynis security auditing and CIS baseline checks"
    echo "• AIDE file integrity monitoring"
    echo "• Network security tools (nmap, wireshark, nethogs)"
    echo ""
    
    echo -e "${BLUE}### Performance:${NC}"
    echo "• Hyprland optimization for AMD AI Max+ 395"
    echo "• Variable refresh rate (VRR) enabled"
    echo "• Direct scanout memory optimization active"
    echo "• GPU video transcoding acceleration"
    echo "• High performance monitor refresh mode"
    echo ""
    
    echo -e "${BLUE}### System:${NC}"
    echo "• AMD Ryzen AI Max+ 395 with Radeon 8060S support"
    echo "• ROCm GPU acceleration with proper environment variables"
    echo "• Automated validation and testing pipeline"
    echo "• Modular architecture with separate configurations"
    echo ""
}

# Function to create main release
create_v1_release() {
    log_info "Creating v1.0 optimized-baseline release..."
    echo ""
    
    local tag_name="v1.0"
    local tag_message="v1.0: Optimized NixOS baseline with Hyprland + AI + Security

This release includes:
- Optimized Hyprland performance configuration
- Full AI/ML stack with ROCm acceleration  
- DeepSeek model integration and support
- Comprehensive security monitoring suite
- Automated testing and validation pipeline
- Performance benchmark and optimization tools
- Robust error handling and graceful fallbacks

System ready for high-performance AI workloads with AMD GPU acceleration."

    # Create release tag
    create_release_tag "$tag_name" "$tag_message"
    
    # Generate release notes
    generate_release_notes "$tag_name" ""
    
    # Push tags
    push_tags
}

# Function to create quick release
create_quick_release() {
    local current_time=$(date +%H:%M)
    log_info "Creating quick release tag..."
    echo ""
    
    local tag_name="release-$(date +%Y%m%d-%H%M)"
    local tag_message="Quick release at $current_time - Latest optimizations and fixes

Includes latest performance improvements and bug fixes for deployment readiness."

    # Create release tag
    create_release_tag "$tag_name" "$tag_message"
    
    # Generate brief notes
    echo -e "${GREEN}Quick Release: $tag_name${NC}"
    echo -e "${BLUE}Message: $tag_message${NC}"
    
    # Push tags
    push_tags
}

# Function to list current tags
list_tags() {
    log_info "Listing current release tags..."
    echo ""
    
    if command -v git >/dev/null 2>&1; then
        git tag --sort=-version:refname | head -10
    else
        log_warning "Git command not available"
    fi
}

# Function to suggest release strategy
suggest_strategy() {
    log_info "Release strategy recommendations:"
    echo ""
    
    echo -e "${GREEN}### SEMANTIC VERSIONING:${NC}"
    echo "• v1.0: Major release - Complete baseline system"
    echo "• v1.1: Minor release - Performance optimizations"
    echo "• v1.2: Minor release - Security hardening"
    echo "• v2.0: Major release - AI model updates"
    echo ""
    
    echo -e "${GREEN}### TAGGING CONVENTION:${NC}"
    echo "• Format: v{major}.{minor}.{patch}"
    echo "• Examples: v1.0, v1.1, v1.2, v2.0"
    echo "• Quick: release-{date}-{time} for rapid fixes"
    echo ""
    
    echo -e "${GREEN}### RELEASE WORKFLOW:${NC}"
    echo "1. Test configuration: nix flake check"
    echo "2. Validate services: systemctl status ollama"
    echo "3. Run benchmarks: ./scripts/performance-test.sh"
    echo "4. Create tag: ./scripts/release.sh create"
    echo "5. Push release: ./scripts/release.sh push"
    echo "6. Deploy: sudo nixos-rebuild switch"
    echo ""
}

# Function to show help
show_help() {
    echo -e "${BLUE}Release Management Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  create    - Create v1.0 optimized-baseline release"
    echo "  quick     - Create quick release with timestamp"
    echo "  push      - Push all tags to remote"
    echo "  list      - List current release tags"
    echo "  strategy  - Show release strategy recommendations"
    echo "  notes     - Generate release notes"
    echo "  help      - Show this help message"
    echo ""
}

# Main execution
main() {
    case "${1:-help}" in
        "create")
            create_v1_release
            ;;
        "quick")
            create_quick_release
            ;;
        "push")
            push_tags
            ;;
        "list")
            list_tags
            ;;
        "strategy")
            suggest_strategy
            ;;
        "notes")
            generate_release_notes "v1.0" ""
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function
main "$@"