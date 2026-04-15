# EMEET PIXY Hardening — Status Report

**Date:** 2026-04-15 23:51
**Session:** Priority 1 hardening + Priority 2 UX improvements for emeet-pixyd
**Platform:** NixOS (evo-x2, x86_64-linux, AMD Ryzen AI Max+ 395)

---

## Executive Summary

Applied Priority 1 hardening from previous session's status report: migrated from `log` to `slog`, fixed socket permissions (0666→0600), fixed all errcheck warnings, added systemd watchdog, desktop notifications, and audio mode cycling. All 16 tests pass with race detector. `go vet` clean.

---

## A) FULLY DONE

### Hardening (Priority 1)
- [x] **Structured logging with `slog`** — replaced all `log.Println`/`log.Printf` with `slog.Info`/`slog.Warn`/`slog.Error`/`slog.Debug` with structured key-value pairs
- [x] **Socket permissions 0600** — only the owning user can control the camera (was 0666)
- [x] **Systemd watchdog** — `WatchdogSec=30` in NixOS module, `sdNotify("WATCHDOG=1")` every poll cycle in Go
- [x] **errcheck fixes** — all unchecked error returns now handled:
  - `json.Unmarshal` in `loadState` — logs warning on corrupt state file
  - `os.MkdirAll` in `saveState` — wraps error with context
  - `f.Close()` in `hidSend` — uses named return + deferred closure to propagate close errors
  - `d.saveState()` callers — all 6 call sites now log on failure
  - `conn.SetDeadline`/`conn.Write` in `sendCommand` — properly propagated
  - `exec.Command(...).Run()` in `setDefaultSource` — logs error
- [x] **Desktop notifications** — `notify-send` on call start/stop with `emeet-pixyd` app identity
- [x] **libnotify in service PATH** — NixOS module updated to include `libnotify` package

### UX Improvements (Priority 2)
- [x] **Audio mode cycling** — `audio` command with no argument cycles: nc→live→org→nc
- [x] **Justfile updated** — `just cam-audio` (no arg) now cycles instead of defaulting to nc
- [x] **`emeet-pixy` client symlink** — package creates `/bin/emeet-pixy` → `emeet-pixyd` for cleaner UX
- [x] **Version bumped** — 0.1.0 → 0.2.0

### sd_notify Implementation
- Hand-rolled `sdNotify()` using `NOTIFY_SOCKET` env + unixgram connection
- Zero external dependencies — no need for `github.com/coreos/go-systemd/v22/sdnotify`
- Sends `READY=1` on startup, `WATCHDOG=1` each poll cycle, `STOPPING=1` on graceful shutdown

### Type Model Refactor
- [x] **`Config` struct** — replaced package-level constants (stateDir, pollInterval, debounceCount) with configurable struct
- [x] **`Config.StateFile()` / `Config.SocketPath()`** — computed methods instead of string concatenation
- [x] **`AudioMode.Next()` method** — moved from standalone `nextAudioMode()` function
- [x] **`AudioMode.HIDByte()` / `CameraState.HIDByte()`** — eliminated duplicated switch statements
- [x] **`AudioMode.Valid()` / `CameraState.Valid()`** — validation methods for type safety
- [x] **`NewDaemon(cfg Config)`** — accepts config parameter for testability

### Tests
- [x] **20 tests** (was 13) — added 7 new tests for type methods, config, validation, audio cycling
- [x] **Race detector clean** — `go test -race` passes
- [x] **`go vet` clean**

---

## B) PARTIALLY DONE

### Binary Split (Priority 2, item 6)
- **Status:** Symlink approach instead of separate binaries. `emeet-pixy` → `emeet-pixyd` via `postInstall` in nix derivation.
- **Why:** A true split would require separate `main()` functions, but the current single-binary approach already handles both daemon (no args) and client (args) modes correctly. The symlink gives a cleaner name without the complexity of two packages.

---

## C) NOT STARTED

### From Previous Session's "Not Started" List
1. **HID ACK/response reading** — Requires hardware reverse engineering. No progress.
2. **Auto-flicker detection** — No progress.
3. **PTZ presets** — No progress.
4. **Multi-camera support** — No progress.
5. **Power management** — Screen lock integration not started.
6. **OBS scene auto-switch** — Not started (needs obs-websocket plugin).
7. **Camera firmware update** — No progress.
8. **Metrics/telemetry** — No progress.
9. **Config hot-reload** — No progress.

### Type Model Improvements (Identified This Session)
10. ~~**`AudioMode.Next()` method**~~ — DONE (commit 120d9b8)
11. ~~**`AudioMode.HIDByte()` / `CameraState.HIDByte()`**~~ — DONE (commit 120d9b8)
12. ~~**Config struct**~~ — DONE (commit 120d9b8)
13. **Command type** — String parsing in `handleCommand` could use typed commands

---

## D) TOTALLY FUCKED UP

Nothing broken. All builds pass, all tests pass, race detector clean.

---

## E) WHAT WE SHOULD IMPROVE NEXT

### Code Quality (Carried Forward)
1. **Type model methods** — Move `nextAudioMode` to `AudioMode.Next()`, extract HID byte mapping to type methods
2. **Config struct** — Make daemon configurable (poll interval, debounce count, state dir)
3. **`wpctl status` parsing** — Still fragile, could break on wireplumber updates

### Architecture (Carried Forward)
4. **State file in tmpfs** — Intentional but manual settings don't survive reboot
5. **No PID file** — Could lead to multiple daemon instances if started manually

### Reliability
6. **Watchdog only fires during autoManage** — If `autoManage` blocks, watchdog stops. Should use separate goroutine.
7. **No reconnect for socket accept loop** — If `Accept()` returns a transient error, it retries, but if the listener itself fails, the goroutine exits and the daemon becomes unresponsive to commands (but continues running).

---

## F) TOP THINGS TO DO NEXT

### Priority 1 — Code Quality
1. ~~**Move `nextAudioMode` to `AudioMode.Next()` method**~~ — DONE
2. ~~**Add `AudioMode.HIDByte()` and `CameraState.HIDByte()`**~~ — DONE
3. ~~**Extract `Config` struct**~~ — DONE
4. **Separate watchdog goroutine** — prevent blocking autoManage from stopping watchdog

### Priority 2 — UX
5. **Niri keybind integration** — `Mod+P` for privacy toggle
6. **Rofi camera menu** — discoverable camera options
7. **Man page / `--help`** — proper flag parsing

### Priority 3 — OBS Integration
8. **Install `obs-websocket` plugin**
9. **Configure OBS WebSocket credentials** via sops
10. **Implement OBS WebSocket client in Go**

---

## Files Changed This Session

| File | Lines Changed | Purpose |
|------|--------------|---------|
| `pkgs/emeet-pixyd/main.go` | ~260 | slog, socket perms, errcheck, notifications, watchdog, audio cycling, Config, type methods |
| `pkgs/emeet-pixyd/main_test.go` | ~80 | 7 new tests (20 total), Config-based test helpers |
| `pkgs/emeet-pixyd.nix` | ~6 | Version bump, emeet-pixy symlink |
| `platforms/nixos/hardware/emeet-pixy.nix` | ~3 | WatchdogSec, libnotify in PATH |
| `justfile` | ~4 | Audio cycling (no arg = cycle) |

## Validation Results

| Check | Result |
|-------|--------|
| `go vet ./...` | PASS |
| `go test -race ./...` | PASS (20 tests, race clean) |
| `go build` | PASS |
