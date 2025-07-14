# Comprehensive Troubleshooting Guide

This guide covers common issues you might encounter when setting up, maintaining, or optimizing your Nix Darwin development environment. It includes specific troubleshooting for the optimization project and performance issues.

## Quick Diagnosis

Before diving into specific issues, try these diagnostic commands:

```bash
# System health check
./scripts/health-check.sh

# Performance benchmark
./shell-performance-benchmark.sh

# View recent optimizations
cat .last_optimization_backup 2>/dev/null || echo "No recent optimizations"

# Check current configuration status
claude config ls
nix show-config
```

## Installation Issues

### Nix Installation Fails

**Problem:** Nix installer fails with permission errors or network issues.

**Solutions:**
1. Ensure you have administrative privileges
2. Check internet connection
3. Try the official installer if Determinate Systems installer fails:
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```
4. On Apple Silicon Macs, ensure Rosetta 2 is installed:
   ```bash
   softwareupdate --install-rosetta
   ```

### Darwin Rebuild Fails

**Problem:** `darwin-rebuild switch` fails with various errors.

**Common causes and solutions:**

1. **Dirty Git tree warning:**
   - This is just a warning, not an error
   - Commit your changes or use `--option warn-dirty false`

2. **Permission denied errors:**
   - Run with sudo: `sudo darwin-rebuild switch --flake .#Lars-MacBook-Air`
   - Check file permissions in the nix directory

3. **Flake evaluation errors:**
   ```bash
   # Check flake syntax first
   nix flake check

   # Show detailed error trace
   darwin-rebuild switch --flake .#Lars-MacBook-Air --show-trace
   ```

### Home Manager Configuration Issues

**Problem:** Home Manager fails to evaluate or apply configuration.

**Solutions:**
1. Check if home directory path is correct in `home.nix`
2. Ensure stateVersion matches your system
3. Temporarily disable problematic configurations to isolate issues

## Package Issues

### Package Not Found

**Problem:** Nix complains that a package doesn't exist.

**Solutions:**
1. Search for the package: `nix search nixpkgs package-name`
2. Check if the package name has changed: https://search.nixos.org/packages
3. Consider using Homebrew as an alternative:
   ```nix
   # In homebrew.nix
   brews = [ "package-name" ];
   ```

### Package Build Failures

**Problem:** Packages fail to build or have dependency issues.

**Solutions:**
1. Update flake inputs: `nix flake update`
2. Try building individual packages: `nix build nixpkgs#package-name`
3. Check if the package is marked as broken: `nix-env -qa --meta --description package-name`
4. Use an older version or alternative package temporarily

### Homebrew Integration Issues

**Problem:** Homebrew packages not installing or conflicting with Nix.

**Solutions:**
1. Ensure `nix-homebrew` is enabled in flake configuration
2. Check if taps are properly configured:
   ```bash
   brew tap # Should show configured taps
   ```
3. Clear Homebrew cache: `brew cleanup`
4. Manually install problematic casks: `brew install --cask app-name`

## System Issues

### PATH Problems

**Problem:** Commands not found even though packages are installed.

**Solutions:**
1. Restart your terminal to reload PATH
2. Check if PATH includes Nix paths:
   ```bash
   echo $PATH | tr ':' '\n' | grep nix
   ```
3. Manually source the environment:
   ```bash
   source /etc/bashrc
   source /etc/zshrc
   ```

### Environment Variables Not Set

**Problem:** Custom environment variables not available.

**Solutions:**
1. Check if variables are defined in `environment.nix`
2. Restart terminal or source configuration
3. For user-specific variables, check `home.nix`

### Shell Configuration Issues

**Problem:** Shell aliases or configurations not working.

**Solutions:**
1. Verify shell is properly configured in `environment.nix`
2. Check if you're using the right shell: `echo $SHELL`
3. For Home Manager shell configs, ensure the shell is enabled in `home.nix`

## Development Tool Issues

### Go Development Problems

**Problem:** Go tools not working or import issues.

**Solutions:**
1. Ensure GOPATH and GOROOT are set correctly:
   ```bash
   go env GOPATH
   go env GOROOT
   ```
2. Check if Go modules are enabled: `go env GO111MODULE`
3. Clear module cache: `go clean -modcache`

### Node.js/JavaScript Issues

**Problem:** npm/yarn/pnpm not working or version conflicts.

**Solutions:**
1. Use Bun for new projects (included in config)
2. Check Node.js version: `node --version`
3. Clear package caches:
   ```bash
   bun cache clear  # or
   pnpm store prune
   ```

### Kubernetes Tools Issues

**Problem:** kubectl, k9s, or other K8s tools not connecting.

**Solutions:**
1. Check kubeconfig: `kubectl config view`
2. Verify cluster connectivity: `kubectl cluster-info`
3. For k9s, check if correct context is selected

### JetBrains Toolbox Issues

**Problem:** JetBrains IDEs not launching or indexing issues.

**Solutions:**
1. Ensure JetBrains Toolbox is installed via Homebrew (not Nix)
2. Check if IDEs have proper permissions
3. Clear IDE caches: Help → Invalidate Caches and Restart

## Performance Issues

### Slow Nix Operations

**Problem:** Nix builds or evaluations are very slow.

**Solutions:**
1. Use binary cache: ensure `substituters` are configured
2. Clean up old generations: `nix-collect-garbage -d`
3. Check disk space: `df -h /nix`
4. Consider using `nix-direnv` for project-specific environments

### High Memory Usage

**Problem:** System using too much memory.

**Solutions:**
1. Check what's using memory: `htop` or Activity Monitor
2. Limit Nix build jobs: add `max-jobs = 4` to nix.conf
3. Close unnecessary applications
4. Restart Nix daemon: `sudo launchctl kickstart -k system/org.nixos.nix-daemon`

## Security Tool Issues

### Little Snitch/Lulu Blocking Connections

**Problem:** Security tools blocking legitimate network access.

**Solutions:**
1. Check Little Snitch rules and whitelist necessary connections
2. For development, temporarily disable or create rules for dev servers
3. Lulu should allow most outgoing connections by default

### SSH/Git Authentication Issues

**Problem:** Git operations or SSH connections failing.

**Solutions:**
1. Check if SSH keys are properly configured in Secretive
2. Test SSH connection: `ssh -T git@github.com`
3. Verify GPG signing (if used): `gpg --list-secret-keys`

## Diagnostic Commands

When reporting issues, include output from these commands:

```bash
# System information
uname -a
system_profiler SPSoftwareDataType

# Nix information
nix --version
nix show-config

# Darwin configuration
darwin-rebuild --version
nix flake show

# Package information
nix-env -q
brew list
```

## Getting Help

1. **Check logs:**
   ```bash
   # Darwin rebuild logs
   tail -f /var/log/system.log | grep nix

   # Nix daemon logs
   journalctl -u nix-daemon
   ```

2. **Community resources:**
   - NixOS Discourse: https://discourse.nixos.org/
   - Nix Darwin GitHub: https://github.com/LnL7/nix-darwin
   - Home Manager manual: https://nix-community.github.io/home-manager/

3. **Debug mode:**
   ```bash
   # Run with debug output
   darwin-rebuild switch --flake .#Lars-MacBook-Air --show-trace --verbose
   ```

## Optimization Issues

### Performance Optimization Failures

**Problem:** Optimization script fails or causes system instability.

**Solutions:**
1. **Rollback to previous state:**
   ```bash
   # Check if backup exists
   ls -la *optimization-backup-*

   # Restore from backup (adjust path as needed)
   backup_dir=$(cat .last_optimization_backup)
   cp "$backup_dir/zshrc.bak" ~/.zshrc
   cp "$backup_dir/claude.json.bak" ~/.claude.json
   sudo cp "$backup_dir/nix.conf.bak" /etc/nix/nix.conf

   # Restart affected services
   sudo launchctl kickstart -k system/org.nixos.nix-daemon
   source ~/.zshrc
   ```

2. **Run optimization in dry-run mode first:**
   ```bash
   ./scripts/optimize.sh --dry-run --profile balanced
   ```

3. **Use conservative profile:**
   ```bash
   ./scripts/optimize.sh --profile conservative --verbose
   ```

### Claude Configuration Issues

**Problem:** Claude optimizations not applying or causing errors.

**Solutions:**
1. **Reset Claude configuration:**
   ```bash
   # Backup current config
   cp ~/.claude.json ~/.claude.json.backup

   # Reset to defaults
   claude config reset

   # Re-apply optimizations
   ./claude-conf-optimized.sh --profile personal
   ```

2. **Profile-specific issues:**
   ```bash
   # Try different profile
   ./claude-conf-optimized.sh --profile prod --dry-run

   # Check profile validation
   CLAUDE_PROFILE=dev ./claude-conf-optimized.sh --dry-run
   ```

### Shell Performance Issues

**Problem:** Shell startup is slow after optimization.

**Solutions:**
1. **Profile shell startup:**
   ```bash
   # Add to .zshrc temporarily
   zmodload zsh/zprof
   # ... restart shell ...
   zprof  # See timing breakdown
   ```

2. **Check for problematic plugins:**
   ```bash
   # Disable Oh-My-Zsh plugins temporarily
   mv ~/.oh-my-zsh ~/.oh-my-zsh.disabled
   # Test startup time
   time zsh -i -c exit
   ```

3. **Optimize lazy loading:**
   ```bash
   # Check if version managers are using lazy loading
   grep -E "(nvm|rbenv|pyenv)" ~/.zshrc
   ```

### Nix Configuration Problems

**Problem:** Nix operations slow or failing after optimization.

**Solutions:**
1. **Check Nix configuration syntax:**
   ```bash
   sudo nix show-config
   # Look for any error messages
   ```

2. **Restore default Nix config:**
   ```bash
   sudo cp /etc/nix/nix.conf /etc/nix/nix.conf.backup
   sudo tee /etc/nix/nix.conf << EOF
   experimental-features = nix-command flakes
   EOF
   sudo launchctl kickstart -k system/org.nixos.nix-daemon
   ```

3. **Check disk space and store health:**
   ```bash
   df -h /nix
   nix store verify --all
   ```

## Performance Monitoring

### Continuous Performance Tracking

**Set up monitoring:**
```bash
# Create performance baseline
./shell-performance-benchmark.sh > baseline_$(date +%Y%m%d).txt

# Schedule regular benchmarks
echo "0 6 * * 1 cd $(pwd) && ./shell-performance-benchmark.sh > weekly_benchmark_\$(date +\%Y\%m\%d).txt" | crontab -
```

### Performance Regression Detection

**Check for regressions:**
```bash
# Compare current performance to baseline
./scripts/performance-compare.sh baseline_20250714.txt

# Monitor resource usage
top -l 1 | head -20
vm_stat
```

### Memory Usage Issues

**Problem:** High memory usage after optimizations.

**Solutions:**
1. **Check memory hogs:**
   ```bash
   ps aux | sort -k 4 -nr | head -10
   ```

2. **Clear caches aggressively:**
   ```bash
   sudo purge
   ./scripts/cleanup.sh --cache-retention 0
   ```

3. **Adjust Nix settings:**
   ```bash
   # Reduce parallel builds
   echo "max-jobs = 2" | sudo tee -a /etc/nix/nix.conf
   ```

## Maintenance Automation

### Automated Health Checks

**Set up monitoring scripts:**
```bash
# Daily health check
echo "0 2 * * * cd $(pwd) && ./scripts/health-check.sh --alert" | crontab -

# Weekly cleanup
echo "0 3 * * 0 cd $(pwd) && ./scripts/cleanup.sh" | crontab -

# Monthly optimization review
echo "0 1 1 * * cd $(pwd) && ./scripts/optimize.sh --dry-run --profile balanced" | crontab -
```

### Log Monitoring

**Check system logs for issues:**
```bash
# Recent errors
sudo log show --predicate 'eventMessage contains "error"' --last 1h

# Nix-specific logs
sudo log show --predicate 'process == "nix-daemon"' --last 1h

# Performance-related logs
sudo log show --predicate 'eventMessage contains "performance"' --last 24h
```

## Emergency Recovery

### Complete System Reset

**If optimizations cause major issues:**

1. **Safe mode boot:** Hold Shift during startup
2. **Reset configurations:**
   ```bash
   # Reset shell config
   cp /etc/zshrc ~/.zshrc

   # Reset Nix config
   sudo rm /etc/nix/nix.conf
   sudo /nix/var/nix/profiles/default/bin/nix-env --install nix

   # Reset Claude config
   rm ~/.claude.json
   ```

3. **Reinstall if necessary:**
   ```bash
   # Reinstall nix-darwin
   darwin-rebuild switch --flake .#Lars-MacBook-Air
   ```

### Data Recovery

**Recover important data:**
```bash
# Find all backup directories
find . -name "*backup*" -type d

# List recent backups
ls -la *optimization-backup-*

# Check git history for configuration changes
git log --oneline --since="1 week ago" -- dotfiles/ scripts/
```

## Preventive Measures

1. **Regular maintenance:**
   ```bash
   # Weekly cleanup
   ./scripts/cleanup.sh --backup-retention 30
   nix-collect-garbage -d
   brew cleanup

   # Monthly updates
   nix flake update
   darwin-rebuild switch --flake .#Lars-MacBook-Air

   # Quarterly optimization review
   ./scripts/optimize.sh --dry-run --profile balanced
   ```

2. **Backup important configs:**
   - This entire repository
   - SSH keys (backed up via Secretive)
   - Application settings not managed by Nix
   - Performance baselines and benchmarks

3. **Test changes:**
   ```bash
   # Always test before applying
   nix flake check
   darwin-rebuild check --flake .#Lars-MacBook-Air
   ./scripts/optimize.sh --dry-run
   ```

4. **Monitor performance:**
   ```bash
   # Create performance baselines
   ./shell-performance-benchmark.sh > performance_baseline.txt

   # Regular performance checks
   ./scripts/health-check.sh --comprehensive
   ```