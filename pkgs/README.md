# Custom Packages

Custom Nix package definitions used across SystemNix. All packages are built via overlays in `flake.nix` and exposed as flake outputs.

## Packages

| Package | Language | Platform | Description |
|---------|----------|----------|-------------|
| [dnsblockd](#dnsblockd) | Go | Linux | DNS block page HTTP server |
| [dnsblockd-processor](#dnsblockd-processor) | Go | Linux | Blocklist processor for dnsblockd |
| [emeet-pixyd](#emeet-pixyd) | Go | Linux | EMEET PIXY webcam auto-activation daemon |
| [modernize](#modernize) | Go | All | Go code modernize linter |
| [jscpd](#jscpd) | Node.js | All | Copy/paste detector for source code |
| [aw-watcher-utilization](#aw-watcher-utilization) | Python | All | ActivityWatch system utilization watcher |
| [monitor365](#monitor365) | Rust | Linux | Personal device monitoring agent |
| [openaudible](#openaudible) | AppImage | Linux | Audible audiobook manager |

---

### dnsblockd

Lightweight HTTP server that serves block pages for DNS-filtered domains. Paired with Unbound DNS resolver to provide visual feedback when a blocked domain is accessed.

- **Source:** `dnsblockd.nix` (derivation) + inline Go source in flake
- **Platform:** Linux only
- **Config:** `platforms/nixos/system/dns-blocker-config.nix`

### dnsblockd-processor

CLI tool that converts DNS blocklists (hosts, domains, dnsmasq, adblock formats) into Unbound `local-data` entries and a domain-to-list mapping JSON file. Run during NixOS activation to regenerate the block list.

- **Source:** `dnsblockd-processor/` (standalone Go module, no dependencies)
- **Platform:** Linux only
- **Usage:** `dnsblockd-processor BLOCK_IP WHITELIST_FILE UNBOUND_OUTPUT MAPPING_OUTPUT [LIST_FILE NAME]...`

### emeet-pixyd

Auto-activation daemon for the EMEET PIXY dual-camera AI webcam. Detects video call usage via `/proc` scanning and automatically enables face tracking + noise cancellation on call start, privacy mode on call end. Includes a web UI and Waybar integration.

- **Source:** `emeet-pixyd/` (Go module)
- **Platform:** Linux only
- **Config:** `platforms/nixos/hardware/emeet-pixy.nix` (NixOS module, udev rules)
- **Binary alias:** `emeet-pixyd` and `emeet-pixy` both work

### modernize

Builds the `modernize` analysis pass from `golang.org/x/tools` with Go 1.26. Detects Go code that can use newer language features.

- **Source:** `modernize.nix` (fetches from `golang/tools` repo)
- **Platform:** All platforms
- **Install:** Available as `nix build .#modernize`

### jscpd

Copy/paste detector for programming source code — finds duplicated code across 150+ languages. Used in the project devShell.

- **Source:** `jscpd.nix` (npm package, vendored lockfile in `jscpd-package-lock.json`)
- **Platform:** All platforms
- **Install:** Available in devShell via `nix develop`

### aw-watcher-utilization

Monitors CPU, RAM, disk, network, and sensor usage, reporting to ActivityWatch. Fork build from [Alwinator/aw-watcher-utilization](https://github.com/Alwinator/aw-watcher-utilization) with modernized poetry build.

- **Source:** `aw-watcher-utilization.nix` (Python, fetched from GitHub)
- **Platform:** All platforms
- **Config:** `platforms/darwin/services/launchagents.nix` (macOS LaunchAgent)

### monitor365

Cross-platform personal device monitoring system agent. Rust CLI that collects system metrics via a plugin architecture. NixOS module available at `modules/nixos/services/monitor365.nix` (currently disabled).

- **Source:** `monitor365.nix` (Rust, source from `monitor365-src` flake input)
- **Platform:** Linux only
- **Builds:** Only the CLI agent binary (`--package monitor365-cli`)

### openaudible

Desktop application for managing Audible audiobooks. Wrapped AppImage.

- **Source:** `openaudible.nix` (AppImage, unfree)
- **Platform:** Linux only (x86_64)
- **Install:** Included in `platforms/common/packages/base.nix` for Linux

## Adding a New Package

1. Create `pkgs/<name>.nix` (or `pkgs/<name>/` directory with `package.nix`)
2. Add an overlay in `flake.nix` (follow existing patterns)
3. Add to the `packages` attrset in the `perSystem` block
4. Add to the appropriate overlay list (shared or Linux-only)
