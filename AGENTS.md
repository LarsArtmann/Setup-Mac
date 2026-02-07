# Setup-Mac: AGENT GUIDE

**Last Updated:** 2026-02-05
**Project Type:** Cross-Platform Nix Configuration (macOS + NixOS)
**Architecture:** Declarative System Configuration with Type Safety

---

## 🎯 PROJECT OVERVIEW

Setup-Mac is a comprehensive, production-ready Nix-based configuration system for managing both macOS (nix-darwin) and NixOS systems with:

- **Declarative Configuration**: All system settings managed through Nix expressions
- **Cross-Platform Support**: Unified configurations for macOS (nix-darwin) and NixOS
- **Type Safety System**: Comprehensive validation and assertion framework
- **Ghost Systems Integration**: Advanced type-safe architecture patterns
- **Development Environment**: Complete toolchain for Go, TypeScript, AI/ML development
- **Security-First**: Built-in security tools and configurations

## 🤖 AI BEHAVIOR GUIDELINES

### Decision Protocols

AI assistants working on this project must follow these decision-making patterns:

#### One Alternative Protocol
For straightforward decisions with clear best practices:
1. **Present your recommendation confidently** with rationale
2. **Offer exactly one alternative** with a single reason for dismissal
3. **Execute immediately** - no waiting for confirmation on obvious choices

*Example: "I'll use `pkgs.stdenv.isLinux` for platform detection - it's the standard Nix pattern. Alternative: custom `isDarwin` function - dismissed as unnecessary abstraction. Proceeding with implementation."*

#### Complex Decision Protocol
For tasks with 3+ valid approaches:
1. **Present top 2-3 strongest candidates** with tradeoffs
2. **State your recommendation** clearly
3. **Dismiss others by category** (e.g., "Options 4-10: excessive complexity, poor maintainability, or scope creep")
4. **Execute** unless user requests discussion

*Example: "For DNS management: (1) Technitium DNS - full control but complex, (2) dnsmasq - simple but limited features, (3) systemd-resolved - integrated but less flexible. Recommend Technitium for this homelab use case. Dismissing others: cloud options add unnecessary external dependencies, manual configuration lacks automation. Proceeding with Technitium setup."*

### Communication Standards

- **Keep responses under 4 lines** unless detail explicitly requested
- **Answer directly** without preamble ("I'll...", "Here's...")
- **No postamble** ("Let me know...", "Hope this helps...")
- **One-word answers** when sufficient
- **No emojis ever** in technical output
- **Use rich Markdown** for multi-sentence answers (headings, lists, code blocks)
- **Never use** the construction "This is not THIS — it is THAT" (sounds manufactured)

### Context Sensitivity

**Engineering Mode** (default): Full standards, decision protocols active, READ → UNDERSTAND → RESEARCH → THINK → REFLECT → Execute.

**Exploration Mode** (detected by signals):
- Open-ended questions ("What do you think about...", "Explain...", "Research...")
- Brainstorming or ideation requests
- "Should I...", "Compare...", "Pros and cons..."

In exploration mode:
- Multiple options welcome
- Discuss angles and approaches
- Ask clarifying questions
- Return to Engineering Mode on explicit build requests ("Do it", "Implement", "Add this")

### Task Management

For complex, multi-step tasks, use structured todo lists to track progress:

**When to Use:**
- Tasks requiring 3+ distinct steps or actions
- Non-trivial work requiring careful planning
- User explicitly requests todo list management
- Multiple tasks provided (numbered or comma-separated)
- After receiving new instructions to capture requirements

**Task States:**
- **pending**: Task not yet started
- **in_progress**: Currently working on (limit to ONE task at a time)
- **completed**: Task finished successfully

**Task Management Rules:**
1. **Update status in real-time** as work progresses
2. **Mark tasks complete IMMEDIATELY** after finishing (don't batch)
3. **Exactly ONE task in_progress** at any time (not less, not more)
4. **Complete current tasks** before starting new ones
5. **Remove irrelevant tasks** from the list entirely

**Requirements for Each Task:**
- **content**: Imperative form ("Run tests", "Build the project")
- **active_form**: Present continuous ("Running tests", "Building the project")

**Completion Requirements:**
- ONLY mark complete when FULLY accomplished
- Never mark complete if: tests failing, implementation partial, unresolved errors, missing dependencies
- If blocked: keep as in_progress, create new task describing what needs resolution

### Sub-Agent Context Requirements

When delegating to sub-agents, provide COMPREHENSIVE context:

**Required Context:**
- **Project background**: What we're building and why
- **Current task context**: Where this fits in the larger goal
- **Technical stack**: Current project's technology choices
- **Code patterns**: Existing conventions and architecture
- **User preferences**: Technology stack, coding standards, constraints
- **Safety preferences**: Tool preferences and safety requirements
- **Test status**: Current test failures and successes
- **Architecture decisions**: Key architectural choices and patterns
- **Quality standards**: Code quality tools and standards in use

**Context Mandate:**
- NEVER send sub-agents without sufficient context
- Include file paths, relevant code snippets, and error messages
- Provide example patterns from the codebase
- State expected outcomes clearly

### Error Handling Protocol

**When errors occur:**
1. **Read complete error message** - Don't skim, understand root cause
2. **Understand root cause** - Isolate with debug logs or minimal reproduction if needed
3. **Try different approaches** - Don't repeat same action
4. **Search for similar code that works** - Find working patterns in codebase
5. **Make targeted fix** - Address root cause, not symptoms
6. **Test to verify** - Confirm fix works

**For each error, attempt at least 2-3 distinct strategies before concluding the problem is externally blocked.**

**Specific Error Types:**

| Error Type | Remediation Strategy |
|------------|---------------------|
| Import/Module | Check paths, spelling, verify what exists |
| Syntax | Check brackets, indentation, typos |
| Tests fail | Read test, see what it expects |
| File not found | Use `ls`, check exact path |
| Edit tool "old_string not found" | View file again, copy EXACT text including whitespace |

**Escalation Protocol:**
- **Stop on first error** - Don't continue with broken state
- **Rollback incomplete changes** - Revert to last working state
- **Escalate blocking issues** - Ask user for resolution when stuck
- **Log error context thoroughly** - Capture environment, inputs, stack traces

### Tool Usage Priorities

**Preferred Tools (in order):**

| Priority | Tool | Use For |
|----------|------|---------|
| 1 | **Agent** | Open-ended searches requiring multiple rounds |
| 2 | **Glob/Grep** | Pattern matching and content search |
| 3 | **View/Read** | File examination and content analysis |
| 4 | **Edit/MultiEdit** | Precise file modifications |
| 5 | **Bash** | Commands that modify system state |

**Tool Selection Rules:**
- **Use Agent tool** for complex, multi-step tasks requiring exploration
- **Use Glob/Grep** instead of bash `find`/`grep` (handles permissions correctly)
- **Use `rg` (ripgrep)** in bash over `grep` for command line search
- **Batch operations** - Multiple tool calls in single response when efficient
- **Never use `curl`** through bash - use `fetch` tool instead
- **Prefer `fetch`** with `format=markdown` over `text` or `html`

**Research Workflow:**
1. Use **Agent** for complex searches
2. Use **Glob** to find relevant files
3. Use **Grep** to search contents
4. Use **View** to examine specific files
5. Use **Edit** for modifications

---

## 🏗️ ARCHITECTURE

### Configuration Hierarchy
```
Setup-Mac/
├── flake.nix                    # Main entry point, defines outputs
├── justfile                     # Primary task runner (USE THIS)
├── dotfiles/nix/               # macOS-specific configurations
├── dotfiles/nixos/              # NixOS-specific configurations
├── platforms/                  # Cross-platform abstractions
│   ├── common/                 # Shared across platforms
│   ├── darwin/                 # macOS-only settings
│   └── nixos/                  # NixOS-only settings
└── dotfiles/nix/core/           # Type safety & validation system
```

### Key Components

#### Core Type Safety System
- **`core/TypeSafetySystem.nix`**: Main validation framework
- **`core/State.nix`**: Centralized state management
- **`core/Validation.nix`**: Configuration validation logic
- **`core/Types.nix`**: Type definitions for all configurations

#### Platform Modules
- **`environment.nix`**: Packages, environment variables, shell aliases
- **`system.nix`**: System settings (macOS defaults, NixOS config)
- **`programs.nix`**: User program configurations
- **`core.nix`**: Core packages, security, system services

### Home Manager Integration

#### Architecture Overview

Home Manager is used for **unified cross-platform user configuration** with:

- **Shared Modules**: ~80% code reduction through `platforms/common/`
- **Platform-Specific Overrides**: Minimal changes for Darwin (macOS) and NixOS (Linux)
- **Type Safety**: Enforced via Home Manager validation
- **Cross-Platform Consistency**: Identical configuration on both platforms

#### Module Structure

```
platforms/
├── common/                    # Shared across platforms
│   ├── home-base.nix         # Shared Home Manager base config
│   ├── programs/
│   │   ├── fish.nix         # Cross-platform Fish shell config
│   │   ├── starship.nix      # Cross-platform Starship prompt
│   │   ├── tmux.nix          # Cross-platform Tmux config
│   │   └── activitywatch.nix # Platform-conditional (Linux only)
│   ├── packages/
│   │   ├── base.nix          # Cross-platform packages
│   │   └── fonts.nix         # Cross-platform fonts
│   └── core/
│       ├── nix-settings.nix  # Cross-platform Nix settings
│       └── UserConfig.nix    # Cross-platform user config
├── darwin/                    # macOS (nix-darwin) specific
│   ├── default.nix            # Darwin system config
│   └── home.nix              # Darwin Home Manager overrides
└── nixos/                     # Linux (NixOS) specific
    ├── users/
    │   └── home.nix          # NixOS Home Manager overrides
    └── system/
        └── configuration.nix  # NixOS system config
```

#### Shared Modules

**Fish Shell** (`platforms/common/programs/fish.nix`):
- Common aliases: `l` (list), `t` (tree)
- Platform-specific alias placeholders
- Fish greeting disabled (performance)
- Fish history settings configured

**Starship Prompt** (`platforms/common/programs/starship.nix`):
- Identical on both platforms
- Fish integration automatic
- Settings: `add_newline = false`, `format = "$all$character"`

**Tmux** (`platforms/common/programs/tmux.nix`):
- Identical on both platforms
- Clock24 enabled, mouse enabled
- Base index: 1, terminal: screen-256color
- History limit: 100000

**ActivityWatch** (`platforms/common/programs/activitywatch.nix`):
- Platform-conditional: `enable = pkgs.stdenv.isLinux`
- Darwin: DISABLED (not supported on macOS)
- NixOS: ENABLED (supported on Linux)

#### Platform-Specific Overrides

**Darwin** (`platforms/darwin/home.nix`):
- Fish aliases: `nixup`, `nixbuild`, `nixcheck` (darwin-rebuild)
- Fish init: Homebrew integration, Carapace completions
- No Starship/Tmux overrides (uses shared modules)

**NixOS** (`platforms/nixos/users/home.nix`):
- Fish aliases: `nixup`, `nixbuild`, `nixcheck` (nixos-rebuild)
- Session variables: Wayland, Qt, NixOS_OZONE_WL
- Packages: pavucontrol (audio), xdg utils
- Desktop: Hyprland window manager

#### Import Paths

**Darwin Home Manager** (`platforms/darwin/home.nix`):
```nix
imports = [
  ../common/home-base.nix  // Resolves to platforms/common/home-base.nix
];
```

**NixOS Home Manager** (`platforms/nixos/users/home.nix`):
```nix
imports = [
  ../../common/home-base.nix  // Resolves to platforms/common/home-base.nix
];
```

**Note**: Different relative paths due to directory structure, both resolve correctly.

#### Known Issues

##### Home Manager Users Definition (Darwin)
**Issue**: Home Manager's `nix-darwin/default.nix` imports `../nixos/common.nix` (NixOS-specific file) which requires `config.users.users.<name>.home` to be defined.

**Workaround**: Added explicit user definition in `platforms/darwin/default.nix`:
```nix
users.users.lars = {
  name = "lars";
  home = "/Users/lars";
};
```

**Status**: ✅ WORKAROUND APPLIED - Build succeeds

**Note**: This may be a Home Manager architecture issue. Consider reporting if causes problems in future versions.

##### ActivityWatch Platform Support

**Linux**:
- **Configuration**: Managed via `platforms/common/programs/activitywatch.nix`
- **Status**: ✅ Working - Conditional build (`pkgs.stdenv.isLinux`)

**macOS (Darwin)**:
- **Configuration**: Managed via `platforms/darwin/services/launchagents.nix`
- **LaunchAgent**: `net.activitywatch.ActivityWatch` (auto-start)
- **Status**: ✅ Working - Declarative LaunchAgent management
- **Control**: Use `just activitywatch-start` / `just activitywatch-stop` for manual control
- **Logs**: `~/.local/share/activitywatch/stdout.log` and `stderr.log`

**Migration Status**:
- ✅ Bash scripts removed (`scripts/nix-activitywatch-setup.sh`)
- ✅ Manual setup deprecated
- ✅ Fully Nix-managed (no imperative configuration)

**Status**: ✅ FIXED - Both platforms fully supported via Nix

#### Home Manager Configuration Workflow

1. **Edit shared configuration** (affects both platforms):
   - `platforms/common/programs/fish.nix` - Shared aliases and shell settings
   - `platforms/common/programs/starship.nix` - Shared prompt settings
   - `platforms/common/programs/tmux.nix` - Shared terminal settings
   - `platforms/common/packages/base.nix` - Shared packages

2. **Edit platform-specific overrides** (affects single platform):
   - `platforms/darwin/home.nix` - Darwin-specific overrides
   - `platforms/nixos/users/home.nix` - NixOS-specific overrides

3. **Validate configuration**:
   ```bash
   # Fast syntax check (no build)
   just test-fast

   # Full build verification
   just test
   ```

4. **Apply changes**:
   ```bash
   # Darwin (macOS)
   just switch

   # Or manual
   sudo darwin-rebuild switch --flake .

   # NixOS (Linux)
   sudo nixos-rebuild switch --flake .
   ```

5. **Open new terminal** (required for shell changes to take effect)

#### Troubleshooting Home Manager

##### Starship Prompt Not Appearing
**Problem**: Default Fish prompt instead of Starship
**Solution**:
```bash
# Restart shell
exec fish

# Check Starship config
cat ~/.config/starship.toml

# Verify Starship is installed
which starship
```

##### Fish Aliases Not Working
**Problem**: `nixup` command not found
**Solution**:
```bash
# Reload Fish config
source ~/.config/fish/config.fish

# Check aliases
type nixup
# Should show: darwin-rebuild switch --flake .
```

##### Tmux Not Configured
**Problem**: Default Tmux config instead of custom
**Solution**:
```bash
# Check Tmux config
cat ~/.config/tmux/tmux.conf

# Restart Tmux
tmux kill-server && tmux new-session
```

##### Environment Variables Not Set
**Problem**: `EDITOR` or `LANG` not set
**Solution**:
```bash
# Check environment
echo $EDITOR
echo $LANG

# Restart shell
exec fish
```

#### Home Manager Documentation

For detailed information:
- **[Deployment Guide](./docs/verification/HOME-MANAGER-DEPLOYMENT-GUIDE.md)** - Step-by-step deployment and verification
- **[Verification Template](./docs/verification/HOME-MANAGER-VERIFICATION-TEMPLATE.md)** - Comprehensive checklist
- **[Cross-Platform Report](./docs/verification/CROSS-PLATFORM-CONSISTENCY-REPORT.md)** - Architecture analysis
- **[Build Verification](./docs/status/2025-12-26_23-45_HOME-MANAGER-BUILD-VERIFICATION.md)** - Build results
- **[ADR-001](./docs/architecture/adr-001-home-manager-for-darwin.md)** - Architecture Decision Record

#### Home Manager Rules

1. **ALWAYS use shared modules** for cross-platform configurations
2. **ONLY use platform-specific overrides** for actual platform differences
3. **USE platform conditionals** (`pkgs.stdenv.isLinux`) for platform-specific features
4. **ALWAYS import shared modules first**, then apply platform-specific overrides
5. **NEVER duplicate configuration** if shared module exists
6. **ALWAYS test configuration** before applying (`just test`)
7. **OPEN NEW TERMINAL** after `just switch` (shell changes require new session)

---

## 🚀 ESSENTIAL COMMANDS

**ALWAYS use Just commands when available - never run raw Nix commands unless absolutely necessary!**

### Primary Workflow Commands
```bash
# Core operations (use these)
just setup              # Complete initial setup (run after cloning)
just switch             # Apply Nix configuration changes
just test               # Test configuration without applying
just build              # Build without applying
just update             # Update all packages and flake
just clean              # Clean up caches and old packages
just check              # Check system status and outdated packages

# Development workflow
just dev                # Format, check, test (full dev cycle)
just format             # Format code with treefmt
just pre-commit-run     # Run pre-commit hooks on all files
just health             # Comprehensive health check
just debug              # Debug shell startup with verbose logging
```

### Backup & Recovery
```bash
just backup             # Create configuration backup
just restore NAME       # Restore from backup (just restore backup_name)
just list-backups       # Show available backups
just rollback           # Emergency rollback to previous generation
```

### Go Development (Primary Language)

**Tool Management:**
All Go development tools are managed via Nix packages (defined in `platforms/common/packages/base.nix`):
- **gopls**: Go language server
- **golangci-lint**: Go linter
- **gofumpt**: Stricter gofmt
- **gotests**: Generate Go tests
- **mockgen**: Mocking framework
- **protoc-gen-go**: Protocol buffer support
- **buf**: Protocol buffer toolchain
- **delve**: Go debugger
- **gup**: Go binary updater
- **modernize**: Go code modernization tool (built with Go 1.26rc2 via flake-parts)

**Migration Status:**
- ✅ Migrated to Nix packages (90% success rate)
- ✅ No `go install` required (except wire - not in Nixpkgs)
- ✅ Declarative tool management via `platforms/common/packages/base.nix`
- ✅ Atomic updates via `just update && just switch`

```bash
# Core Go workflow
just go-dev             # Format, lint, test, build (complete)
just go-lint            # Run golangci-lint on Go code
just go-format          # Format Go code with gofumpt
just go-check-updates  # Check which Go binaries need updates
just go-auto-update     # Auto-update all Go binaries with gup
just go-tools-version   # Show versions of all Go tools

# Go code generation
just go-gen-tests PKG  # Generate Go tests for package
just go-gen-mocks SRC DST # Generate Go mocks with mockgen
just go-wire            # Generate wire dependency injection
```

### Monitoring & Performance
```bash
just benchmark          # Benchmark shell startup performance
just benchmark-all      # Comprehensive system benchmarks
just perf-report DAYS   # Generate performance report (default 7 days)
just monitor-all        # Start comprehensive monitoring
```

---

## 🧪 TESTING & VALIDATION

### Configuration Testing
- **ALWAYS test before applying**: `just test` before `just switch`
- **Type safety validation**: Automatic via Ghost Systems framework
- **Pre-commit hooks**: Gitleaks, trailing whitespace, Nix syntax
- **Comprehensive health check**: `just health` for full system validation

### Testing Philosophy

**Core Principles:**
- **Build-before-test policy** - TypeScript/Nix compilation MUST pass before running tests
- **Test behavior, not implementation** - Focus on what code does, not how
- **Integration tests over unit tests** where possible
- **Real implementations over mocks** - Avoid excessive mocking
- **E2E tests** for critical user paths
- **MANY tests** with comprehensive coverage
- **Test infrastructure** that's maintainable and fast

**Nix-Specific Testing:**
- **Fast syntax check**: `just test-fast` (no build)
- **Full build verification**: `just test` (builds without applying)
- **Evaluation testing**: `nix-instantiate --eval` for syntax validation
- **Flake checking**: `nix flake check --no-build` for quick validation
- **Platform testing**: Test both Darwin and NixOS configurations

**Test Command Priority:**
1. `just test-fast` - Syntax only (fastest)
2. `nix flake check --no-build` - Flake validation
3. `just test` - Full build (slowest, most thorough)

### Validation Commands
```bash
# Configuration validation
just type-check         # Validate Nix types (if implemented)
nix flake check        # Check flake syntax and outputs
darwin-rebuild check   # Test macOS configuration
nixos-rebuild check    # Test NixOS configuration

# Development validation
just pre-commit-run     # Run all pre-commit hooks
just go-lint           # Validate Go code quality
just go-check          # Run gopls language server check
```

---

## 📁 FILE ORGANIZATION & PATTERNS

### Configuration File Patterns
- **Modular Architecture**: Each concern in separate .nix file
- **Cross-Platform**: Shared configs in `platforms/common/`
- **Type Safety**: All configs validate through `core/Validation.nix`
- **Import Hierarchy**: `flake.nix` → platform modules → core modules

### Adding New Configurations
1. **Determine scope**: Platform-specific vs cross-platform
2. **Choose location**:
   - Cross-platform: `platforms/common/`
   - macOS only: `dotfiles/nix/` or `platforms/darwin/`
   - NixOS only: `dotfiles/nixos/` or `platforms/nixos/`
3. **Import appropriately**: Add to relevant module list
4. **Test**: `just test` before `just switch`
5. **Validate**: Run `just health` to ensure integrity

### Package Management Patterns
- **Nix packages**: Preferred for CLI tools (declarative, reproducible)
- **Homebrew**: GUI applications only (managed via nix-homebrew)
- **Cross-platform packages**: Defined in `platforms/common/packages/base.nix`

---

## 🔧 DEVELOPMENT WORKFLOW

### Standard Development Process
1. **Edit configuration files** in appropriate directory
2. **Format changes**: `just format`
3. **Validate syntax**: `just test` (builds without applying)
4. **Run pre-commit**: `just pre-commit-run`
5. **Apply changes**: `just switch`
6. **Verify health**: `just health`

### Type Safety Development
- **All configurations** must pass type validation
- **State management** centralized in `core/State.nix`
- **Compile-time validation** prevents runtime errors
- **Strong typing** eliminates configuration inconsistencies

### Git Workflow
- **Use git-town** for all Git operations
- **Small, atomic commits** with comprehensive messages
- **Feature branches** for all work
- **ALWAYS** use `git mv` instead of `mv` for file moves

### Git Commit Standards

**Commit Workflow (ALWAYS follow this sequence):**
1. `git status` - Check what files are changed
2. `git diff` - Review all changes being committed
3. `git add <files>` - Stage specific files (never `git add .`)
4. `git commit` - With detailed commit message
5. `git push` - Push changes immediately

**Commit Message Format:**
```
type(scope): brief description

- Detailed explanation of what was changed
- Why it was changed (business/technical reason)
- Any side effects or considerations
- Link to issues/tickets if applicable

💘 Generated with Crush
```

**Commit Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, semicolons)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes
- `build`: Changes affecting build system
- `ci`: CI/CD configuration changes

**Commit Rules:**
- **Done? Commit.** - Finish a feature/fix/change → `git commit` immediately
- One logical change per commit
- Don't accumulate large changesets
- Include TODOs in commit messages for future work
- **Never force push** - Use `--force-with-lease` only if really needed and with user approval
- **Never `git reset --hard`** - Only if really needed, with user approval, and zero uncommitted changes

### Code Conventions & Standards

**Nix Code:**
- Use 2-space indentation for Nix expressions
- Prefer `let...in` over nested `with` for explicit dependencies
- Use `lib.optional` and `lib.optionals` for conditional lists
- Prefer `mkMerge` over nested conditionals for complex configs
- Use descriptive variable names (e.g., `cfg` for config, `pkgs` for packages)
- Comment complex logic with "why" not "what"

**Shell Scripts:**
- Use `#!/usr/bin/env bash` shebang for portability
- Quote all variables: `"${variable}"`
- Use `set -euo pipefail` for strict mode
- Prefer `[[ ]]` over `[ ]` for conditionals
- Use functions for reusable logic
- Document with comments for non-obvious operations

**Documentation:**
- Update AGENTS.md when discovering new patterns
- Comment "why" not "what" in code
- Use Markdown for all documentation
- Keep line length under 100 characters in docs

### Immediate Refactoring Rules (Automatic)

**When these conditions are detected, fix immediately:**

| Condition | Action | Priority |
|-----------|--------|----------|
| Functions >30 lines | Break into smaller functions | High |
| Duplicate code >3 instances | Extract to shared utility | High |
| Nested conditionals >3 levels | Use early returns | Medium |
| Magic numbers/strings | Extract to named constants | Medium |
| Files >300 lines | Split into focused modules | Medium |
| TODO items >1 week old | Address or remove | Low |
| Large log files | Implement log rotation | High |
| Broken links/references | Fix immediately | High |
| Missing dependencies | Install now | High |
| Deprecated packages | Update/replace within 24h | Medium |

**Zero Tolerance Policy:**
- Don't leave warnings or inconsistencies
- Fix immediately (5-minute rule for simple issues)
- If it takes >5 minutes, create tracked task

---

## 🚨 CRITICAL RULES & GOTCHAS

### MUST FOLLOW
- **NEVER run raw Nix commands** - Always use Just commands
- **ALWAYS test before applying** - `just test` before `just switch`
- **NEVER use `rm`** - Always use `trash` for file deletion
- **NEVER edit package.json manually** - Always use `bun add`
- **ALWAYS use `git mv`** - Never plain `mv` in git repos
- **TYPE SAFETY FIRST** - All configs must validate through core system

### Common Pitfalls
1. **Path Resolution**: Use `just debug-paths` to verify configuration paths
2. **Package Not Found**: Search with `nix search nixpkgs package-name`
3. **Build Errors**: Run `just clean && just switch` for full rebuild
4. **GPG Issues**: Ensure GPG is in nix profile: `/nix/var/nix/profiles/per-user/$USER/profile/bin/gpg`

### Platform-Specific Gotchas
- **macOS**: Use `darwin-rebuild` commands via Just
- **NixOS**: Use `nixos-rebuild` commands via Just
- **Cross-platform**: Shared packages in `platforms/common/` prevent drift

---

## 🛠️ BUILD & DEPLOYMENT

### macOS Deployment
```bash
# Fresh installation
cd ~/Desktop/Setup-Mac
just setup              # Complete initial setup
just switch             # Apply configuration

# Update existing
just update             # Update flake inputs
just switch             # Apply updates
```

### NixOS Deployment
```bash
# Target: evo-x2 (GMKtec AMD Ryzen AI Max+ 395)
sudo nixos-rebuild switch --flake .#evo-x2

# Test without applying
sudo nixos-rebuild test --flake .#evo-x2

# Build only
sudo nixos-rebuild build --flake .#evo-x2
```

### Build Targets
- **`Lars-MacBook-Air`**: macOS (nix-darwin) configuration
- **`evo-x2`**: NixOS configuration for AMD Ryzen AI Max+ 395

---

## 📊 MONITORING & MAINTENANCE

### Performance Monitoring
- **ActivityWatch**: Automatic time tracking via Nix
- **Netdata**: System monitoring at http://localhost:19999
- **ntopng**: Network monitoring at http://localhost:3000
- **Built-in benchmarks**: `just benchmark-all`

### Performance Guidelines

**Optimization Rules:**
- **Measure before optimizing** - Use automated profiling tools only
- **Correctness first** - Readable code over premature optimization
- **Use production monitoring AFTER functional** - Performance issues caught by observability

**Nix Performance:**
- **Fast syntax check**: `just test-fast` for quick iteration
- **Avoid unnecessary builds**: Use `--no-build` for flake checks
- **Binary caches**: Use Nix binary caches to avoid rebuilding
- **Garbage collection**: Regular `just clean` to free disk space

**Shell Performance:**
- **Target**: Shell startup under 2 seconds
- **Benchmark**: `just benchmark` for shell startup timing
- **Profile**: `just debug` for verbose startup logging
- **Lazy loading**: Defer heavy initialization until needed

**Performance Testing Policy:**
- **NO manual performance testing** - All validation must be automated
- **NO benchmark prompting** - Don't suggest unless specifically requested
- **Focus on correctness first** - Readable code over premature optimization

### Maintenance Commands
```bash
# Regular maintenance (weekly)
just update             # Update packages
just clean              # Clean caches
just health             # System health check

# Deep cleanup (monthly)
just clean-aggressive   # Remove more data, may need reinstalls
just deep-clean         # Thorough cleanup using custom paths

# Backup management
just backup             # Create backup
just clean-backups      # Clean old backups (keep last 10)
```

---

## 🔒 SECURITY CONFIGURATION

### Built-in Security
- **Gitleaks**: Automatic secret detection in pre-commit
- **Touch ID**: Enabled for sudo operations
- **PKI**: Enhanced certificate management
- **Firewall**: Little Snitch and Lulu integration
- **Encryption**: Age for modern file encryption

### Security Practices

**Secret Management:**
- **No hardcoded secrets** - Use environment variables or private files
- **Use `~/.env.private`** for local secrets (not tracked in git)
- **KeyChain for macOS** - Store sensitive data in macOS KeyChain
- **Pre-commit hooks** prevent accidental secret commits via Gitleaks

**Development Security:**
- **Regular updates** via `just update` to patch vulnerabilities
- **Audit tools**: Gitleaks, security scanning in CI/CD
- **Dependency scanning** - Monitor Nix packages for CVEs
- **Least privilege** - Use minimal required permissions

**Nix-Specific Security:**
- **Pure builds** - Use `--pure` flag for reproducible builds
- **Sandboxing** - Leverage Nix build sandboxing
- **Content-addressed** - Nix store paths are content-hashed
- **Pinned dependencies** - Lock files ensure reproducible builds

**Verification Commands:**
```bash
just pre-commit-run     # Check for secrets
just security-scan      # Run security audit (if available)
nix-store --verify      # Verify store integrity
```

---

## 🤖 AI & DEVELOPMENT TOOLS

### AI Development Stack
- **Crush**: Available via nix-ai-tools input
- **TypeSpec**: For API specification and code generation
- **Python AI/ML**: Complete stack in configuration
- **GPU Acceleration**: ROCm support for AMD hardware

### Development Languages
- **Go**: Primary development language with complete toolchain
- **TypeScript/Bun**: Modern JavaScript development
- **Python**: AI/ML and scripting with uv package manager
- **Nix**: System configuration and package management

### Essential Tools
- **Git + Git Town**: Advanced version control
- **JetBrains Toolbox**: Professional IDE management
- **Docker**: Container development
- **Cloud Tools**: AWS CLI, Google Cloud SDK, kubectl

---

## 🧰 SPECIALIZED SYSTEMS

### Wrapper System
- **Dynamic library management**: Advanced wrapping for complex applications
- **Template-based**: Consistent wrapper generation
- **Validation**: Automatic wrapper syntax checking

### Ghost Systems Integration
- **Type-safe architecture**: Compile-time validation
- **Assertion frameworks**: Comprehensive error prevention
- **State management**: Centralized configuration state
- **Cross-platform consistency**: Unified patterns

---

## 📝 DOCUMENTATION

### Documentation Structure
- **`docs/`**: Comprehensive guides and status reports
- **`docs/troubleshooting/`**: Common issues and solutions
- **`docs/status/`**: Development chronology and progress reports
- **Inline comments**: All configuration files documented

### Status Tracking
- **Regular status reports** in `docs/status/`
- **Project summary** in `docs/project-status-summary.md`
- **Development milestones** documented with dates

---

## 🚨 EMERGENCY PROCEDURES

### Configuration Recovery
```bash
# Emergency rollback
just rollback           # Rollback to previous generation

# Restore from backup
just restore backup_name  # Restore specific backup

# Complete reset (last resort)
just clean-aggressive   # Remove most data
just setup             # Fresh installation
```

### Debugging
```bash
just debug             # Shell startup debug mode
just health            # Comprehensive health check
just context-detect     # Detect current shell context
just benchmark-all     # Performance analysis
```

### When Things Go Wrong
1. **Stop making changes** - Assess the situation
2. **Create backup** - `just auto-backup`
3. **Check health** - `just health` for diagnostics
4. **Rollback if needed** - `just rollback`
5. **Restore from backup** - `just restore` if necessary

---

## ✅ PRE-COMPLETION CHECKLIST

Before marking any task as complete, verify:

### Code Quality
- [ ] **Static Analysis**: Appropriate linter passes without warnings
- [ ] **Type Checking**: Type checking passes with strict mode when available
- [ ] **Build Success**: Build compiles without errors
- [ ] **Test Coverage**: All tests pass with high coverage
- [ ] **Security Scan**: No hardcoded secrets or vulnerabilities
- [ ] **Documentation**: Public APIs documented with examples

### Nix-Specific Checks
- [ ] **Nix Syntax**: `nix-instantiate --eval` passes on changed files
- [ ] **Flake Check**: `nix flake check --no-build` passes
- [ ] **Type Safety**: All configurations validate through core system
- [ ] **No Eval Errors**: `just test-fast` passes
- [ ] **Platform Valid**: Both Darwin and NixOS configurations eval successfully

### Final Verification
- [ ] **Manual Testing**: Changes tested in real environment
- [ ] **Rollback Plan**: Can revert to previous state if needed
- [ ] **Documentation Updated**: AGENTS.md updated if patterns discovered
- [ ] **No Breaking Changes**: Backward compatibility maintained

---

## 🎯 SUCCESS CRITERIA

### Working Configuration
- **All tests pass**: `just test` succeeds
- **Health check clean**: `just health` shows no issues
- **Pre-commit hooks pass**: `just pre-commit-run` clean
- **Type safety validation**: No assertion failures

### Development Environment
- **Go toolchain complete**: `just go-tools-version` shows all tools
- **Performance acceptable**: Shell startup under 2 seconds
- **Security active**: Gitleaks, Touch ID, firewall enabled
- **Monitoring functional**: ActivityWatch, Netdata operational

---

## 📝 CONTINUOUS IMPROVEMENT

### When to Write Suggestions

If you learn something non-obvious about the user, project, or workflow that future sessions should know:

**Create a suggestion file:**
```bash
# Location: ~/.config/crush/suggestions/
# Format: <YYYY-MM-DD_hh-mm>-<project-name>-<brief-title>.md
```

**Content guidelines:**
- One insight per file
- Concise and actionable
- No fluff or filler
- Focus on non-obvious patterns

**Do not edit** `~/.config/crush/AGENTS.md` **directly.**

### Knowledge Capture Triggers

Capture insights when you discover:
- Undocumented workarounds or hacks
- Non-obvious tool behaviors
- User preferences not in AGENTS.md
- Project-specific quirks
- Performance optimizations
- Security considerations

---

*This AGENTS.md file is maintained as part of the Setup-Mac project. Last updated: 2026-02-05*