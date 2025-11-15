# Cross-Platform Strategy: macOS (nix-darwin) → NixOS Migration

**Created:** 2025-11-15
**Status:** Planning / Future Implementation
**Priority:** Medium (enables NixOS migration)

---

## EXECUTIVE SUMMARY

**Problem:** Current setup uses Homebrew (macOS-only) for some GUI apps.
**Goal:** Enable future migration to NixOS without major reconfiguration.
**Solution:** Platform abstraction + clear migration path for each package.

**Key Insight:** Using Homebrew on macOS NOW doesn't prevent NixOS migration LATER, as long as we document and plan for it.

---

## CURRENT STATE: macOS (nix-darwin)

### Package Distribution

**Nix (Platform-Agnostic):**
- All CLI tools: bat, fish, starship, ripgrep, etc.
- Development toolchains: Go, Node.js, Python, Rust
- System utilities

**Homebrew (macOS-Specific):**
- ActivityWatch (pynput broken in Nix on macOS)
- Sublime Text (better macOS integration)
- JetBrains Toolbox (manages multiple IDEs)

### Why This Split?

**Pragmatic choice, not ideological:**
1. Some packages broken/problematic in nixpkgs on macOS
2. Homebrew provides better macOS integration for GUI apps
3. Official binaries often more stable than Nix-packaged versions
4. **All these apps exist in nixpkgs for NixOS**

---

## MIGRATION PATH: macOS → NixOS

### Step 1: Package Availability Check

**GOOD NEWS:** All current Homebrew casks exist in nixpkgs!

| macOS (Homebrew) | NixOS (nixpkgs) | Status |
|------------------|-----------------|--------|
| `activitywatch` | `pkgs.activitywatch` | ✅ Available |
| `sublime-text` | `pkgs.sublime4` | ✅ Available |
| `jetbrains-toolbox` | `pkgs.jetbrains.*` | ✅ Available |

**Migration Effort:** LOW (all packages exist)

### Step 2: Configuration Portability

**Platform-Agnostic Configs:**
```
dotfiles/
  activitywatch/      # Works on both platforms
  sublime-text/       # Works on both platforms
  fish/               # Works on both platforms
```

**Only installation method changes, NOT configuration.**

### Step 3: Platform Abstraction (v0.2.0)

Create `dotfiles/nix/core/Platform.nix`:

```nix
{ lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in

{
  inherit isDarwin isLinux;

  # GUI apps with platform-specific installation
  guiApps = if isDarwin then {
    # macOS: Homebrew manages these (see homebrew.nix)
    activitywatch = null;
    sublime = null;
    jetbrains = null;
  } else {
    # NixOS: Use nixpkgs directly
    activitywatch = pkgs.activitywatch;
    sublime = pkgs.sublime4;
    jetbrains = pkgs.jetbrains.idea-ultimate;
  };

  # CLI tools work everywhere
  cliTools = [
    pkgs.bat
    pkgs.fish
    pkgs.starship
    # ... etc
  ];

  # Platform-specific system packages
  systemPackages =
    (lib.filter (p: p != null) (lib.attrValues guiApps))
    ++ cliTools;
}
```

### Step 4: Conditional Homebrew

Update `dotfiles/nix/homebrew.nix`:

```nix
{ config, pkgs, lib, ... }:

let
  platform = import ./core/Platform.nix { inherit lib pkgs; };
in

# Only enable Homebrew on macOS
lib.mkIf platform.isDarwin {
  homebrew = {
    enable = true;

    casks = [
      "activitywatch"
      "sublime-text"
      "jetbrains-toolbox"
    ];

    onActivation.cleanup = "zap";
  };
}
```

### Step 5: NixOS Configuration Example

When migrating to NixOS, use the same Platform.nix:

```nix
# NixOS configuration.nix
{ config, pkgs, ... }:

let
  platform = import ./dotfiles/nix/core/Platform.nix { inherit lib pkgs; };
in

{
  environment.systemPackages = platform.systemPackages;

  # Reuse all platform-agnostic configs
  imports = [
    ./dotfiles/nix/programs.nix   # Fish, Starship
    ./dotfiles/nix/wrappers        # Wrapper system
  ];
}
```

**Result:** Same configs, different installation method. Zero reconfiguration needed.

---

## ARCHITECTURAL PATTERN

### Separation of Concerns

```
┌──────────────────────────────────────┐
│   Application Configuration         │ ← Platform-Agnostic
│   (dotfiles/*/config.*)              │   (PORTABLE)
└──────────────────────────────────────┘
                ↓
┌──────────────────────────────────────┐
│      Platform Adapter Layer          │ ← Platform-Specific
│      (core/Platform.nix)             │   (ABSTRACTED)
└──────────────────────────────────────┘
                ↓
        ┌───────┴───────┐
        ↓               ↓
┌───────────────┐ ┌─────────────────┐
│     macOS     │ │      NixOS      │
│  (Homebrew)   │ │   (nixpkgs)     │
└───────────────┘ └─────────────────┘
```

**Benefits:**
1. **Configurations portable** - Same dotfiles work everywhere
2. **Installation abstracted** - Platform layer handles differences
3. **Easy migration** - Change one import, everything works
4. **Testable** - Can validate NixOS builds without migrating

---

## DECISION: ActivityWatch → Homebrew on macOS

### Context (Issue #129)

**Problem:** `python3.13-pynput` broken in nixpkgs on macOS
**Impact:** Blocks all Nix deployments

**Options:**
- A) Homebrew cask (5 min, works immediately)
- B) Override broken flag (30-60 min, risky)
- C) Python 3.12 override (1-2 hours, complex)

### Decision: Option A (Homebrew)

**Rationale:**
1. ✅ **Unblocks development** - 5 minute fix
2. ✅ **Zero maintenance** - Official binary, auto-updates
3. ✅ **Doesn't block NixOS migration** - `pkgs.activitywatch` exists for Linux
4. ✅ **Pragmatic** - Use best tool for current platform
5. ✅ **Establishes pattern** - Clear criteria for future decisions

### NixOS Migration Impact: NONE

**On NixOS:**
```nix
# Simply use nixpkgs package
environment.systemPackages = [ pkgs.activitywatch ];

# Config remains in same location
# ~/.config/activitywatch/ (from dotfiles/)
```

**No reconfiguration needed. Just different installation method.**

### Long-Term Sustainability

**Scenario 1: pynput gets fixed in nixpkgs (likely)**
```nix
# macOS: Switch from Homebrew to Nix
# Simply remove from homebrew.nix, add to environment.nix
# Configs unchanged
```

**Scenario 2: pynput stays broken (unlikely)**
```nix
# macOS: Continue using Homebrew
# NixOS: Use nixpkgs (works fine on Linux)
# Platform.nix handles the difference
```

**Either way: No migration problems.**

---

## PACKAGE DECISION CRITERIA

### Use Nix (Both Platforms)

**When:**
- CLI tools (always prefer Nix)
- Open-source with stable Nix packages
- Development toolchains
- System utilities

**Examples:** bat, fish, starship, ripgrep, fd, fzf

### Use Homebrew on macOS, Nix on NixOS

**When:**
- Package broken in Nix on macOS
- Commercial software with better integration
- GUI apps with complex dependencies
- **BUT:** Package must exist in nixpkgs for NixOS

**Examples:** ActivityWatch, Sublime Text, JetBrains

### Avoid (Both Platforms)

**Never use if:**
- Doesn't exist in nixpkgs for NixOS
- Would require platform-specific configuration
- Creates vendor lock-in

---

## TESTING STRATEGY

### Continuous Validation

**Goal:** Ensure configs work on both platforms

**Phase 1: Documentation (v0.1.0 - NOW)**
- ✅ Document cross-platform strategy
- ✅ Create platform package mapping
- ✅ Record all platform-specific decisions

**Phase 2: Abstraction (v0.2.0)**
- [ ] Create Platform.nix
- [ ] Make homebrew.nix conditional
- [ ] Update environment.nix to use platform abstraction

**Phase 3: Testing (v0.2.0)**
- [ ] GitHub Actions: Build on both platforms
- [ ] NixOS VM: Test actual migration
- [ ] Document any migration issues

**Phase 4: Validation (v0.3.0)**
- [ ] Real NixOS migration test
- [ ] Verify all configs work
- [ ] Update documentation

### CI/CD (Future)

```yaml
name: Cross-Platform Build
on: [push, pull_request]

jobs:
  macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build nix-darwin
        run: darwin-rebuild build --flake .

  nixos:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build NixOS
        run: nixos-rebuild build-vm --flake .
```

---

## DOCUMENTATION REQUIREMENTS

### For Each Platform-Specific Decision

**Create:** `docs/decisions/YYYY-MM-DD-package-name.md`

**Template:**
```markdown
# Decision: [Package] Installation Method

**Date:** YYYY-MM-DD
**Package:** package-name
**Status:** Active

## Context
Why platform-specific handling?

## Decision
- macOS: [Method & Reason]
- NixOS: [Method & Reason]

## Consequences
### Positive
- Unblocks development
- Uses best tool for platform
- Documented migration path

### Negative
- Hybrid package management
- Need to maintain mapping

### NixOS Migration Impact
LOW/MEDIUM/HIGH - Explain

## Alternatives Considered
1. Option A: ...
2. Option B: ...

## Review Date
When to reconsider?
```

### Master Mapping

**Maintain:** `docs/architecture/platform-package-mapping.md`

Update whenever:
- Adding new GUI app
- Changing installation method
- Discovering package availability

---

## MIGRATION GUIDE (Future)

### Prerequisites

1. ✅ All Homebrew packages exist in nixpkgs
2. ✅ Configs are platform-agnostic
3. ✅ Platform.nix abstraction exists
4. ✅ Tested in NixOS VM

### Migration Steps

**Step 1: Backup macOS State**
```bash
# List current Homebrew packages
brew list --cask > /tmp/macos-packages.txt

# Backup all configs
tar -czf /tmp/macos-dotfiles-backup.tar.gz ~/.config
```

**Step 2: Install NixOS**
```bash
# Standard NixOS installation
# Partition, format, install
```

**Step 3: Clone Dotfiles**
```bash
git clone https://github.com/user/Setup-Mac.git ~/dotfiles
cd ~/dotfiles
```

**Step 4: Build NixOS Configuration**
```bash
# Platform.nix automatically detects NixOS
sudo nixos-rebuild switch --flake .
```

**Step 5: Verify**
```bash
# All GUI apps should work
activitywatch --version
subl --version

# All CLI tools should work (same as macOS)
bat --version
fish --version
```

**Step 6: Restore Configs**
```bash
# Configs already in dotfiles/, just verify
ls ~/.config/activitywatch
ls ~/.config/fish
```

**Done!** All packages working, same configs, zero reconfiguration.

---

## REFERENCES

- **Platform Mapping:** `docs/architecture/platform-package-mapping.md`
- **Issue #129:** ActivityWatch decision (Homebrew on macOS)
- **Issue #98:** Cross-Platform Portable Development Environments
- **Split Brain #2:** Package management criteria

---

## SUMMARY

### Key Principles

1. **Pragmatism over Purity** - Use best tool for each platform
2. **Portability** - Keep configs platform-agnostic
3. **Documentation** - Record every platform-specific decision
4. **Abstraction** - Hide platform differences behind clean interface
5. **Testing** - Validate both platforms continuously

### Current State (v0.1.0)

- ✅ Using Homebrew for problematic GUI apps on macOS
- ✅ All packages exist in nixpkgs for NixOS
- ✅ Migration path documented
- ✅ Zero reconfiguration needed for migration

### Future State (v0.2.0)

- [ ] Platform abstraction implemented
- [ ] Both platforms tested in CI
- [ ] Ready for instant migration to NixOS

**Bottom Line:**
**Homebrew on macOS is a pragmatic stepping stone, not a dead end.**
**NixOS migration remains straightforward and low-effort.**
