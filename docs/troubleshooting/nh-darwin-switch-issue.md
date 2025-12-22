# nh darwin switch Issue and Solution

## Problem Description
The `nh darwin switch` command fails with errors:
- `$HOME ('/Users/larsartmann') is not owned by you, falling back to the one defined in the 'passwd' file ('/var/root')`
- `getting status of '/private/var/folders/.../nh-.../result': No such file or directory`

## Root Cause Analysis
The issue is caused by `nh` creating temporary files as the user but trying to access them when running with sudo. The temporary file context is lost when switching to sudo, causing the "No such file or directory" error. The HOME ownership warning is misleading - the real issue is file access context.

## Solution Options

### Option 1: Use `just switch` (RECOMMENDED)
```bash
just switch
```
This uses darwin-rebuild directly without the temporary file issue.

### Option 2: Use darwin-rebuild directly
```bash
sudo darwin-rebuild switch --flake ./
```

### Option 3: Update nh (if available)
Check if there's a newer version of nh that fixes this issue.

## Verification
- Configuration syntax is valid (verified with `just test-fast`)
- `just switch` command works (takes time to build the system)
- System health check passes: `just health` ✅
- This is a known issue with nh on macOS

## Notes
- The configuration itself is fine - the issue is with the nh tool
- `just switch` is the recommended approach for this project
- Consider adding a note to the documentation to use `just switch` instead of `nh darwin switch`

## Verification Commands Used
```bash
# Check system is working
ls -la /run/current-system

# Run health check
just health

# Test configuration syntax
just test-fast
```