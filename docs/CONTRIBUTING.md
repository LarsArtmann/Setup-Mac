# Contributing to SystemNix

Cross-platform Nix configuration managing macOS (nix-darwin) and NixOS via a single flake.

## Quick Start

```bash
just setup                # First-time setup after clone
just switch               # Apply config (auto-detects platform)
just test-fast            # Syntax check before committing
just format               # Auto-format all Nix files
just health               # System health check
```

## Architecture

```
SystemNix/
├── flake.nix                    # Entry point (flake-parts)
├── justfile                     # Task runner — use this, not raw nix commands
├── modules/nixos/services/      # NixOS service modules (flake-parts)
├── pkgs/                        # Custom package derivations
└── platforms/
    ├── common/                  # Shared config (~80%), imported by both platforms
    ├── darwin/                  # macOS (nix-darwin, user: larsartmann)
    └── nixos/                   # NixOS (user: lars)
```

## Code Style

### Nix

- **2-space indentation** (enforced by alejandra)
- **Unused parameters**: Use `_:` when a function takes no arguments (satisfies both deadnix and statix)
- **Legitimate inputs**: Keep `{inputs, ...}:` when the module actually uses `inputs` (e.g., hermes.nix, signoz.nix)
- **Module options**: Every `mkOption` must have a `description` field
- **No inline secrets**: Use sops-nix for all sensitive values

### Go (custom packages in `pkgs/`)

- **Tab indentation** (per .editorconfig)
- Follow standard Go conventions

### General

- **LF line endings**, UTF-8, final newline enforced
- **Python**: 4-space indent
- **Justfile/Makefile**: Tab indentation

## Pre-commit Hooks

Installed via `just pre-commit-install`. All hooks must pass before merge:

| Hook | Purpose |
|------|---------|
| gitleaks | Detect committed secrets |
| trailing-whitespace | Clean trailing spaces |
| deadnix | Find dead/unused Nix code |
| statix | Detect Nix antipatterns (20+ rules) |
| alejandra | Enforce Nix formatting |
| nix-check | Full `nix flake check --no-build` |
| flake-lock-validate | Validate lockfile integrity |
| check-merge-conflicts | Catch unresolved markers |

### Auto-fix Commands

```bash
nix fmt                              # Format all Nix files with alejandra
statix fix .                         # Auto-fix linting issues
deadnix --fail --no-lambda-pattern-names .  # Check for dead code
```

## Adding a New NixOS Service

Services are self-contained flake-parts modules in `modules/nixos/services/`:

1. Create `modules/nixos/services/<name>.nix` as a flake-parts module
2. Add to `imports` in `flake.nix`
3. Wire into NixOS config via `inputs.self.nixosModules.<name>`
4. Enable in `platforms/nixos/system/configuration.nix`

Module template:

```nix
_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.my-service;
in
{
  options.services.my-service = {
    enable = lib.mkEnableOption "My Service";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for the service";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.my-service = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.my-service}/bin/my-service --port ${toString cfg.port}";
        Restart = "on-failure";
      };
    };
  };
}
```

## Shared Configuration

Place cross-platform config in `platforms/common/`. Both platforms import `common/home-base.nix`, which pulls in program modules from `common/programs/`.

Platform differences use:
```nix
if pkgs.stdenv.isLinux then "..." else "..."
```

Only override in platform dirs for things that genuinely differ.

## Verification

```bash
just test-fast            # Fast syntax-only check
just test                 # Full build validation
just check                # System status, git, disk usage
just health               # System health check
just format               # Auto-format and verify
```

## Key Patterns to Know

### Infinite Recursion Avoidance

Never wrap config in `lib.mkIf config.services.<nixpkg-option>.enable` AND set attributes under `services.<nixpkg-option>` inside the same `mkIf`. Create a separate custom option instead.

### Systemd Hardening

Use the shared `lib/systemd.nix` harden function for consistent security:
```nix
serviceConfig = config.lib.systemd.harden {
  PrivateTmp = true;
  MemoryMax = "512M";
};
```

### Secrets

All secrets managed via sops-nix with age encryption. See `modules/nixos/services/sops.nix`.
