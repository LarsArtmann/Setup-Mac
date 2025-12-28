# Nix Reinstall Plan

## Current Problem
- Multiple Nix versions (2.31.2 and 2.26.1) in store
- Build commands fail silently
- Caches corrupted

## Reinstall Steps

### Option 1: Full Reinstall (Recommended)
```bash
# 1. Backup current configuration
cd ~/Desktop/Setup-Mac
git add . && git commit -m "Backup before nix reinstall"

# 2. Uninstall nix-darwin
sudo rm -rf /etc/static/bashrc-nix-daemon.sh
sudo rm -rf /etc/static/zshrc-nix-daemon.sh
sudo rm -rf /run/current-system

# 3. Use official installer
curl -L https://nixos.org/nix/install | sh

# 4. Rebuild from configuration
cd ~/Desktop/Setup-Mac
nix build .#darwinConfigurations.Lars-MacBook-Air.config.system.build.toplevel
sudo ./result/activate
```

### Option 2: Selective Cleanup (Less Risk)
```bash
# Remove only old nix version references
nix-store --gc --delete-older-than 90d

# Force garbage collection
nix-collect-garbage -d

# Try building again
just switch
```

## Which to Choose?

- **Use Option 1** if you want completely clean Nix installation
- **Use Option 2** if you want to try fixing current installation first

## Before Reinstalling

1. Commit all configuration changes:
   ```bash
   cd ~/Desktop/Setup-Mac
   git status
   git add .
   git commit -m "Pre-reinstall backup"
   ```

2. Note current working packages:
   ```bash
   ls /run/current-system/sw/bin
   ```

3. Document any custom configurations that might be lost
