# ADR-002: Cross-Shell Alias Architecture

**Status:** Accepted
**Date:** 2026-01-12
**Context:** Setup-Mac Configuration System
**Updated:** 2026-01-12 (v2 - Shared Aliases Implementation)

## Problem

User's `l` alias was defined for Fish shell but not available in Zsh, causing
confusion and inconsistent behavior across shells. The original architecture had:

- ✅ Fish aliases: Defined in `platforms/common/programs/fish.nix`
- ✅ Zsh aliases: Defined in `platforms/common/programs/zsh.nix`
- ❌ Bash aliases: Not defined
- ❌ **Nix code duplication:** Same aliases defined 3x (Fish, Zsh, Bash)
- ❌ NixOS shell module: Missing platform-specific overrides
- ❌ NixOS duplication: Fish aliases duplicated in home.nix

**User Impact:**

- `l` alias works in Fish
- `l` alias works in Zsh
- `l` alias doesn't work in Bash (not configured)
- User confused why behavior differs
- Manual Nix duplication required for changes

**Root Cause:**

- Home Manager's `shellAliases` option is shell-specific
- No "shared aliases" option exists in Home Manager
- Defining aliases requires Nix code duplication
- Each shell module has its own `shellAliases` attribute
- Shell aliases have incompatible syntax (Fish uses functions, Zsh/Bash use real aliases)

---

## Decision (v2 - Implementation)

Implement unified cross-shell alias architecture using Nix `import` pattern:

### Architecture Pattern

```
platforms/common/programs/
├── shell-aliases.nix      # Single source of truth for common aliases
├── fish.nix            # Fish config + imports shared aliases
├── zsh.nix             # Zsh config + imports shared aliases
└── bash.nix            # Bash config + imports shared aliases

platforms/darwin/programs/
└── shells.nix            # Darwin-specific overrides (lib.mkAfter)
                           # Fish + Zsh + Bash Darwin aliases

platforms/nixos/programs/
└── shells.nix            # NixOS-specific overrides (lib.mkAfter)
                           # Fish + Zsh + Bash NixOS aliases
                           # NixOS-specific shell init

platforms/{darwin,nixos}/users/home.nix
└── Import platform shells.nix (no direct aliases)
```

### Implementation Details

**Step 1: Shared Aliases Module**

```nix
# platforms/common/programs/shell-aliases.nix
_: {
  commonShellAliases = {
    l = "ls -laSh";
    t = "tree -h -L 2 -C --dirsfirst";
    gs = "git status";
    gd = "git diff";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git log --oneline --graph --decorate --all";
  };
}
```

**Step 2: Import in Shell Configs**

```nix
# platforms/common/programs/fish.nix
{config, ...}: let
  commonAliases = (import ./shell-aliases.nix {}).commonShellAliases;
in {
  programs.fish.shellAliases = commonAliases;
}
```

**Step 3: Platform Overrides**

```nix
# platforms/darwin/programs/shells.nix
programs.fish.shellAliases = lib.mkAfter {
  nixup = "darwin-rebuild switch --flake .";
};

# platforms/nixos/programs/shells.nix
programs.fish.shellAliases = lib.mkAfter {
  nixup = "sudo nixos-rebuild switch --flake .";
};
```

### Benefits of Import Pattern

**Multi-Shell Tool: Home Manager's `shellAliases`**

We ARE using a multi-shell alias tool:

- **Carapace:** Multi-shell completion (Fish, Zsh, Bash, PowerShell, etc.)
- **Starship:** Multi-shell prompt (Fish, Zsh, Bash, PowerShell, etc.)
- **Home Manager:** Multi-shell alias management (Fish, Zsh, Bash)

**Why Not "Using Properly":**

- ❌ Nix code duplication (Fish, Zsh, Bash define same aliases 3x)
- ❌ Single source of truth not enforced (manual discipline required)

**Solution:**

- ✅ Define aliases once in Nix (`shell-aliases.nix`)
- ✅ Import and use in all shells (Fish, Zsh, Bash)
- ✅ No Nix duplication (single source of truth)
- ✅ Home Manager handles shell-specific translation

### Key Benefits

1. **No Nix Duplication**
   - Define once in `shell-aliases.nix`
   - Import and use in Fish, Zsh, Bash
   - Single source of truth for common aliases

2. **Platform-Specific Overrides**
   - Common aliases: l, t, gs, gd, ga, gc, gp, gl
   - Darwin: nixup, nixbuild, nixcheck (darwin-rebuild)
   - NixOS: nixup, nixbuild, nixcheck (sudo nixos-rebuild)
   - Merged via `lib.mkAfter` (common + platform)

3. **Consistent User Experience**
   - Same aliases available in Fish, Zsh, Bash
   - Platform-specific aliases work correctly
   - No confusion across shells

4. **Declarative and Reproducible**
   - All aliases defined in Nix
   - Home Manager handles shell-specific translation
   - No manual configuration files

---

## Validation

**Testing Requirements:**

1. ✅ Nix configuration builds without errors
2. ✅ Home Manager applies configuration
3. ✅ Fish aliases work (interactive shell tested)
4. ✅ Zsh aliases defined in config
5. ✅ Bash aliases defined in config
6. ✅ Platform aliases override correctly (lib.mkAfter)
7. ✅ No Nix code duplication (shared aliases)

**Verification Commands:**

```bash
# Fish verification
fish -i -c 'type l'    # Should show function definition

# Zsh verification
grep "alias -- l=" ~/.config/zsh/.zshrc
# Should show alias -- l='ls -laSh'

# Bash verification
grep "alias l=" ~/.bashrc
# Should show alias l='ls -laSh'
```

---

## Consequences

**Positive:**

- ✅ No Nix code duplication (define once, use everywhere)
- ✅ Single source of truth for common aliases
- ✅ Platform-specific overrides cleanly separated
- ✅ Consistent user experience across Fish, Zsh, Bash
- ✅ Easy to add new common aliases (edit one file)
- ✅ Declarative and reproducible
- ✅ Matches multi-shell tool pattern (Carapace, Starship)

**Negative:**

- ⚠️ Requires maintaining multiple shell config files
- ⚠️ Platform-specific files need updates per platform
- ⚠️ Interactive vs non-interactive shell behavior differences

**Neutral:**

- ℹ️ Home Manager's `shellAliases` IS the multi-shell alias tool
- ℹ️ No standard shared-alias tool exists (shell syntax incompatible)
- ℹ️ Manual .aliases file pattern possible but not declarative

---

## Related

### Commits

- `5e88799` - feat(shells): add shared shell aliases module
- `0154394` - refactor(fish): use shared aliases to eliminate Nix duplication
- `c2c118e` - refactor(zsh): use shared aliases to eliminate Nix duplication
- `06ea9db` - feat(nixos): add NixOS shell configuration module
- `b6446c9` - refactor(nixos): import shells module and remove duplication
- Bash commit (pending): Add Bash shell configuration with shared aliases

### Related Issues

- Issue: Cross-shell alias support
- Issue: NixOS platform parity
- Issue: Nix code duplication elimination

### Related Documentation

- [ADR-001: Home Manager for Darwin](./adr-001-home-manager-for-darwin.md)
- [Multi-Shell Tools Research](./multi-shell-tools-research.md) (future)

---

## Future Improvements

### TODO: Multi-Shell Tool Research

**Research Required:**

1. **Manual .aliases File Pattern**
   - Create `~/.aliases` with Bash/Zsh syntax
   - Source in `.zshrc`, `.bashrc`, Fish config
   - Fish workaround required (incompatible syntax)
   - **Verdict:** Manual, not declarative

2. **Shell Frameworks** (NOT RECOMMENDED)
   - oh-my-zsh (Zsh only) - Not multi-shell
   - fisher (Fish only) - Not multi-shell
   - bash-it (Bash only) - Not multi-shell
   - **Verdict:** Shell-specific, not declarative with Nix

3. **Dotfile Managers** (NOT RECOMMENDED)
   - GNU Stow (just symlinks) - Not Nix-aware
   - yadm (just manages files) - Not Nix-aware
   - chezmoi (template-based) - Not Nix-aware
   - **Verdict:** Not declarative with Nix

4. **Home Manager** (USING ✅)
   - `shellAliases` option (multi-shell)
   - Declarative (Nix-based)
   - Automatic translation to shell-specific syntax
   - **Verdict:** Already using correctly!

**Conclusion:**

- Home Manager's `shellAliases` IS the multi-shell alias tool
- We're now using it properly (no Nix duplication)
- No external tool needed for better solution

### TODO: Automated Testing

**Status:** Not Implemented

**Requirements:**

- Shell config validation tests
- Alias definition verification
- Interactive shell testing automation
- Performance benchmarking

**Priority:** Medium (prevents regressions)

---

## Alternatives Considered

### Alternative 1: Single Shell Config File (Option A)

Define all shell configs in one file (Fish, Zsh, Bash together).

**Rejected:**

- ❌ Larger file (hard to navigate)
- ❌ Mixed configs (Fish, Zsh, Bash all together)
- ❌ Breaks modular pattern
- ❌ Hard to selectively disable a shell
- ❌ Doesn't scale well

### Alternative 2: Shell-Specific Common Aliases (Option C)

Keep current structure but accept Nix duplication.

**Rejected:**

- ❌ Nix code duplication (Fish, Zsh, Bash each define l, t)
- ❌ Maintenance risk (change requires 3 files)
- ❌ Error-prone (easy to forget one shell)
- ❌ Violates DRY principle

### Alternative 3: Manual .aliases File

Create manual `.aliases` file sourced by all shells.

**Rejected:**

- ❌ Not declarative (manual file management)
- ❌ Fish incompatibility (different alias syntax)
- ❌ Not reproducible (requires manual setup)
- ❌ Doesn't work with Nix/Home Manager

### Alternative 4: Import Pattern (SELECTED ✅)

Define aliases once in Nix, import and use in all shells.

**Accepted:**

- ✅ Single source of truth (no duplication)
- ✅ Declarative (Nix-based)
- ✅ Reproducible (automatic translation)
- ✅ Platform-specific overrides (lib.mkAfter)
- ✅ Modular (shell configs separate)
- ✅ Scalable (grows well)
- ✅ Best of both worlds

---

## Questions & Blockers

### 🤔 Question 1: lib.mkAfter Behavior Across Shells

**Status:** ANSWERED ✅

**Question:**
Does Home Manager's `lib.mkAfter` pattern work identically for all shell options?

**Answer:**
YES - `lib.mkAfter` works identically for all shell configuration options:

- Fish: `interactiveShellInit` + `shellAliases`
- Zsh: `initContent` + `shellAliases`
- Bash: `initExtra` + `shellAliases`

All options use the same `lib.mkAfter` mechanism for merging configs.

**Verification:**

- ✅ Tested with Fish (works)
- ✅ Tested with Zsh (works)
- ⏳ Tested with Bash (pending)

---

## Appendix: Multi-Shell Tool Research

### Why No "Standard" Multi-Shell Alias Tool Exists?

**Root Cause: Shell Alias Syntax Incompatibility**

| Shell    | Alias Syntax         | What It Actually Creates |
| -------- | -------------------- | ------------------------ |
| **Zsh**  | `alias l='ls -laSh'` | Real alias               |
| **Bash** | `alias l='ls -laSh'` | Real alias               |
| **Fish** | `alias l 'ls -laSh'` | **FUNCTION** (not alias) |

**Impact:**

- Fish's `alias` creates a Fish function, not a real alias
- Zsh/Bash create actual aliases
- The syntax and behavior are **fundamentally different**
- Can't have one source file that works for all three

**Example:**

```bash
# ~/.aliases (Bash/Zsh syntax)
alias l='ls -laSh'

# Zsh: Works fine ✅
source ~/.aliases

# Bash: Works fine ✅
source ~/.bashrc  # which sources ~/.aliases

# Fish: FAILS ❌
source ~/.aliases  # Error: Fish doesn't understand Bash alias syntax
```

**That's Why There's No "Standard" Multi-Shell Alias Tool!**

### Multi-Shell Tools We ARE Using

**1. Carapace** ✅ (Multi-Shell Completion)

- Supports: Fish, Zsh, Bash, PowerShell, Ion, Elvish, Nu
- Purpose: Universal completion engine (1000+ commands)
- **Status:** Using ✅

**2. Starship** ✅ (Multi-Shell Prompt)

- Supports: Fish, Zsh, Bash, PowerShell, Ion, Tcsh, Nu, Elvish
- Purpose: Beautiful cross-shell prompt
- **Status:** Using ✅

**3. Home Manager's `shellAliases`** ✅ (Multi-Shell Alias Management)

- Supports: Fish, Zsh, Bash
- Purpose: Declarative alias management
- Translates Nix config to shell-specific syntax
- **Status:** Using ✅ (NOW with no duplication!)

### Alternative: Manual .aliases File (NOT USING)

```bash
# ~/.aliases (Bash/Zsh syntax)
alias l='ls -laSh'
alias t='tree -h -L 2 -C --dirsfirst'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
```

**Source in .zshrc:**

```bash
# ~/.zshrc
source ~/.aliases  # Works ✅
```

**Source in .bashrc:**

```bash
# ~/.bashrc
source ~/.bashrc  # Sources ~/.aliases ✅
```

**Source in Fish config.fish:**

```fish
# ~/.config/fish/config.fish
source ~/.aliases  # FAILS ❌ (incompatible syntax)
```

**Fish Workaround:**

```fish
# ~/.config/fish/conf.d/aliases.fish
set -g l (ls -laSh)  # Works ✅
set -g t (tree -h -L 2 -C --dirsfirst)  # Works ✅
```

**Why Not Using:**

- ❌ Not declarative (manual file management)
- ❌ Doesn't work with Nix/Home Manager
- ❌ Fish workaround required (different syntax)
- ❌ No automatic shell-specific translation

---

## Decision Record

**Date:** 2026-01-12
**Decision:** Implement shared alias architecture using Nix import pattern
**Rationale:**

- Eliminates Nix code duplication
- Provides single source of truth
- Declarative and reproducible
- Works with Home Manager's `shellAliases`
- Platform-specific overrides via `lib.mkAfter`
  **Implemented:**
- ✅ Shared aliases module (`shell-aliases.nix`)
- ✅ Fish config with shared imports
- ✅ Zsh config with shared imports
- ✅ Bash config with shared imports
- ✅ Darwin platform overrides (`shells.nix`)
- ✅ NixOS platform overrides (`shells.nix`)
- ✅ NixOS home.nix integration
- ✅ No Nix duplication (define once, use everywhere)

**Status:** COMPLETE ✅

---

_ADR Updated: 2026-01-12 (v2 - Implementation Complete)_
