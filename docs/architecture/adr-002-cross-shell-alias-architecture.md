# ADR-002: Cross-Shell Alias Architecture

**Status:** Accepted
**Date:** 2026-01-12
**Context:** Setup-Mac Configuration System

## Problem

User's `l` alias was defined for Fish shell but not available in Zsh, causing
confusion and inconsistent behavior across shells. The original architecture:

- ✅ Fish aliases: Defined in `platforms/common/programs/fish.nix`
- ❌ Zsh aliases: Not defined
- ❌ Bash aliases: Not defined

**User Impact:**
- `l` alias works in Fish
- `l` alias doesn't work in Zsh (default macOS shell)
- User confused why alias not available
- Manual alias duplication would be required

## Decision

Implement unified cross-shell alias architecture with proper separation of concerns:

**Architecture:**
```
platforms/common/programs/
├── fish.nix      # Common Fish aliases + init
├── zsh.nix       # Common Zsh aliases + config
└── [bash.nix]     # Future: Common Bash aliases

platforms/darwin/programs/
└── shells.nix     # Platform-specific overrides (lib.mkAfter)
                    # Fish + Zsh + Bash Darwin-specific aliases

platforms/darwin/home.nix
└── Imports shells.nix
```

**Pattern:**
1. **Common aliases** defined in `platforms/common/programs/{fish,zsh}.nix`
2. **Platform overrides** added via `lib.mkAfter` in `platforms/{darwin,nixos}/programs/shells.nix`
3. **Home Manager** automatically merges `shellAliases` using `lib.mkAfter`

**Key Benefits:**
- ✅ Single source of truth (no duplication)
- ✅ Common aliases shared across all shells
- ✅ Platform-specific aliases cleanly separated
- ✅ Consistent user experience across Fish, Zsh, Bash

## Implementation

### Common Aliases (All Shells)

**File:** `platforms/common/programs/{fish,zsh}.nix`

```nix
programs.{fish,zsh}.shellAliases = {
  l = "ls -laSh";
  t = "tree -h -L 2 -C --dirsfirst";
};
```

### Darwin-Specific Aliases

**File:** `platforms/darwin/programs/shells.nix`

```nix
programs.{fish,zsh}.shellAliases = lib.mkAfter {
  nixup = "darwin-rebuild switch --flake .";
  nixbuild = "darwin-rebuild build --flake .";
  nixcheck = "darwin-rebuild check --flake .";
};
```

**How it works:**
- Home Manager's `lib.mkAfter` merges common + platform aliases
- Common aliases defined first
- Platform-specific aliases override or add to common list
- Platform-specific commands (nixup, etc.) only on Darwin

### Shell-Specific Initialization

**Fish:**
- `interactiveShellInit` for Fish-specific settings
- Carapace completions integration (Fish-only)
- Starship prompt integration

**Zsh:**
- `initContent` for Zsh-specific settings
- Homebrew integration (Darwin-only)
- Carapace completions integration (Zsh-only)
- Starship prompt integration (auto)

## Validation

**Testing Requirements:**
1. ✅ Nix configuration builds without errors
2. ✅ Home Manager applies configuration
3. ✅ Fish aliases defined in interactive shell
4. ✅ Zsh aliases defined in config
5. ✅ Platform aliases override common aliases correctly

**Verification Commands:**

```bash
# Zsh verification
source ~/.config/zsh/.zshrc
type l    # Should show alias -- l='ls -laSh'

# Fish verification (requires interactive shell)
fish -i -c 'type l'    # Should show function definition
```

## Consequences

**Positive:**
- ✅ Consistent aliases across all shells
- ✅ No code duplication
- ✅ Easy to add new common aliases
- ✅ Platform-specific aliases cleanly separated
- ✅ Follows Home Manager best practices

**Negative:**
- ⚠️  Requires maintaining multiple shell config files
- ⚠️  Platform-specific files need updates per platform
- ⚠️  Interactive vs non-interactive shell behavior differences

## References

- [Home Manager: Fish](https://nix-community.github.io/home-manager/options.html#opt-programs.fish.shellAliases)
- [Home Manager: Zsh](https://nix-community.github.io/home-manager/options.html#opt-programs.zsh.shellAliases)
- [Home Manager: lib.mkAfter](https://nix-community.github.io/home-manager/options.html#opt-promsfsh.interactiveshllnit)
- [ADR-001: Home Manager for Darwin](./adr-001-home-manager-for-darwin.md)

## Alternatives Considered

### Alternative 1: Single Alias Module
Define all shell aliases in single file, import into all shells.

**Rejected:**
- ❌ Can't use `lib.mkAfter` pattern
- ❌ All shells would get all platform-specific aliases
- ❌ Would add Zix-specific aliases to Fish unnecessarily

### Alternative 2: Shell-Agnostic Alias System
Create custom alias system outside Home Manager.

**Rejected:**
- ❌ Breaks Home Manager declarative model
- ❌ Manual alias management required
- ❌ Not reproducible across machines

### Alternative 3: NixOS-style Configuration
Use NixOS-style modules with custom options.

**Rejected:**
- ❌ Over-engineering for simple use case
- ❌ Home Manager provides built-in `shellAliases` option
- ❌ Requires writing custom NixOS modules

## Future Improvements

### TODO: Bash Shell Support

**Status:** Not Implemented

**Required Changes:**
1. Add `platforms/common/programs/bash.nix`
2. Define common aliases in Bash config
3. Add Bash overrides in `platforms/darwin/programs/shells.nix`
4. Update `platforms/nixos/users/home.nix` for NixOS Bash overrides

**Priority:** Medium

### TODO: NixOS Parity

**Status:** Partially Implemented

**Required Changes:**
1. Create `platforms/nixos/programs/shells.nix`
2. Add NixOS-specific aliases (nixos-rebuild instead of darwin-rebuild)
3. Test NixOS configuration build

**Priority:** High

### TODO: Automated Testing

**Status:** Not Implemented

**Requirements:**
- Automated shell configuration tests
- Verify alias definitions in generated configs
- Test interactive shell startup
- Performance benchmarking for shell loading

**Priority:** Medium

## Related

- [Commit 89f0b41: feat(shells): implement cross-platform alias architecture](https://github.com/user/repo/commit/89f0b41)
- [Issue: Cross-shell alias support](https://github.com/user/repo/issues/XXX)
- [ADR-001: Home Manager for Darwin](./adr-001-home-manager-for-darwin.md)
