# SystemNix: AGENT GUIDE


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
│   ├── jscpd.nix                # Copy/paste detector (Node.js)
│   ├── modernize.nix            # Go modernize tool
│   ├── monitor365.nix           # Device monitoring agent (Rust)
│   ├── netwatch.nix             # Real-time network diagnostics TUI (Rust)
│   ├── openaudible.nix          # Audible audiobook manager (AppImage)
│   ├── golangci-lint-auto-configure.nix # golangci-lint auto-configurator (Go)
│   ├── mr-sync.nix              # ~/.mrconfig GitHub sync CLI (Go)
│   └── file-and-image-renamer.nix # AI screenshot renaming (Go)
│
│   # External flake inputs (packages via overlay — no local pkgs/ file)
│   # emeet-pixyd             — EMEET PIXY webcam daemon
│   # todo-list-ai            — AI-powered TODO extraction CLI
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

All private LarsArtmann repos use `git+ssh://git@github.com/LarsArtmann/<name>?ref=<branch>` for flake inputs. No `path:` inputs exist — the flake is fully portable.

**Naming convention:** `-src` suffix = `flake = false` (source-only). No suffix = full flake.

**Active overlays:**
- `sharedOverlays` — applied on Darwin + NixOS (NUR, aw-watcher, todo-list-ai, golangci-lint-auto-configure, mr-sync)
- `linuxOnlyOverlays` — NixOS only (openaudible, dnsblockd, emeet-pixyd, monitor365, netwatch, file-and-image-renamer)
- `disableTestsOverlay` — disables flaky tests for valkey, aiocache
- `pythonTestOverlay` — NixOS-specific Python test overrides

**Rule:** Never override `vendorHash` from outside a package. Each repo owns its own hash.

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

**Source files:**
- `scripts/niri-session-save.sh` — save logic (read niri state + kitty /proc tree)
- `scripts/niri-session-restore.sh` — restore logic (JSON validation, workspace recreation, window spawning)
- `platforms/nixos/programs/niri-wrapped.nix` — NixOS module wrapping scripts via `writeShellApplication` + `builtins.readFile`

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

**Configurable via `services.niri-session` module options:**
- `sessionSaveInterval` — timer interval (default `"60s"`)
- `maxSessionAgeDays` — max age before fallback (default `7`)
- `fallbackApps` — list of `{app_id, args}` for fallback session

**Commands:**
```bash
just session-status       # Show last save time, window count, session age
just session-restore      # Manually trigger session restore
systemctl --user list-timers niri-session-save  # Check save timer
```

### Wallpaper Self-Healing (`scripts/wallpaper-set.sh`)

Automatic wallpaper management with daemon crash recovery:

**Source files:**
- `scripts/wallpaper-set.sh` — wallpaper setter (random/restore modes, daemon wait loop)
- `platforms/nixos/programs/niri-wrapped.nix` — awww-daemon + awww-wallpaper systemd services

**Self-healing architecture:**
- `awww-daemon`: `Restart=always` — systemd auto-restarts after BrokenPipe crash (upstream awww 0.12.0 bug)
- `awww-wallpaper`: `PartOf=["awww-daemon.service"]` — **automatically restarted by systemd when daemon restarts** (no bash supervisor loop)
- On daemon crash recovery: uses `awww restore` to restore last displayed image (preserves user choice)
- On first boot / `Mod+W`: picks random wallpaper from `~/.local/share/wallpapers/`
- Wallpaper script waits up to 60s for daemon socket before setting

**Do NOT use `BindsTo`** — it kills the wallpaper service when the daemon crashes, preventing recovery. `PartOf` is correct: it propagates restarts without killing. This was a bug introduced in `029a911` that caused permanent wallpaper loss on daemon crash.

### Crush AI Config Deployment

Crush config (`~/.config/crush/`) is a flake input deployed via Home Manager on both platforms:

```nix
# flake.nix input (SSH URL for private repo)
crush-config.url = "git+ssh://git@github.com/LarsArtmann/crush-config?ref=master";

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

### Network Configuration (`platforms/nixos/system/local-network.nix`)

Shared IP addresses defined as `networking.local` module options:
- `networking.local.lanIP` (default: 192.168.1.150) — evo-x2 LAN IP
- `networking.local.gateway` (default: 192.168.1.1) — default gateway
- `networking.local.subnet` (default: 192.168.1.0/24) — LAN subnet
- `networking.local.blockIP` (default: 192.168.1.200) — DNS block page IP
- `networking.local.virtualIP` (default: 192.168.1.53) — VRRP virtual IP
- `networking.local.piIP` (default: 192.168.1.151) — Pi 3 backup DNS IP

Both `evo-x2` and `rpi3-dns` import this module. Changing the subnet only requires updating `local-network.nix` defaults.

### DNS Failover Cluster

High-availability DNS via Keepalived VRRP (`modules/nixos/services/dns-failover.nix`).
- Two-node cluster: evo-x2 (primary, priority 100) + Raspberry Pi 3 (backup, priority 50)
- Virtual IP shared between nodes — LAN clients point to VIP, not individual IPs
- Health check: tracks `unbound` process — if unbound dies, node loses VIP
- VRRP garp refresh every 30s for rapid failover detection
- Module options: `services.dns-failover.{enable, virtualIP, interface, priority, routerID, subnetPrefix, authPassword}`
- Pi 3 image built via `nixosConfigurations.rpi3-dns` in flake.nix
- **Status**: Planned — Pi 3 hardware not yet provisioned

### Centralized AI Model Storage (`modules/nixos/services/ai-models.nix`)

Unified directory structure for ALL AI models and tool data on NixOS (evo-x2).

**Directory tree (`/data/ai/`):**
```
/data/ai/
├── models/
│   ├── ollama/         → Ollama service home + model blobs
│   ├── gguf/           → LLaMA.cpp standalone models
│   ├── whisper/        → Whisper ASR models
│   ├── comfyui/        → ComfyUI checkpoints/Loras
│   ├── jan/            → Jan AI data (symlinked from ~/.config/Jan/data)
│   ├── vision/         → Vision models (CLIP, etc)
│   ├── image/          → Image generation models
│   ├── embeddings/     → Embedding models
│   └── tts/            → Text-to-speech models
├── cache/
│   └── huggingface/    → HuggingFace Hub + Transformers cache
└── workspaces/
    └── unsloth/        → Unsloth Studio venv + workspace
```

**How it works:**
- `services.ai-models.enable = true` creates all directories via `systemd.tmpfiles.rules`
- `services.ai-models.paths` attrset provides derived paths for all modules to reference
- Environment variables (`OLLAMA_MODELS`, `HF_HOME`, `LLAMA_MODEL_PATH`, etc.) are set system-wide
- All AI services (Ollama, Whisper, ComfyUI, Unsloth) reference `config.services.ai-models.paths.*`
- Jan AI data folder is symlinked via Home Manager activation (`~/.config/Jan/data` → `/data/ai/models/jan`)

**Module options (`services.ai-models`):**
| Option | Default | Description |
|--------|---------|-------------|
| `enable` | false | Enable centralized AI storage |
| `baseDir` | "/data/ai" | Root directory for all AI data |
| `user` | "lars" | File owner |
| `group` | "users" | File group |
| `paths` | (derived) | Attrset of all tool-specific paths |

**Migration:**
```bash
just ai-migrate    # Move legacy /data/{models,cache,unsloth} → /data/ai/
just ai-status     # Show current storage status
```

**Migration MUST happen BEFORE `just switch`** if you have existing models at `/data/models/`.

**Key files:**
- Module: `modules/nixos/services/ai-models.nix`
- Enabled in: `platforms/nixos/system/configuration.nix`
- Jan symlink: `platforms/nixos/users/home.nix` (home.activation)
- Refactored consumers: `ai-stack.nix`, `voice-agents.nix`, `comfyui.nix`

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
| Darwin overlays | Darwin uses `sharedOverlays` directly (no Linux-only overlays). perSystem applies the same shared + Linux-only overlays. No Go overlay — uses nixpkgs default. |
| NixOS overlays separate | NixOS adds `niri.overlays.niri`, `dnsblockdOverlay`, and Python overrides on top of the shared ones |
| SigNoz built from source | SigNoz is built from source (Go 1.25), not from a pre-built package. Takes significant build time. |
| crush-config doesn't follow nixpkgs | The crush-config input intentionally does NOT follow nixpkgs (no `inputs.nixpkgs.follows`) |
| Theme everywhere | Catppuccin Mocha is the universal theme — all apps, terminals, bars, login screen |
| SSH config is external | SSH configuration comes from `nix-ssh-config` flake input, not defined locally |
| Secrets via sops-nix | Secrets are age-encrypted using the SSH host key. Managed in `modules/nixos/services/sops.nix` |
| BTRFS dual layout | Root uses zstd compression, `/data` uses zstd:3 with async discard. Docker lives on `/data`. |
| Niri BindsTo patched | Upstream niri.service uses `BindsTo=graphical-session.target` — we replace with `PartOf` + `Restart=always` in `niri-config.nix`. Without this, `just switch` kills niri permanently. |
| awww-daemon BrokenPipe | Upstream awww 0.12.0 panics on BrokenPipe at `daemon/src/main.rs:712:32` (Wayland disconnect during suspend/output hotplug). `Restart=always` covers it. Never use `BindsTo` for wallpaper services — use `PartOf` for restart propagation. |

### lib/systemd Shared Helpers

Two reusable functions in `lib/systemd/`:

| File | Purpose | Usage |
|------|---------|-------|
| `lib/systemd.nix` | Security hardening (PrivateTmp, NoNewPrivileges, ProtectSystem, etc.) | `harden = import ../../../lib/systemd.nix;` then `harden {MemoryMax = "512M";}` |
| `lib/systemd/service-defaults.nix` | Common service defaults (Restart, RestartSec, StartLimitBurst) | `serviceDefaults = import ../../../lib/systemd/service-defaults.nix;` then `serviceDefaults {}` |

Combining: `serviceConfig = harden {MemoryMax = "1G";} // serviceDefaults {};`

### WatchdogSec / sd_notify Rules

**`WatchdogSec` is ONLY valid for services that implement `sd_notify()` (i.e., `Type = "notify"`).** Setting it on services that don't call `sd_notify()` causes systemd to kill them after the timeout — even though they're running perfectly fine.

**Services that support sd_notify (Type=notify, safe to use WatchdogSec):**
- Caddy (`modules/nixos/services/caddy.nix`)
- Gitea (`modules/nixos/services/gitea.nix`)

**Services that do NOT support sd_notify (NEVER set WatchdogSec):**
- All Python services: Hermes, ComfyUI, Immich ML
- All Node.js services: Homepage, Immich server
- Go services without explicit sd_notify: SigNoz, Authelia, cadvisor, EMEET PIXY
- Rust services without explicit sd_notify: TaskChampion

**Rule:** If a service isn't `Type = "notify"`, do NOT set `WatchdogSec`. The `serviceDefaults` function does NOT include `WatchdogSec` for this reason — pass it explicitly only for sd_notify-capable services.

## Known Issues

| Issue | Workaround | Status |
|-------|-----------|--------|
| Darwin HM user definition | Explicit `users.users.larsartmann` in darwin/default.nix | Workaround applied |
| mkMerge + flake-parts | Use inline config or imports instead of `lib.mkMerge` | Accepted limitation |
| `wire` not in Nixpkgs | Installed via `go install` (see `go-update-tools-manual` just recipe) | Accepted |
| AI model migration order | Run `just ai-migrate` BEFORE `just switch` to avoid Ollama seeing empty model dir | Documented |
| Go overlay removed on Darwin | nixpkgs `go_1_26` is already 1.26.1; overlay was invalidating 1094 binary cache derivations | Resolved — removed |
| GPU hang recovery | Hermes anime-comic-pipeline (PyTorch/ROCm) SIGSEGV → GPU driver hang → entire desktop frozen. Defense in depth: `kernel.sysrq=1` (REISUB), `kernel.panic=30`, `softlockup_panic=1`, `hung_task_panic=1`, `watchdogd` (SP5100 TCO), `amdgpu.gpu_recovery=1`. See `boot.nix`. | Resolved |

## Essential Commands

```bash
# Core
just setup              # Initial setup after clone
just switch             # Apply config (detects platform automatically)
just update             # Update flake inputs
just test-fast          # Syntax-only validation (fast)
just test               # Full build validation (slow)
just format             # Format with treefmt + alejandra
just health             # Cross-platform health check (Nix, flake, direnv, shell, systemd, disk, memory)
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

# Wallpaper (self-healing)
just wallpaper-status     # Show daemon health, image count, outputs
just wallpaper-random     # Set random wallpaper
just wallpaper-restore    # Restore last displayed wallpaper
just wallpaper-restart    # Restart daemon + wallpaper service
just wallpaper-logs       # Show daemon logs (last 50 lines)

# AI Models
just ai-migrate           # Migrate legacy AI data → /data/ai/ (run BEFORE switch)
just ai-status            # Show AI model storage status

# todo-list-ai
just todo-scan             # Extract TODOs from current directory (default: mock)
just todo-scan-openai DIR  # Extract TODOs with OpenAI
just todo-scan-mock DIR    # Extract TODOs with mock provider
just todo-version          # Show todo-list-ai version

# golangci-lint-auto-configure
just lint-configure           # Auto-configure golangci-lint for current project
just lint-configure-version   # Show golangci-lint-auto-configure version

# Recovery
just rollback           # Revert to previous generation
just backup / just restore NAME
```

### EMEET PIXY Webcam (`emeet-pixyd` flake input)

Custom Go daemon for the EMEET PIXY dual-camera AI webcam with auto-activation:

| Component | Path | Purpose |
|-----------|------|---------|
| Package | `emeet-pixyd` flake input overlay | buildGoModule derivation (no local pkgs/ file) |
| NixOS module | `platforms/nixos/hardware/emeet-pixy.nix` | udev rules, user systemd service |
| NixOS module | `inputs.emeet-pixyd.nixosModules.default` | flake-provided NixOS module |
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
| Config | `/home/hermes/config.yaml` | Hermes runtime config (NOT in repo — Hermes writes at runtime) |
| Env | `/home/hermes/.env` | Merged from sops template at service start (secrets + non-secret env) |

**Architecture:**
- Installed via flake input `hermes-agent` (pinned in `flake.lock`)
- System-level systemd service (`systemd.services.hermes`) targeting `multi-user.target` — starts at boot without login
- Dedicated system user/group (`hermes`/`hermes`) with state at `/home/hermes`
- `binutils` in service PATH for `ctypes.util.find_library` opus resolution on NixOS
- `GATEWAY_ALLOW_ALL_USERS=true` — all Discord users can interact with the bot
- Auto-migrates state from `/home/lars/.hermes` or `/var/lib/hermes` on first start
- Secrets decrypted by sops-nix template → merged into `.env` by `mergeEnvScript` (ExecStartPre) → Hermes reads `.env` at runtime via `load_hermes_dotenv`
- `libopus` installed system-wide for Discord voice support (in `configuration.nix`)
- `key_env` references in `config.yaml` read API keys from `.env` instead of inline plaintext

**Module options (`services.hermes`):**
| Option | Default | Description |
|--------|---------|-------------|
| `enable` | false | Enable the gateway |
| `user` | "hermes" | System user |
| `group` | "hermes" | System group |
| `stateDir` | "/home/hermes" | State directory |
| `restartSec` | "5" | Restart delay after failure |
| `timeoutStopSec` | "120" | Graceful shutdown timeout |

**Sops secrets (`hermes.yaml`):**
- `hermes_discord_bot_token` — Discord bot token
- `hermes_glm_api_key` — Z.AI/GLM API key
- `hermes_minimax_api_key` — MiniMax API key
- `hermes_xiaomi_api_key` — Xiaomi MiMo API key
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
| `todo-list-ai` | AI-powered TODO extraction CLI | Yes |
| `golangci-lint-auto-configure-src` | golangci-lint auto-configurator (flake=false) | — |
| `go-finding-src` | go-finding library (flake=false) | — |
| `homebrew-bundle` | Homebrew taps (flake=false) | — |
| `homebrew-cask` | Homebrew cask taps (flake=false) | — |
| `monitor365-src` | Device monitoring agent source (flake=false) | — |
| `mr-sync-src` | ~/.mrconfig GitHub sync CLI (flake=false) | — |
| `wallpapers-src` | Wallpaper collection (flake=false) | — |
| `file-and-image-renamer-src` | AI screenshot renamer source (flake=false) | — |
| `cmdguard-src` | Go command guard library (flake=false) | — |
| `go-output-src` | Go output library (flake=false) | — |
| `nixos-hardware` | Hardware profiles (RPi, etc.) | No |
| `emeet-pixyd` | EMEET PIXY webcam daemon | Yes |
| `treefmt-full-flake` | Treefmt formatter | Yes |

**All LarsArtmann private repos use `git+ssh://` URLs.** No `path:` inputs remain.
