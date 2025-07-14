# Troubleshooting Documentation

This directory contains troubleshooting guides and solutions for common issues with the Nix Darwin setup.

## Quick Reference

### Immediate Issues

If you're experiencing immediate problems:

1. **Configuration won't apply:** See [Common Issues](./common-issues.md#darwin-rebuild-fails)
2. **Commands not found:** Check [PATH Problems](./common-issues.md#path-problems)
3. **Packages failing:** See [Package Issues](./common-issues.md#package-issues)
4. **Performance problems:** Check [Performance Issues](./common-issues.md#performance-issues)

### Emergency Recovery

If your system is broken after a configuration change:

```bash
# Rollback to previous generation
sudo darwin-rebuild rollback

# Or manually switch to previous generation
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### Quick Diagnostics

Run these commands to gather system information:

```bash
# Check Nix status
nix doctor

# Verify configuration syntax
nix flake check

# Check system generation
darwin-rebuild --list-generations
```

## Documentation Structure

- **[common-issues.md](./common-issues.md)** - Most frequently encountered problems and solutions
- **[recovery.md](./recovery.md)** - System recovery procedures (if needed)
- **[performance.md](./performance.md)** - Performance optimization tips (if needed)

## Getting Help

1. **Check existing issues** in this documentation first
2. **Search community forums** like NixOS Discourse
3. **Create minimal reproduction** cases for complex issues
4. **Include diagnostic output** when asking for help

## Contributing

Found a solution to a problem not documented here? Please add it to the appropriate file or create a new one if needed.