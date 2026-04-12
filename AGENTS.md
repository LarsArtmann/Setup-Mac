# SystemNix: AGENT GUIDE

**Last Updated:** 2026-04-04
**Project Type:** Cross-Platform Nix Configuration (macOS + NixOS)
**Repo:** `github:LarsArtmann/SystemNix`

---

## Project Overview

SystemNix manages two machines through a single Nix flake:

| System | Hostname | Platform | Hardware |
|--------|----------|----------|----------|
| macOS | `Lars-MacBook-Air` | aarch64-darwin | Apple Silicon |
| NixOS | `evo-x2` | x86_64-linux | AMD Ryzen AI Max+ 395, 128GB |

~80% of configuration is shared via `platforms/common/`. Platform-specific code lives in `platforms/darwin/` and `platforms/nixos/`.

## Architecture

```
SystemNix/
├── flake.nix                    # Entry point (flake-parts)
├── justfile                     # Task runner — ALWAYS use this over raw Nix commands
│
├── modules/nixos/services/      # NixOS service modules (flake-parts)
│   ├── default.nix              # Docker
│   ├── caddy.nix                # Reverse proxy (TLS via sops)
│   ├── gitea.nix                # Git hosting + GitHub mirror
│   ├── grafana.nix              # Dashboards
│   ├── homepage.nix             # Service dashboard
│   ├── immich.nix               # Photo/video management
│   ├── monitoring.nix           # Prometheus + exporters
│   ├── photomap.nix             # AI photo exploration
│   ├── signoz.nix               # Observability (traces/metrics/logs)
│   ├── sops.nix                 # Secrets management
│   └── taskchampion.nix         # Taskwarrior sync server
│
├── pkgs/                        # Custom packages
│   ├── dnsblockd.nix            # DNS block page server (Go)
│   ├── dnsblockd-processor/     # DNS blocklist processor (Go)
│   ├── modernize.nix            # Go modernize tool
│   └── aw-watcher-utilization.nix
│
└── platforms/
    ├── common/                  # Shared (~80%)
    │   ├── home-base.nix        # Imports 15 program modules
    │   ├── programs/            # fish, zsh, bash, nushell, starship, git, tmux, fzf, taskwarrior, ...
    │   ├── packages/base.nix    # All cross-platform packages (70+)
    │   └── core/nix-settings.nix
    ├── darwin/                  # macOS (nix-darwin)
    │   ├── default.nix          # System config (user: larsartmann)
    │   ├── home.nix             # HM config (imports common/home-base.nix)
    │   ├── services/launchagents.nix  # ActivityWatch, Crush updates
    │   └── programs/shells.nix  # darwin-rebuild aliases
    └── nixos/                   # NixOS
        ├── system/configuration.nix  # Main system entry
        ├── system/boot.nix      # systemd-boot, kernel params, ZRAM
        ├── system/networking.nix # Static IP, firewall
        ├── system/dns-blocker-config.nix  # Unbound + dnsblockd
        ├── system/snapshots.nix # BTRFS + Timeshift
        ├── desktop/             # Niri, Waybar, SDDM, AI stack, security
        ├── hardware/            # AMD GPU/NPU, Bluetooth
        ├── programs/            # Rofi, swaylock, wlogout, Yazi, Zellij, Chromium
        └── users/home.nix       # HM config (imports common/home-base.nix)
```

## Key Patterns

### NixOS Service Modules (flake-parts)

Services are self-contained flake-parts modules in `modules/nixos/services/`. Each module:
- Defines its own `config` options under `services.<name>`
- Manages its own systemd services, users, and dependencies
- Is imported in `flake.nix` via `imports = [ ./modules/nixos/services/<name>.nix ];`
- Is wired into the NixOS configuration via `inputs.self.nixosModules.<name>`

To add a new service:
1. Create `modules/nixos/services/<name>.nix` as a flake-parts module
2. Add it to `imports` in `flake.nix`
3. Add `inputs.self.nixosModules.<name>` to the evo-x2 module list
4. Enable it in `platforms/nixos/system/configuration.nix`

### Cross-Platform Home Manager

Both platforms import `platforms/common/home-base.nix`, which pulls in 14 program modules from `platforms/common/programs/`. The import paths differ:

```nix
# Darwin (platforms/darwin/home.nix)
imports = [ ../common/home-base.nix ];

# NixOS (platforms/nixos/users/home.nix)
imports = [ ../../common/home-base.nix ];
```

**Rules:**
- Shared config goes in `platforms/common/` — both platforms inherit it
- Platform differences use `pkgs.stdenv.isLinux` / `pkgs.stdenv.isDarwin`
- Only override in platform dirs for things that genuinely differ
- Darwin user: `larsartmann`, NixOS user: `lars`

### Custom Overlays

Three overlays are defined in `flake.nix`:

| Overlay | Purpose |
|---------|---------|
| `goOverlay` | Pins Go to 1.26.1 (overrides default) |
| `awWatcherOverlay` | Builds `aw-watcher-utilization` from local nix pkg |
| `dnsblockdOverlay` | Builds `dnsblockd` + `dnsblockd-processor` from local source (Linux only) |

Go overlay is applied on both platforms. dnsblockd overlay is Linux-only (applied in NixOS config).

### Wrapped Packages (Vimjoyer Pattern)

Niri is wrapped using the `wrapper-modules` pattern to bake configuration into the package:

```nix
# Config function (platforms/nixos/programs/niri-wrapped.nix)
{ pkgs, lib }:
{
  binds = {
    "Mod+Q".close-window = null;        # null for actions
    "Mod+Return".spawn = ["kitty"];      # list for spawn
    "Mod+D".spawn-sh = "rofi -show drun"; # string for shell commands
  };
}
```

**Limitation:** `lib.mkMerge` does not work with flake-parts modules.

### Crush AI Config Deployment

Crush config (`~/.config/crush/`) is a flake input deployed via Home Manager on both platforms:

```nix
# flake.nix input
crush-config.url = "github:LarsArtmann/crush-config";

# Both home.nix files
home.file.".config/crush".source = crush-config;
```

To update: `just update && just switch` (fetches latest crush-config from GitHub).

### NixOS DNS Blocker

Custom DNS blocking stack: Unbound (resolver) + dnsblockd (Go block page server).
- 25 blocklists, 2.5M+ domains blocked
- Upstream: Quad9 (DNS-over-TLS) + Cloudflare fallback
- Local `.home.lan` DNS records for all services
- Blocklist source: `platforms/nixos/programs/dnsblockd/`

### Taskwarrior + TaskChampion Sync

Task management synced across NixOS, macOS, and Android via TaskChampion sync server.
- Server: `services.taskchampion-sync-server` on NixOS (port 10222, behind Caddy at `tasks.home.lan`)
- Client: Taskwarrior 3 via Home Manager (`platforms/common/programs/taskwarrior.nix`)
- Android: TaskStrider (Play Store, supports TaskChampion sync)
- Sync URL: `https://tasks.home.lan`
- No forward auth — TaskChampion uses client ID allowlisting + client-side encryption
- Per-device setup required: generate client ID (`uuidgen`) and set `sync.server.client_id` + `sync.encryption_secret` in `~/.config/task/taskrc`

AI agent task tracking protocol:
- Tag `+agent` for AI-created/tracked tasks
- UDA `source` identifies the originating agent (e.g., `source:crush`)
- Report: `task report.agent` shows agent tasks
- Quick add: `just task-agent "description"` adds task with `+agent source:crush`
- Setup: `just task-setup` generates client ID + configures encryption secret
- Backup: `just task-backup` exports all tasks as JSON to `~/backups/taskwarrior/`
- Theme: Catppuccin Mocha colors configured in `platforms/common/programs/taskwarrior.nix`

## Critical Rules & Gotchas

### Must Follow

- **Use `just` commands** — never raw `nixos-rebuild`/`darwin-rebuild` directly
- **Test before applying** — `just test-fast` (syntax) or `just test` (full build)
- **Use `trash` not `rm`** for file deletion
- **Use `git mv` not `mv`** in this repo
- **No OpenZFS on macOS** — causes kernel panics (see ADR-003)
- **2-space indentation** for Nix files
- **Open new terminal** after `just switch` (shell changes need new session)
- **`config.allowBroken = false`** — must stay false in flake.nix

### Non-Obvious Gotchas

| Issue | Explanation |
|-------|-------------|
| Darwin HM user | Must define `users.users.larsartmann.home` in `platforms/darwin/default.nix` — Home Manager requires it |
| Different relative paths | Darwin home.nix uses `../common/`, NixOS uses `../../common/` due to directory depth |
| Go overlay on Darwin | Darwin doesn't use the Go overlay from perSystem — it defines its own in the darwinConfiguration modules |
| NixOS overlays separate | NixOS adds `niri.overlays.niri`, `dnsblockdOverlay`, and Python overrides on top of the shared ones |
| SigNoz built from source | SigNoz is built from source (Go 1.25), not from a pre-built package. Takes significant build time. |
| crush-config doesn't follow nixpkgs | The crush-config input intentionally does NOT follow nixpkgs (no `inputs.nixpkgs.follows`) |
| Theme everywhere | Catppuccin Mocha is the universal theme — all apps, terminals, bars, login screen |
| SSH config is external | SSH configuration comes from `nix-ssh-config` flake input, not defined locally |
| Secrets via sops-nix | Secrets are age-encrypted using the SSH host key. Managed in `modules/nixos/services/sops.nix` |
| BTRFS dual layout | Root uses zstd compression, `/data` uses zstd:3 with async discard. Docker lives on `/data`. |

## Known Issues

| Issue | Workaround | Status |
|-------|-----------|--------|
| Darwin HM user definition | Explicit `users.users.larsartmann` in darwin/default.nix | Workaround applied |
| mkMerge + flake-parts | Use inline config or imports instead of `lib.mkMerge` | Accepted limitation |
| `wire` not in Nixpkgs | Installed via `go install` (see `go-update-tools-manual` just recipe) | Accepted |

## Essential Commands

```bash
# Core
just setup              # Initial setup after clone
just switch             # Apply config (detects platform automatically)
just update             # Update flake inputs
just test-fast          # Syntax-only validation (fast)
just test               # Full build validation (slow)
just format             # Format with treefmt + alejandra
just health             # Health check
just validate           # nix flake check --no-build

# Go development
just go-dev             # Full workflow (format, lint, test, build)
just go-tools-version   # Show all tool versions

# NixOS services
just dns-diagnostics    # DNS stack diagnostics
just immich-status       # Immich service status
just immich-backup       # Database backup
just gitea-sync-repos    # Sync GitHub → Gitea

# Taskwarrior
just task-list           # Show pending tasks (next report)
just task-add <desc>     # Add a new task
just task-agent <desc>   # Add AI-tracked task (+agent source:crush)
just task-sync           # Sync with TaskChampion server
just task-status         # Show task counts + sync config
just task-setup          # Per-device: generate client ID + set encryption secret
just task-backup         # Export all tasks as JSON

# Recovery
just rollback           # Revert to previous generation
just backup / just restore NAME
```

## Flake Inputs

| Input | What | Follows nixpkgs? |
|-------|------|-------------------|
| `nixpkgs` | Package collection (unstable) | — |
| `nix-darwin` | macOS system management | Yes |
| `home-manager` | User configuration | Yes |
| `flake-parts` | Modular flake architecture | No |
| `niri` | Wayland compositor | Yes |
| `nix-homebrew` | Homebrew management (macOS) | No |
| `sops-nix` | Secrets with age | Yes |
| `nix-amd-npu` | AMD XDNA NPU driver | Yes |
| `nix-ssh-config` | SSH configuration | Yes (+ HM) |
| `crush-config` | AI assistant config | No |
| `nix-colors` | Color schemes | No |
| `silent-sddm` | SDDM theme | Yes |
| `nur` | Nix User Repository | Yes |
| `helium` | Helium browser | Yes |
| `nix-visualize` | Dependency visualization | Yes |
| `otel-tui` | OpenTelemetry TUI viewer | Yes |
| `signoz-src` | SigNoz source (flake=false) | — |
| `signoz-collector-src` | SigNoz collector source (flake=false) | — |
| `homebrew-bundle` | Homebrew taps (flake=false) | — |
| `homebrew-cask` | Homebrew cask taps (flake=false) | — |
