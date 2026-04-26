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
│   ├── homepage.nix             # Service dashboard
│   ├── immich.nix               # Photo/video management
│   ├── photomap.nix             # AI photo exploration
│   ├── signoz.nix               # Observability (traces/metrics/logs)
│   ├── sops.nix                 # Secrets management
│   └── taskchampion.nix         # Taskwarrior sync server
│
├── pkgs/                        # Custom packages
│   ├── aw-watcher-utilization.nix # ActivityWatch system utilization watcher (Python)
│   ├── dnsblockd.nix            # DNS block page server (Go)
│   ├── dnsblockd-processor/     # DNS blocklist processor (Go)
│   ├── emeet-pixyd/             # EMEET PIXY webcam daemon (Go)
│   ├── jscpd.nix                # Copy/paste detector (Node.js)
│   ├── modernize.nix            # Go modernize tool
│   ├── monitor365.nix           # Device monitoring agent (Rust)
│   └── openaudible.nix          # Audible audiobook manager (AppImage)
│
└── platforms/
    ├── common/                  # Shared (~80%)
    │   ├── home-base.nix        # Imports 14 program modules
    │   ├── programs/            # fish, zsh, bash, starship, git, tmux, fzf, taskwarrior, ...
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
        ├── hardware/            # AMD GPU/NPU, Bluetooth, EMEET PIXY
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

Eight overlays are defined in `flake.nix`:

| Overlay | Purpose |
|---------|---------|
| `goOverlay` | Pins Go to 1.26.1 (overrides default) |
| `awWatcherOverlay` | Builds `aw-watcher-utilization` from local nix pkg |
| `jscpdOverlay` | Builds `jscpd` copy/paste detector from npm (all platforms) |
| `dnsblockdOverlay` | Builds `dnsblockd` + `dnsblockd-processor` from local source (Linux only) |
| `emeetPixyOverlay` | Builds `emeet-pixyd` from local source (Linux only) |
| `openaudibleOverlay` | Wraps OpenAudible AppImage (Linux only) |
| `monitor365Overlay` | Builds `monitor365` CLI agent from flake input source (Linux only) |
| `unboundDoQOverlay` | Patches unbound for DNS-over-QUIC support (Linux only) |

Go, aw-watcher-utilization, and jscpd overlays are applied on both platforms. The remaining overlays are Linux-only (applied in NixOS config).

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

### Niri Session Save/Restore (`platforms/nixos/programs/niri-wrapped.nix`)

Crash-recovery system for niri window restoration on the NixOS (evo-x2) machine.

**How it works:**
- **Save** (systemd timer, configurable interval default 60s): Snapshots all niri windows, workspaces, and kitty terminal state to `~/.local/state/niri-session/`
- **Restore** (runs at niri startup via `spawn-at-startup`): Reads snapshot, re-spawns apps on correct workspaces with column widths, floating state, and focus order
- **Fallback**: If no session exists or snapshot is >7 days old (configurable), uses hardcoded default apps

**Saved data:**
- `windows.json` — from `niri msg -j windows` (app_id, pid, workspace_id, is_floating, layout.tile_size, focus_timestamp)
- `workspaces.json` — from `niri msg -j workspaces` (workspace names + IDs)
- `kitty-state.json` — per-kitty-window: PID, args, CWD, child process command + CWD (walks `/proc` tree, uses `tpgid` for foreground process detection)
- `timestamp` — epoch seconds of last save

**Restore features:**
- Workspace-aware: pre-creates named workspaces, spawns each app on correct workspace
- Floating state: restores `is_floating` via `niri msg action move-window-to-floating`
- Column widths: restores via `SetColumnWidth` with proportion calculated from `tile_size / output_width`
- Focus order: uses `focus_timestamp` to identify and refocus the last-active window
- Deduplication: skips non-kitty apps already running (via `pgrep`)
- JSON validation: validates all JSON files before parsing, falls back gracefully if corrupt
- Notification: `notify-send` on successful restore
- Save failure: `OnFailure` triggers critical desktop notification

**Configurable via `let` block:**
- `sessionSaveInterval` — timer interval (default `"60s"`)
- `maxSessionAgeDays` — max age before fallback (default `7`)
- `fallbackApps` — list of `{app_id, args}` for fallback session

**Commands:**
```bash
just session-status       # Show last save time, window count, session age
just session-restore      # Manually trigger session restore
systemctl --user list-timers niri-session-save  # Check save timer
```

### Crush AI Config Deployment

Crush config (`~/.config/crush/`) is a flake input deployed via Home Manager on both platforms:

```nix
# flake.nix input
crush-config.url = "github:LarsArtmann/crush-config";

# Both home.nix files
home.file.".config/crush".source = crush-config;
```

To update: `just update && just switch` (fetches latest crush-config from GitHub).

### SigNoz Observability Pipeline

SigNoz is the sole observability platform (replaces Prometheus + Grafana). Full stack in `modules/nixos/services/signoz.nix`.

**Data pipeline:**
- **node_exporter** (port 9100) → system metrics (CPU, RAM, disk, network, pressure)
- **cAdvisor** (port 9110) → Docker container metrics
- **Caddy** (port 2019) → HTTP request rates, latencies, errors
- **Authelia** (port 9959) → SSO health metrics
- **journald receiver** → service logs from signoz, caddy, immich, gitea, docker, postgresql, authelia
- **OTLP receiver** → traces/metrics/logs from OTel-instrumented apps (ports 4317/4318)

**SigNoz OTel Collector** scrapes all Prometheus exporters via `prometheus` receiver, collects journald logs, and exports everything to ClickHouse.

**Components (all enabled by default):**
| Component | Port | Purpose |
|-----------|------|---------|
| Query Service | 8080 | Web UI + API (`signoz.home.lan`) |
| OTel Collector | 4317/4318 | OTLP ingest + Prometheus scraping + journald |
| ClickHouse | 9000 | Metrics/traces/logs storage |
| node_exporter | 9100 | System metrics |
| cAdvisor | 9110 | Container metrics |

**Configurable via `services.signoz.components`:**
- `queryService` — SigNoz server (default: enabled)
- `otelCollector` — OTel collector + scrapers (default: enabled)
- `clickhouse` — managed ClickHouse (default: enabled)
- `nodeExporter` — node_exporter (default: enabled)
- `cadvisor` — container metrics (default: enabled)

### NixOS DNS Blocker

Custom DNS blocking stack: Unbound (resolver) + dnsblockd (Go block page server).
- 25 blocklists, 2.5M+ domains blocked
- Upstream: Quad9 (DNS-over-TLS) + Cloudflare fallback
- Local `.home.lan` DNS records for all services
- Blocklist source: `platforms/nixos/programs/dnsblockd/`

### DNS Failover Cluster

High-availability DNS via Keepalived VRRP (`modules/nixos/services/dns-failover.nix`).
- Two-node cluster: evo-x2 (primary, priority 100) + Raspberry Pi 3 (backup, priority 50)
- Virtual IP shared between nodes — LAN clients point to VIP, not individual IPs
- Health check: tracks `unbound` process — if unbound dies, node loses VIP
- VRRP garp refresh every 30s for rapid failover detection
- Module options: `services.dns-failover.{enable, virtualIP, interface, priority, routerID, subnetPrefix, authPassword}`
- Pi 3 image built via `nixosConfigurations.rpi3-dns` in flake.nix
- **Status**: Planned — Pi 3 hardware not yet provisioned

### Taskwarrior + TaskChampion Sync

Task management synced across NixOS, macOS, and Android via TaskChampion sync server.
- Server: `services.taskchampion-sync-server` on NixOS (port 10222, behind Caddy at `tasks.home.lan`)
- Client: Taskwarrior 3 via Home Manager (`platforms/common/programs/taskwarrior.nix`)
- Android: TaskStrider (Play Store, supports TaskChampion sync)
- Sync URL: `https://tasks.home.lan`
- No forward auth — TaskChampion uses client ID allowlisting + client-side encryption
- **Zero manual setup**: client IDs derived deterministically from `username@platform` via SHA-256, encryption secret is a shared deterministic hash. `just switch && task sync` just works.
- Per-device client ID: `sha256("taskchampion-${username}@${system}")` formatted as UUID
- Shared encryption secret: `sha256("taskchampion-sync-encryption-systemnix")` (same on all devices)

AI agent task tracking protocol:
- Tag `+agent` for AI-created/tracked tasks
- UDA `source` identifies the originating agent (e.g., `source:crush`)
- Report: `task report.agent` shows agent tasks
- Quick add: `just task-agent "description"` adds task with `+agent source:crush`
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

# Niri session
just session-status       # Show session save state (last save, window count, age)
just session-restore      # Manually trigger session restore

# Recovery
just rollback           # Revert to previous generation
just backup / just restore NAME
```

### EMEET PIXY Webcam (`pkgs/emeet-pixyd/`)

Custom Go daemon for the EMEET PIXY dual-camera AI webcam with auto-activation:

| Component | Path | Purpose |
|-----------|------|---------|
| Daemon | `pkgs/emeet-pixyd/` | Go binary — call detection, HID control, auto-management |
| Package | `pkgs/emeet-pixyd.nix` | buildGoModule derivation |
| NixOS module | `platforms/nixos/hardware/emeet-pixy.nix` | udev rules, user systemd service |
| Waybar | `platforms/nixos/desktop/waybar.nix` | Camera state indicator |

**Architecture:**
- User-level systemd service (inherits Wayland + pipewire session env)
- Call detection: scans `/proc/*/fd` for any process holding the video device open
- Auto-actions: face tracking + noise cancellation on call start, privacy mode on call end
- Auto-switches PipeWire default source to PIXY on call start
- Desktop notifications via `notify-send` on state changes
- Systemd watchdog (`WatchdogSec=30`) prevents hung daemon
- Structured logging via `slog` (leveled: debug/info/warn/error)
- Waybar click toggles privacy, right-click enables tracking, middle-click centers
- Device auto-detection by USB vendor/product ID (`328f:00c0`), not hardcoded
- Hotplug recovery: re-probes on error, recovers when camera reconnected
- Boot default: privacy mode (camera physically disabled until needed)
- Configurable via `Config` struct (poll interval, debounce count, state dir)
- Type-safe HID commands via `CameraState.HIDByte()` / `AudioMode.HIDByte()` methods
- Socket permissions 0600 (user-only, not world-writable)
- HID state querying via bidirectional hidraw (reads camera's actual tracking/audio/gesture state)
- State sync on startup + `sync` command to reconcile believed state with camera reality

```bash
# Camera commands
just cam-status          # Show camera state
just cam-privacy         # Toggle privacy mode
just cam-track           # Enable face tracking
just cam-reset           # Center camera (pan/tilt/zoom)
just cam-audio           # Cycle audio: nc → live → org → nc
just cam-audio <mode>    # Set audio: nc, live, org
just cam-sync           # Sync daemon state with camera
just cam-restart         # Restart daemon (user service)
just cam-logs            # View daemon logs

# Direct daemon commands (either emeet-pixyd or emeet-pixy works)
emeet-pixy status           # Full status
emeet-pixy toggle-privacy   # Toggle privacy
emeet-pixy probe            # Re-detect device
emeet-pixy sync             # Sync state from camera
emeet-pixy audio            # Cycle audio mode
```

### Hermes AI Agent Gateway (`modules/nixos/services/hermes.nix`)

Declarative NixOS module for the Hermes AI agent gateway (Discord bot, cron scheduler, messaging).

| Component | Path | Purpose |
|-----------|------|---------|
| NixOS module | `modules/nixos/services/hermes.nix` | flake-parts module — system service, tmpfiles, user/group |
| Secrets | `platforms/nixos/secrets/hermes.yaml` | sops-encrypted API keys |
| Config | `/var/lib/hermes/config.yaml` | Hermes runtime config (NOT in repo — Hermes writes at runtime) |
| Env | `/var/lib/hermes/.env` | Merged from sops template at service start (secrets + non-secret env) |

**Architecture:**
- Installed via flake input `hermes-agent` (pinned in `flake.lock`)
- System-level systemd service (`systemd.services.hermes`) targeting `multi-user.target` — starts at boot without login
- Dedicated system user/group (`hermes`/`hermes`) with state at `/var/lib/hermes`
- Secrets decrypted by sops-nix template → merged into `.env` by `mergeEnvScript` (ExecStartPre) → Hermes reads `.env` at runtime via `load_hermes_dotenv`
- `libopus` installed system-wide for Discord voice support (in `configuration.nix`)
- `key_env` references in `config.yaml` read API keys from `.env` instead of inline plaintext

**Module options (`services.hermes`):**
| Option | Default | Description |
|--------|---------|-------------|
| `enable` | false | Enable the gateway |
| `user` | "hermes" | System user |
| `group` | "hermes" | System group |
| `stateDir` | "/var/lib/hermes" | State directory |
| `restartSec` | "5" | Restart delay after failure |
| `timeoutStopSec` | "120" | Graceful shutdown timeout |

**Sops secrets (`hermes.yaml`):**
- `hermes_discord_bot_token` — Discord bot token
- `hermes_glm_api_key` — Z.AI/GLM API key
- `hermes_minimax_api_key` — MiniMax API key
- `hermes_fal_key` — fal.ai image generation key
- `hermes_firecrawl_api_key` — Firecrawl web scraping key

```bash
# Hermes commands
just hermes-status        # Show gateway status
just hermes-restart       # Restart gateway service
just hermes-logs          # View gateway logs
hermes gateway status     # Check gateway state
hermes model              # Change default model
hermes cron list          # List cron jobs
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
| `hermes-agent` | AI agent gateway (Discord, cron) | Yes |
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
