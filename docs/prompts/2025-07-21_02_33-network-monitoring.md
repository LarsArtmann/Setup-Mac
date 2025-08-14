# Reusable Prompt: Network Monitoring and Package Deployment

**Created**: 2025-07-21T02:33+02:00  
**Based on**: Network monitoring implementation session learnings  
**Use Cases**: Network monitoring setup, package deployment, system monitoring tools

## Core Prompt Template

```
I need to implement network monitoring capabilities on macOS with Nix configuration management.

CRITICAL REQUIREMENTS:
1. VERIFY FIRST: Always check package availability before configuration work
2. SIMPLE FIRST: Try basic installation before complex integration  
3. REALITY CHECK: Validate all suggestions with actual commands
4. PLATFORM AWARE: Ensure macOS/Darwin compatibility for all packages

SPECIFIC VERIFICATION PROTOCOL:
Before implementing any package suggestions:
1. Run: nix search nixpkgs <package-name>
2. Verify Darwin platform support explicitly
3. If not available in Nix, check: brew search <package-name>
4. Test basic functionality before configuration integration

TARGET SETUP:
- Primary monitoring tool: [specify requirements]
- Integration method: Nix-first, Homebrew fallback
- Configuration management: Declarative via existing Nix flake
- Verification: Working system before documentation

LEARNING FROM PREVIOUS SESSION:
- Task agents may provide confident but incorrect package availability information
- Always verify with direct commands before trusting research outputs
- ntopng is not available for Darwin in nixpkgs
- netdata works well via Homebrew for immediate monitoring needs
- systemd configurations don't apply to macOS (uses launchd instead)

EXPECTED DELIVERABLES:
1. Working monitoring solution (verified functionality)
2. Integration with existing Nix configuration (if appropriate)
3. Verification commands and troubleshooting steps
4. Platform-specific considerations documented
```

## Specialized Variants

### 1. Quick Network Monitoring Setup

```
I need immediate network monitoring capabilities on macOS. Priority is working solution over perfect integration.

CONSTRAINTS:
- Must work within 30 minutes
- Prefer simple installation over complex configuration
- Web interface preferred for monitoring
- Should integrate with existing system without breaking configuration

APPROACH:
1. Check Homebrew first for GUI/monitoring tools
2. Verify functionality before any Nix integration
3. Document working setup for future declarative migration
4. Include basic usage commands and troubleshooting

VERIFICATION CHECKLIST:
- [ ] Package installs successfully
- [ ] Service starts and runs
- [ ] Web interface accessible (if applicable)
- [ ] Basic monitoring data visible
- [ ] No conflicts with existing system configuration
```

### 2. Comprehensive Network Analysis Setup

```
I need detailed network traffic analysis and monitoring capabilities integrated with my declarative Nix configuration.

REQUIREMENTS:
- Network traffic analysis (packet inspection, flow monitoring)
- Real-time monitoring dashboard
- Historical data retention
- Integration with existing Nix flake configuration
- macOS/Darwin compatibility verified

VERIFICATION PROTOCOL:
1. Research phase: Check both nixpkgs and Homebrew availability
2. Compatibility phase: Verify Darwin support explicitly  
3. Testing phase: Proof-of-concept installation
4. Integration phase: Add to declarative configuration
5. Documentation phase: Working configuration with troubleshooting

KNOWN CONSTRAINTS:
- Many Linux network tools not available on macOS
- Some tools require additional system permissions
- GUI tools often better via Homebrew
- Command-line tools often better via Nix

FALLBACK STRATEGY:
If primary tools unavailable:
- Alternative macOS-compatible tools
- Built-in macOS network monitoring utilities
- Third-party commercial solutions evaluation
```

### 3. Package Research and Verification

```
I need to research and verify package availability for [SPECIFIC_TOOL] on macOS with Nix configuration management.

RESEARCH PROTOCOL:
1. VERIFICATION FIRST: Check actual availability before planning
   - nix search nixpkgs [PACKAGE_NAME]
   - Verify Darwin platform support
   - Check alternative package names

2. PLATFORM COMPATIBILITY:
   - Confirm macOS support (not Linux-only)
   - Check system requirements and dependencies
   - Identify platform-specific configuration needs

3. INSTALLATION TESTING:
   - Simple installation test before complex integration
   - Verify basic functionality
   - Document any issues or limitations

4. INTEGRATION PLANNING:
   - Determine appropriate Nix configuration file
   - Plan service configuration if needed
   - Consider Homebrew fallback if Nix unavailable

CRITICAL VERIFICATION COMMANDS:
nix search nixpkgs [PACKAGE]
brew search [PACKAGE]  
[PACKAGE] --version    # After installation
[PACKAGE] --help       # Basic functionality check

OUTPUT REQUIREMENTS:
- Confirmed package availability and platform support
- Working installation method
- Basic usage verification
- Integration recommendations with rationale
```

## Anti-Patterns to Avoid

### Common Mistakes from Previous Sessions

```
AVOID THESE APPROACHES:

❌ Trusting Task agent package research without verification
❌ Creating comprehensive documentation before proving functionality  
❌ Attempting complex Nix integration before simple installation test
❌ Assuming Linux package configurations work on macOS
❌ Spending more time on documentation than implementation
❌ Using systemd configurations on macOS
❌ Adding packages to Nix config without confirming Darwin availability

✅ INSTEAD USE THESE APPROACHES:

✅ Verify package availability with direct commands first
✅ Test basic functionality before comprehensive configuration
✅ Use progressive complexity (simple → complex)
✅ Document working systems, not theoretical ones
✅ Platform-specific research and configuration
✅ "Working first, documenting second" approach
✅ Appropriate package manager choice (Nix vs Homebrew)
```

## Success Criteria Templates

### Minimal Success
- [ ] Package installs successfully on macOS
- [ ] Basic functionality verified with simple test
- [ ] No system conflicts or configuration breaking
- [ ] Working uninstall/rollback procedure documented

### Standard Success  
- [ ] All minimal success criteria met
- [ ] Integration with existing configuration management
- [ ] Service starts automatically if applicable
- [ ] Basic monitoring/functionality accessible
- [ ] Troubleshooting steps documented

### Comprehensive Success
- [ ] All standard success criteria met
- [ ] Advanced configuration and customization
- [ ] Performance optimization applied
- [ ] Integration with other monitoring tools
- [ ] Comprehensive documentation with examples

## Platform-Specific Considerations

### macOS/Darwin Specific Checks

```bash
# Package availability verification
nix search nixpkgs <package>
nix-env -qaP | grep <package>

# Homebrew alternative research  
brew search <package>
brew info <package>

# Service management (macOS uses launchd, not systemd)
launchctl list | grep <service>
brew services list

# Permission and security considerations
# Some network tools require additional permissions
# System integrity protection may affect tool functionality
```

### Known Working Patterns

```bash
# GUI monitoring tools → Homebrew
brew install --cask <monitoring-app>

# CLI network utilities → Nix when available
nix search nixpkgs iftop
# Add to environment.nix systemPackages

# System-level monitoring → Often Homebrew
brew install netdata
brew services start netdata

# Development tools → Usually Nix
nix search nixpkgs tcpdump
```

## Template Usage Instructions

1. **Choose appropriate variant** based on complexity and timeline requirements
2. **Customize placeholders** with specific tool names and requirements  
3. **Follow verification protocol** strictly before implementation
4. **Document outcomes** including failures and workarounds
5. **Update this template** with new learnings and patterns

## Integration with Existing Workflows

### Nix Configuration Files
- **CLI tools**: Add to `dotfiles/nix/environment.nix` systemPackages
- **GUI applications**: Add to `dotfiles/nix/homebrew.nix` casks
- **Services**: Configure in appropriate Nix modules

### Deployment Commands
```bash
just test        # Verify configuration before applying
just switch      # Apply changes
just rollback    # Revert if issues
```

### Verification Commands
```bash
just health      # System health check
just check       # Configuration status
which <package>  # Verify installation
<package> --version  # Confirm functionality
```

---

**Usage Note**: This prompt template incorporates learnings from actual deployment sessions and should be updated as new patterns and anti-patterns are discovered. Always prioritize working systems over theoretical perfection.