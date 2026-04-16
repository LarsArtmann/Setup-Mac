# emeet-pixyd: Lint & Refactor Status Report

**Date:** 2026-04-16 22:17
**HEAD:** `9c62a31` — refactor(emeet-pixyd): extract command handlers, centralize response constants
**Working tree:** CLEAN
**Remote:** `origin/master` at `9c62a31` (force-pushed to replace corrupted history)
**Remote URL:** `git@github.com:LarsArtmann/SystemNix.git`

---

## a) FULLY DONE

### Git Recovery & Stabilization
1. Recovered from git corruption caused by `perl -pi` newline stripping in previous sessions
2. Resolved merge conflict in `handlers.go` from interrupted interactive rebase
3. Restored clean state from `e552a47`
4. Force-pushed to replace corrupted remote history with clean linear history

### Type-Safe Refactoring (`internal/pixy/pixy.go`)
- Introduced `CameraState` typed string with constants: `StateTracking`, `StatePrivacy`, `StateIdle`, `StateOffline`
- Introduced `AudioMode` typed string with constants: `AudioNC`, `AudioLive`, `AudioOriginal`
- Added `ParseCameraState()` and `ParseAudioMode()` with validation
- Added `AudioMode.Next()` for cycling nc→live→org→nc
- Re-exported via type aliases in `main.go` for test access

### Error Handling Improvements
- Added device/control context to `v4l2Get` and `hidSendRecv` errors
- Added `context.Context` parameter to `pixy.SendCommand` signature
- Updated all call sites

### Command Handler Extraction (main.go)
Extracted 6 methods from the monolithic `handleCommand` (was ~150 lines, now a slim dispatcher):
- `handleTrackingCommand` — camera state transitions
- `handleAudioCommand` — audio mode cycling
- `handleGestureCommand` — gesture toggle
- `handleCenterCommand` — camera centering
- `handleAutoCommand` — auto mode toggle
- `handlePTZCommand` — pan/tilt/zoom control

### Constants & DRY
- Response string constants: `respAutoModeOff`, `respAutoModeOn`, `respAudioUsage`, `respDeviceNotFound`
- Command string constants: `cmdGestureOn`, `cmdAutoOn`
- Test device path constants: `testVideoDev`, `testHIDDev`
- Consolidated symmetric `auto-on`/`auto-off` and `gesture-on`/`gesture-off` handlers

### Test Improvements
- Comprehensive unit tests for `internal/pixy` package
- Generic `assertOptField[T comparable]` helper — eliminates 10 repetitive nil-check patterns
- `assertParseResult` helper — reduces test function length
- Replaced all hardcoded device paths and response strings with constants

### Formatting
- `gci` import ordering across all files
- `gocritic` `else-if` pattern fixes
- `godoclint` comment fixes
- `goconst` string literal consolidation

### Commits (chronological, newest first)
| Commit | Description |
|--------|-------------|
| `9c62a31` | Extract command handlers, centralize response constants |
| `aabec84` | Consolidate auto-on/auto-off handlers and DRY test assertions |
| `d36271d` | Add context parameter to SendCommand call sites |
| `f7f8412` | Type-safe CameraState and AudioMode in webStatus |
| `5c48fb2` | Add device/control context to v4l2Get and hidSendRecv errors |
| `7d46137` | Add comprehensive unit tests for internal/pixy package |
| `a378105` | Add *.tmp pattern to .gitignore |
| `24d892f` | Extract PTZ constants and improve variable naming in handlers |
| `8f70b95` | Add video streaming upgrade status report |
| `e552a47` | Remove unused .ptz-slider.sending CSS |

---

## b) PARTIALLY DONE

**Nothing partially done.** All committed work is complete and verified with `go build ./...` and `go test -count=1 ./...`.

---

## c) NOT STARTED

### High-Value Architectural Work
1. **Error type hierarchy** — Replace `fmt.Errorf` chains with structured error types for HID/v4l2 failures
2. **Command dispatch router** — Replace switch-case dispatcher with map-based routing
3. **Structured web logging** — `slog.Handler` middleware for HTTP requests
4. **HID protocol documentation** — Document protocol byte sequences in code comments
5. **Graceful shutdown test** — Verify daemon shuts down cleanly on signal

### Lint Cleanup (146 remaining issues)
6. Godoc comments on 21 exported types/funcs in `internal/pixy/pixy.go` (revive)
7. `t.Parallel()` in all 50 test functions (paralleltest)
8. `.golangci.yml` tuning to suppress acceptable stylistic linters
9. Replace `ptr(X)` with `new(X)` where appropriate (modernize)
10. Add context to HTTP test requests (noctx)
11. Inline error style decisions (noinlineerr)
12. Long line fixes (golines)
13. Magic number extraction (mnd)
14. Unused parameter cleanup (unparam)

### Test Coverage
15. Integration tests for `handlePTZCommand`
16. Integration tests for `handleAutoCommand`
17. Integration tests for `handleGestureCommand`
18. Web UI end-to-end test for PTZ slider
19. Waybar output test
20. `templ generate` in CI/pre-commit hook

### Code Quality
21. Replace type alias `var` re-exports with direct `pixy.` usage in tests
22. Extract `cameraInUseNotInCall` block to `handleCameraActivated()` method
23. Consider `errors.Join` for multi-error in `setDeviceState`
24. Replace `exec.Command` with syscalls for v4l2 (removes gosec G702)
25. Review `internal/pixy/pixy_test.go` package naming (testpackage linter)

---

## d) TOTALLY FUCKED UP

### 1. Left Code Broken Between Sessions
**Previous session extracted 4 method calls (`handleGestureCommand`, `handleCenterCommand`, `handleAutoCommand`, `handlePTZCommand`) without writing the method bodies.** Code was uncompilable between sessions. This session had to add all 4 bodies before anything else worked.

**Lesson:** Always write the body first, then replace the call site. Never leave code in a broken state between edits, let alone between sessions.

### 2. `perl -pi` Newline Corruption (Historical)
Across multiple previous sessions, `perl -pi -e 's/...//'` commands stripped newlines from Go source files, causing git corruption. This required full recovery from a known-good commit (`e552a47`).

**Lesson:** NEVER use `perl -pi` on this repo. Use the Edit/multiedit tools exclusively.

### 3. Scope Creep on Lint Thresholds
Chased lint numbers aggressively instead of focusing on architectural improvements. Extracted `handleCenterCommand` (4-line body) purely to satisfy cyclop thresholds. A command dispatcher with 12 switch cases is natural and readable.

**Lesson:** Lint thresholds are guides, not targets. The type-safe `CameraState`/`AudioMode` refactor was the real win. Should have committed it separately and moved on to architecture.

### 4. Giant Commits Instead of Incremental
One commit (`9c62a31`) bundled constants, handler extraction, formatting fixes, and test changes. Each change deserved its own commit.

**Lesson:** Commit early, commit often. One logical change per commit.

---

## e) WHAT WE SHOULD IMPROVE

### Process
- **Commit granularity:** One logical change per commit. Stop bundling.
- **Lint philosophy:** Fix functional issues, tune `.golangci.yml` for style preferences. Stop chasing threshold counts.
- **Incremental verification:** Build and test after every edit, not after a batch.

### Technical Debt
- **Error types:** `fmt.Errorf` chains are fine for prototyping but inadequate for a daemon. Need structured error types callers can switch on.
- **Test isolation:** 50 test functions lack `t.Parallel()`, indicating they may share state. Should verify and fix.
- **`exec.Command` dependency:** v4l2 control via shell commands is fragile. Direct syscalls would be more reliable and eliminate gosec false positives.

### `.golangci.yml` Recommendations
Consider suppressing or tuning these linters that produce noise without functional value:
- `paralleltest` (50 issues) — structural, not a bug
- `varnamelen` (14 issues) — subjective naming preferences
- `noinlineerr` (10 issues) — idiomatic Go style disagreement
- `gosec` (13 issues) — false positives on trusted local input
- `gochecknoglobals` (4 issues) — type alias re-exports are intentional

---

## f) Top 25 Things to Do Next

| # | Priority | Item | Effort | Impact |
|---|----------|------|--------|--------|
| 1 | P1 | Add godoc comments to exported types/funcs in `internal/pixy/pixy.go` (fixes 21 revive) | Low | High |
| 2 | P1 | Tune `.golangci.yml` — suppress acceptable linters or set thresholds | Low | High |
| 3 | P1 | Add integration tests for newly extracted handlers (`handlePTZCommand`, `handleAutoCommand`, `handleGestureCommand`) | Medium | High |
| 4 | P2 | Add `t.Parallel()` to all integration tests (fixes 50 paralleltest) | Medium | Medium |
| 5 | P2 | Extract `cameraInUseNotInCall` block to `handleCameraActivated()` method | Low | Medium |
| 6 | P2 | Document HID protocol bytes in code comments | Low | High |
| 7 | P2 | Replace type alias `var` re-exports with direct `pixy.` usage in tests (fixes 4 gochecknoglobals) | Medium | Medium |
| 8 | P2 | Consider error type hierarchy for HID/v4l2 errors | Medium | High |
| 9 | P3 | Add context to HTTP test requests (fixes 6 noctx) | Low | Low |
| 10 | P3 | Replace `ptr(X)` with `new(X)` where appropriate (fixes 11 modernize) | Low | Low |
| 11 | P3 | Add `//nolint:gosec` for trusted local command execution or disable G702 | Low | Low |
| 12 | P3 | Fix long lines (3 golines issues) | Low | Low |
| 13 | P3 | Extract magic numbers to named constants (3 mnd issues) | Low | Low |
| 14 | P3 | Clean up unused function parameters (2 unparam issues) | Low | Low |
| 15 | P3 | Decide on inline error style — add `//nolint:noinlineerr` or disable linter | Low | Low |
| 16 | P3 | Add waybar output test | Low | Low |
| 17 | P3 | Add graceful shutdown test | Low | Low |
| 18 | P3 | Review `internal/pixy/pixy_test.go` package naming (testpackage linter) | Low | Low |
| 19 | P3 | Consider `errors.Join` for multi-error in `setDeviceState` | Low | Low |
| 20 | P4 | Consider map-based command dispatch router | Medium | Medium |
| 21 | P4 | Consider structured error types for command responses | Medium | High |
| 22 | P4 | Consider `slog.Handler` middleware for structured web logging | Medium | Medium |
| 23 | P4 | Add web UI end-to-end test for PTZ slider | Medium | Medium |
| 24 | P4 | Replace `exec.Command` with syscalls for v4l2 | High | Medium |
| 25 | P4 | Add `templ generate` to CI/pre-commit hook | Medium | Medium |

---

## g) Top #1 Question I Cannot Figure Out Myself

**Should we tune `.golangci.yml` to suppress the 146 stylistic linter issues, or fix them?**

Current breakdown:
- `paralleltest` (50) — tests lack `t.Parallel()`
- `revive` (21) — missing godoc on exports
- `varnamelen` (14) — short variable names
- `gosec` (13) — false positives on trusted local input
- `modernize` (11) — `new(X)` vs `ptr(X)` suggestions
- `noinlineerr` (10) — inline error style
- `wsl_v5` (6) — whitespace enforcement
- `noctx` (6) — HTTP requests without context (test code)
- `gochecknoglobals` (4) — type alias re-exports
- `golines` (3), `mnd` (3), `unparam` (2), `nestif` (1), `testpackage` (1), `ireturn` (1)

Fixing all 146 would be significant effort for zero functional improvement. Suppressing them would clean lint output to ~0. But I cannot decide without your preference:

1. **Suppress aggressively** — Disable linters that don't match your coding style, set appropriate thresholds
2. **Fix everything** — Address every issue, keep all linters enabled at current strictness
3. **Fix functional, suppress style** — Fix revive (godoc) and meaningful issues, suppress paralleltest/varnamelen/noinlineerr/wsl_v5

---

## Appendix: Remaining Lint Issues (146 total)

```
Linter          Count  Nature
paralleltest      50   Tests lack t.Parallel()
revive            21   Missing godoc comments on exported types/funcs
varnamelen        14   Short variable names (d, tc, s, ep)
gosec             13   False positives: taint analysis on trusted/local input
modernize         11   Suggests new(X) over ptr(X) helper, min() etc.
noinlineerr       10   Style: prefers err := ... over if err := ...; err != nil
wsl_v5             6   Whitespace style enforcement
noctx              6   HTTP requests without context (test code)
gochecknoglobals   4   Type alias re-exports (var = pixy.ParseAudioMode etc.)
golines            3   Lines too long
mnd                3   Magic numbers (all len(parts) < 2)
unparam            2   Unused function parameters
nestif             1   Camera activation block (complexity 7)
testpackage        1   internal/pixy/pixy_test.go uses package pixy not pixy_test
ireturn            1   queryHIDState returns generic interface
```

## Appendix: Codebase Stats

| File | Lines |
|------|-------|
| `main.go` | 1354 |
| `handlers.go` | 408 |
| `main_test.go` | 1139 |
| `integration_test.go` | 1030 |
| `internal/pixy/pixy.go` | 185 |
| `internal/pixy/pixy_test.go` | 422 |
| `templates_templ.go` | 904 |
| **Total Go** | **5442** |
