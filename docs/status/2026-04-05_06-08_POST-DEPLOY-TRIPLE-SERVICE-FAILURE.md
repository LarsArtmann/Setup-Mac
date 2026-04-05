# Post-Deploy Triple Service Failure — Incident & Fix Report

**Date:** 2026-04-05 06:08
**Trigger:** `just switch` on evo-x2 (generation `26.05.20260402.8d8c1fa`)
**Result:** Activation failed (exit 4) — 3 services crashed, 1 dependency cascaded
**Status:** Fixed, validated (`just test-fast` passes), pending `just switch`

---

## Timeline

| Time | Event |
|------|-------|
| 06:05 | `just switch` begins building new generation |
| 06:06 | Activation starts — old units stopped, new units activated |
| 06:06:53 | `clickhouse.service` fails → `signoz.service` dependency fails |
| 06:06:56 | `dnsblockd.service` fails (restart loop, counter 32) |
| 06:06:58 | `authelia-main.service` fails (config validation) |
| 06:08 | Activation exits with code 4 |

---

## Root Causes & Fixes

### 1. Authelia 4.39 Breaking Configuration Changes

**Service:** `authelia-main.service`
**File:** `modules/nixos/services/authelia.nix`

Authelia upgraded to **4.39.12** which introduced strict config validation. Five errors + one deprecation warning:

| # | Error | Root Cause | Fix |
|---|-------|-----------|-----|
| 1 | `notifier.filesystem.path` unexpected | Renamed in 4.39 | `filesystem.path` → `filesystem.filename` |
| 2 | `server.endpoints.enable.enable_expvars` unexpected | Nested `enable` key removed | `endpoints.enable.enable_expvars` → `endpoints.enable_expvars` |
| 3 | `server.endpoints.enable.enable_pprof` unexpected | Same as above | `endpoints.enable.enable_pprof` → `endpoints.enable_pprof` |
| 4 | `domain 'lan'` not valid cookie domain | Bare TLDs rejected in 4.39 | Domain migration: `lan` → `home.lan` (see below) |
| 5 | `notifier: filesystem: option 'filename' is required` | Same as #1 | Same as #1 |
| ⚠ | `webauthn.user_verification` deprecated | Moved in 4.39 | → `webauthn.selection_criteria.user_verification` |

#### Domain Migration: `*.lan` → `*.home.lan`

Authelia 4.39 enforces that session cookie domains must have at least two levels (e.g., `example.com`, not just `com`). The bare TLD `lan` was rejected. This required migrating **all** service domains across the entire codebase.

**Old → New domain map:**

| Service | Old | New |
|---------|-----|-----|
| Authelia | `auth.lan` | `auth.home.lan` |
| Immich | `immich.lan` | `immich.home.lan` |
| Gitea | `gitea.lan` | `gitea.home.lan` |
| Homepage | `home.lan` | `dash.home.lan` |
| PhotoMap | `photomap.lan` | `photomap.home.lan` |
| Unsloth | `unsloth.lan` | `unsloth.home.lan` |
| SigNoz | `signoz.lan` | `signoz.home.lan` |
| Cookie domain | `lan` | `home.lan` |

**Files changed for domain migration (11 total):**

| File | Changes |
|------|---------|
| `modules/nixos/services/authelia.nix` | `domain`, session cookies, ACLs, CORS, email |
| `modules/nixos/services/caddy.nix` | 7 virtual host definitions |
| `modules/nixos/services/homepage.nix` | 14 URLs + health checks |
| `modules/nixos/services/immich.nix` | OAuth `issuerUrl` |
| `modules/nixos/services/gitea.nix` | `ROOT_URL`, `DOMAIN` |
| `platforms/nixos/system/dns-blocker-config.nix` | `local-zone` + 7 DNS records |
| `README.md` | Service table, DNS description |
| `AGENTS.md` | DNS blocker description |
| `IMMICH-BULL-BOARD-PATCH-GUIDE.md` | Example config |

---

### 2. ClickHouse XML Parse Error

**Service:** `clickhouse.service` (cascaded to `signoz.service`)
**File:** `modules/nixos/services/signoz.nix:206-226`

**Error:**
```
SAXParseException: Junk after document element in '200-nixos-module-extra-config.xml', line 14 column 0
```

**Root cause:** `services.clickhouse.extraServerConfig` contained two sibling XML elements (`<keeper_server>` and `<zookeeper>`) without a wrapping root element. ClickHouse's config merger writes this to a standalone XML file, which requires a single root element.

**Fix:** Wrapped both elements in `<clickhouse>` root:

```xml
<clickhouse>
  <keeper_server>...</keeper_server>
  <zookeeper>...</zookeeper>
</clickhouse>
```

---

### 3. dnsblockd sops Secret Race Condition

**Service:** `dnsblockd.service`
**File:** `platforms/nixos/modules/dns-blocker.nix`

**Error:**
```
-ca-cert and -ca-key are required when -tls-port > 0
```

**Root cause:** dnsblockd started before sops-nix decrypted the TLS CA cert/key secrets. The sops secrets existed on disk but weren't ready at first start. With `Restart = "on-failure"` (3s delay), it would eventually self-heal (restart counter was at 32), but this caused unnecessary startup delay and noise.

**Fix:** Added `sops-nix.service` to `after` and `wants`:

```nix
after = ["network-online.target" "sops-nix.service"];
wants = ["network-online.target" "sops-nix.service"];
```

---

## Files Changed (11 files, 72 insertions, 70 deletions)

```
AGENTS.md                                          |  2 +-
README.md                                          | 16 ++++-----
.../services/IMMICH-BULL-BOARD-PATCH-GUIDE.md      |  2 +-
modules/nixos/services/authelia.nix                | 12 ++++---
modules/nixos/services/caddy.nix                   | 14 ++++----
modules/nixos/services/gitea.nix                   |  4 +--
modules/nixos/services/homepage.nix                | 30 ++++++++--------
modules/nixos/services/immich.nix                  |  2 +-
modules/nixos/services/signoz.nix                  | 40 ++++++++++++----------
platforms/nixos/modules/dns-blocker.nix            |  4 +--
platforms/nixos/system/dns-blocker-config.nix      | 16 ++++-----
```

## Validation

```
$ just test-fast
✅ Fast configuration test passed
```

All NixOS modules evaluated successfully. No remaining stale `.lan` references in `.nix` files (verified via `grep`).

## Next Steps

1. `just switch` — deploy the fixed configuration
2. Verify all 3 services start cleanly
3. Update any bookmarks/browser shortcuts from `*.lan` to `*.home.lan`
4. Update DNS cache on LAN clients (flush or wait for TTL)

## Unaffected by Domain Migration

These files reference `.lan` but are **not** configuration — no changes needed:
- `pkgs/dnsblockd-processor/main.go:102` — skips `.lan` domains in blocklist processing (correct behavior, skips local domains)
- `platforms/nixos/programs/dnsblockd/main.go:451` — `isLANDomain()` helper for block page rendering (correct, matches any `.lan` suffix)
- Various `docs/status/*.md` — historical reports, not live config
