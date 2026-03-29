# SystemNix - TODO List

**Last Updated**: 2026-03-29
**Status**: Active

---

## Summary

| Category | Count |
|----------|-------|
| **Actionable TODOs** | 3 |
| **Documentation placeholders** | 1 |
| **External/Non-actionable** | 2 |

---

## Actionable TODOs (3)

### 1. Re-enable Audit Daemon (NixOS)

**File**: `platforms/nixos/desktop/security-hardening.nix`
**Line**: 14
**Priority**: MEDIUM
**Category**: Security
**Blocked by**: Upstream NixOS bug

```nix
# TODO: Re-enable after NixOS resolves the audit-rules service bug
```

**Context**:
- Audit daemon disabled due to AppArmor conflicts
- NixOS 26.05 (Jan 2026) has bug where `audit-rules-nixos.service` fails with "No rules" error
- Issue: https://github.com/NixOS/nixpkgs/issues/483085

**Action**: Monitor upstream issue and re-enable once resolved.

---

### 2. Re-enable Audit Kernel Module (NixOS)

**File**: `platforms/nixos/desktop/security-hardening.nix`
**Line**: 21
**Priority**: MEDIUM
**Category**: Security
**Blocked by**: AppArmor conflicts

```nix
# TODO: Re-enable after fixing audit kernel module (AppArmor conflicts)
```

**Context**: Audit rules configuration disabled due to AppArmor conflicts with audit kernel module.

**Action**: Research and resolve AppArmor/audit compatibility, then re-enable.

---

### 3. Update Home Manager Issue Reference (Darwin)

**File**: `platforms/darwin/default.nix`
**Line**: 85
**Priority**: LOW
**Category**: Documentation

```nix
# See: https://github.com/nix-community/home-manager/issues/XXXX
```

**Context**: Placeholder XXXX should be replaced with actual GitHub issue number for the Home Manager + nix-darwin user definition workaround.

**Action**: Find the relevant Home Manager GitHub issue and update the URL.

---

## Documentation Placeholders (1)

### .buildflow.yml TODO Comment

**File**: `.buildflow.yml`
**Line**: 15
**Type**: Configuration comment (not a task)

```yaml
# TODO comment severity: debug, info, warn, error
todo_severity: info
```

**Context**: This is explaining the `todo_severity` setting, not an actual TODO task. The comment describes what the setting does.

---

## External/Non-Actionable (2)

### Patch File TODOs (Upstream Code)

**File**: `patches/2019.patch`
**Lines**: 295, 862
**Type**: External patch (Crush upstream)
**Actionable**: NO - This is third-party code

```go
// TODO: when we support multiple agents we need to change this so that we pass in the agent specific model config
// TODO: remove the app instance from here
```

**Context**: These TODOs are in a patch file for the Crush CLI tool, not in this project's code. They're upstream issues to be handled by the Crush maintainers.

---

## Verification Commands

```bash
# Find all TODOs in source code (excluding patches and docs)
grep -rn "TODO\|FIXME\|XXX\|HACK" \
  --include="*.nix" --include="*.sh" \
  --include="*.py" --include="*.go" \
  --exclude-dir=.git --exclude-dir=.crush \
  --exclude-dir=patches \
  .

# Count actionable TODOs only
grep -rn "^\s*#.*TODO" \
  --include="*.nix" \
  --exclude-dir=patches \
  platforms/ 2>/dev/null | wc -l
```

---

## History

- **2026-03-29**: Comprehensive audit completed. Found only 3 actionable TODOs in actual source code.
- **2026-03-27**: Library policy implementation completed (paths.sh, consolidated nixpkgs config)
- **2026-02-10**: File organization completed (12 files moved to proper directories)

---

## Notes

- Previous counts of "445 TODOs" were misleading - included documentation TODOs and planning documents
- Shell scripts (62+ files): Zero TODOs found
- Python files: Zero TODOs found
- Go files (dnsblockd): Zero TODOs found
- Only Nix configuration files contain actionable TODOs
- Patch files contain upstream TODOs that are not this project's responsibility
