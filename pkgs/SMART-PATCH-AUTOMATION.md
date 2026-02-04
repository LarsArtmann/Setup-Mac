# Smart Crush-Patch Automation

## Overview

The `update-crush-patched-smart.sh` script automatically manages patches for the `crush-patched` package by checking GitHub API to see which PRs are already merged into a given version.

## Problem It Solves

**Before**: Manual patch list management
- Manually check each PR's merge status
- Manually remove patches that are already in release
- Build fails when trying to apply merged PRs
- Wastes time investigating patch conflicts

**After**: Automated intelligent patch management
- Automatically checks PR status via GitHub API
- Compares merge date with release date
- Only includes patches that are NOT in the release
- Generates clean, working Nix file

## How It Works

### 1. Version Comparison
```bash
Current: v0.39.1
Latest:  v0.40.0
```
If versions match → Exit (nothing to do)

### 2. PR Status Check

For each patch defined in the script:

| PR # | Status | Merge Date | Release Date | Action |
|-------|--------|------------|--------------|--------|
| 1854 | merged | 2025-12-10 | 2026-02-15 | SKIP ✅ |
| 2068 | merged | 2026-02-02 | 2026-02-04 | SKIP ✅ |
| 2019 | open | - | 2026-02-15 | APPLY 📝 |
| 2070 | merged | 2026-02-20 | 2026-02-15 | APPLY 📝 |

**Logic**:
- If PR is **OPEN** → Apply patch (not in any release yet)
- If PR is **MERGED BEFORE** release date → Skip (already in release tarball)
- If PR is **MERGED AFTER** release date → Apply patch (not in our version yet)

### 3. Nix File Generation

Script generates `pkgs/crush-patched.nix` with:
- Correct version
- Prefetched source hash
- Only needed patches (filtered by version)
- Proper Nix syntax

## Usage

### Update to latest version:
```bash
cd pkgs
bash update-crush-patched-smart.sh
```

### Review changes:
```bash
git diff pkgs/crush-patched.nix
```

### Test build:
```bash
nix build .#crush-patched
```

### Update vendorHash if needed:
```bash
# Build will show error with correct hash
# Copy hash into crush-patched.nix vendorHash line
```

### Apply changes:
```bash
git add pkgs/crush-patched.nix
git commit -m "feat(crush): update to v0.XX.Y"
git push
```

## Adding New Patches

To add a new patch to track:

1. Open `pkgs/update-crush-patched-smart.sh`
2. Add to the `PATCHES` array at top:
   ```bash
   PATCHES=(
     "NEW_PR_NUMBER:SHA256:MERGE_COMMIT_SHA"
     # ... existing patches
   )
   ```
3. Save and run the script

## Removing Patches

To stop tracking a patch:

1. Remove from `PATCHES` array in `pkgs/update-crush-patched-smart.sh`
2. Run the script
3. If PR is merged, script will auto-skip it anyway

## Technical Details

### GitHub API Queries

**PR Info**:
```bash
curl -s "https://api.github.com/repos/charmbracelet/crush/pulls/{PR_NUM}"
```

**Release Info**:
```bash
curl -s "https://api.github.com/repos/charmbracelet/crush/releases/tags/{VERSION}"
```

### Date Comparison

Python datetime comparison:
```python
from datetime import datetime
merged = datetime.strptime(MERGED_AT, '%Y-%m-%dT%H:%M:%SZ')
release = datetime.strptime(RELEASE_DATE, '%Y-%m-%dT%H:%M:%SZ')
# Returns True if merged < release (meaning PR is IN release)
print(1 if merged < release else 0)
```

## Workflow Integration

Recommended to integrate into `justfile`:

```makefile
update:
    @echo "🔄 Updating Nix flake..."
    @nix flake update
    @echo "✅ Nix flake updated"
    @echo ""
    @echo "📡 Updating crush-patched to latest version..."
    @./pkgs/update-crush-patched-smart.sh || echo "⚠️  crush-patched update skipped (manual intervention needed)"
    @echo "✅ System updated"
    @echo ""
    @echo "💡 Next steps:"
    @echo "   - Run 'just switch' to apply changes"
```

## Troubleshooting

### Script shows "Already up to date!" but you want to force update:
- Edit `pkgs/crush-patched.nix` manually
- Or temporarily change version check in script

### Build fails with "cannot apply patch":
- Check if patch PR was recently merged
- Manually remove from PATCHES array
- Re-run script

### GitHub API rate limit:
- Wait a few minutes before retrying
- Script handles failures gracefully

## Benefits

1. **Time saving**: No more manual PR research
2. **Error prevention**: Catches conflicts before full build
3. **Maintenance**: Easy to add/remove tracked patches
4. **Reliability**: Source of truth is GitHub API
5. **Documentation**: Clear why each patch is included/skipped

## Future Improvements

- [ ] Pre-build patch validation (dry-run patch -p1)
- [ ] Conflict detection and resolution suggestions
- [ ] Automated PR monitoring (new PRs from repos you follow)
- [ ] Patch dependency tracking (PRs that require others)
- [ ] Rollback capability if new version breaks
