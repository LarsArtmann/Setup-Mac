# Post-Deploy Service Failures — 2026-04-05 06:08

**Trigger:** `just switch` on evo-x2 (commit `8d8c1fa`)

**Result:** 3 services failed, activation exited with code 4.

---

## Failed Services

| Service | Status | Root Cause |
|---------|--------|------------|
| `authelia-main.service` | Failed | Authelia 4.39 breaking config changes |
| `clickhouse.service` | Failed | Malformed XML in `extraServerConfig` |
| `dnsblockd.service` | Failed | sops secret race condition (eventually self-heals) |
| `signoz.service` | Failed | Dependency on clickhouse |

---

## 1. Authelia 4.39 Breaking Changes

Authelia upgraded from pre-4.39 to **4.39.12**. Five config validation errors:

### Errors & Fixes (`modules/nixos/services/authelia.nix`)

| # | Error | Current (broken) | Fix |
|---|-------|-----------------|-----|
| 1 | `notifier.filesystem.path` unexpected | `filesystem.path = "..."` (line 141) | `filesystem.filename = "..."` |
| 2 | `server.endpoints.enable.enable_expvars` unexpected | `endpoints.enable.enable_expvars` (line 49) | `endpoints.enable_expvars` |
| 3 | `server.endpoints.enable.enable_pprof` unexpected | `endpoints.enable.enable_pprof` (line 50) | `endpoints.enable_pprof` |
| 4 | `domain 'lan'` not valid cookie domain | `domain = "lan"` (line 8, 120) | **Requires domain migration** (see below) |
| 5 | `notifier: filesystem: option 'filename' is required` | Same as #1 | Same as #1 |

### Warning (non-fatal)
- `webauthn.user_verification` deprecated → `webauthn.selection_criteria.user_verification` (line 77)

### Domain Migration Required

Authelia 4.39 rejects bare TLDs as session cookie domains. `"lan"` is invalid — must have at least two levels (e.g., `home.lan`).

**Affected files** (all use `*.lan` or `"lan"`):

| File | Usage |
|------|-------|
| `modules/nixos/services/authelia.nix` | `domain = "lan"`, session cookies, ACLs, CORS |
| `modules/nixos/services/caddy.nix` | All virtual hosts: `auth.lan`, `immich.lan`, `gitea.lan`, `home.lan`, etc. |
| `modules/nixos/services/homepage.nix` | All service URLs and health checks |
| `platforms/nixos/system/dns-blocker-config.nix` | All DNS local-data records |

**Proposed migration:** `*.lan` → `*.home.lan` (or user-chosen subdomain)

---

## 2. ClickHouse XML Parse Error

**File:** `modules/nixos/services/signoz.nix:206-226`

`services.clickhouse.extraServerConfig` contains two root-level XML elements:
```xml
<keeper_server>...</keeper_server>
<zookeeper>...</zookeeper>
```

ClickHouse's config merger writes this to a standalone XML file, which requires a single root element. The error:
```
SAXParseException: Junk after document element in '200-nixos-module-extra-config.xml', line 14 column 0
```

**Fix:** Wrap both elements in a `<clickhouse>` root element:
```xml
<clickhouse>
  <keeper_server>...</keeper_server>
  <zookeeper>...</zookeeper>
</clickhouse>
```

---

## 3. dnsblockd — sops Secret Race Condition

**Error:** `-ca-cert and -ca-key are required when -tls-port > 0`

The sops secrets exist at `/run/secrets/dnsblockd_ca_cert` and `/run/secrets/dnsblockd_ca_key`, but dnsblockd starts before they're decrypted. With `Restart = "on-failure"` (3s delay), it eventually self-heals (restart counter was at 32).

**Fix:** Add sops dependency to `platforms/nixos/modules/dns-blocker.nix`:
```nix
after = ["network-online.target" "sops-nix.service"];
wants = ["network-online.target" "sops-nix.service"];
```

---

## Action Items

1. **Authelia** — Fix 3 syntax errors + decide on domain migration strategy
2. **ClickHouse** — Wrap XML in `<clickhouse>` root element
3. **dnsblockd** — Add `sops-nix.service` dependency
