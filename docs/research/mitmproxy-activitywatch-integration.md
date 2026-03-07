# mitmproxy + ActivityWatch Integration

**Status:** Research / Proposed
**Created:** 2026-02-27
**Type:** Feature Proposal

---

## Overview

This document explores the potential integration of [mitmproxy](https://www.mitmproxy.org/) with [ActivityWatch](https://activitywatch.net/) for protocol-level web activity tracking.

---

## What is mitmproxy?

mitmproxy is a free, open-source interactive HTTPS proxy that intercepts, inspects, modifies, and replays web traffic. It acts as a "swiss-army knife" for debugging, testing, privacy measurements, and penetration testing.

### Key Features

| Feature                  | Description                                                    |
| ------------------------ | -------------------------------------------------------------- |
| **Protocol Support**     | HTTP/1, HTTP/2, HTTP/3, WebSockets, SSL/TLS, TCP/UDP/QUIC, DNS |
| **Interfaces**           | `mitmproxy` (terminal), `mitmweb` (web UI), `mitmdump` (CLI)   |
| **Traffic Manipulation** | Modify headers, bodies, blocklist, map local/remote            |
| **Replay**               | Client/server-side replay of HTTP conversations                |
| **Automation**           | Python addon system with event hooks                           |

### Extension Mechanism

mitmproxy provides a powerful addon system with event hooks:

**Lifecycle Events:**

- `load()`, `running()`, `configure()`, `done()`

**Connection Events:**

- `client_connected/disconnected()`, `server_connect/connected/disconnected()`

**HTTP Events:**

- `requestheaders()`, `request()`, `responseheaders()`, `response()`, `error()`

**Protocol Events:**

- WebSocket, TCP, UDP, DNS, TLS handshake events

---

## Research Findings

### Existing Integrations

**No direct integration exists.** Comprehensive search of GitHub, forums, and documentation found no projects combining mitmproxy with ActivityWatch or time tracking tools.

### Related ActivityWatch Watchers

Two network-related watchers exist, but neither tracks detailed web traffic:

| Project                                                                       | Description                                | Limitation      |
| ----------------------------------------------------------------------------- | ------------------------------------------ | --------------- |
| [aw-watcher-netstatus](https://github.com/sameersismail/aw-watcher-netstatus) | Network connection status (online/offline) | No URL tracking |
| [aw-watcher-network-rs](https://github.com/0xbrayo/aw-watcher-network-rs)     | Network connectivity and Wi-Fi scanning    | No URL tracking |

### References

- [ActivityWatch awesome list](https://github.com/ActivityWatch/awesome-activitywatch)
- [ActivityWatch proxy issue #360](https://github.com/ActivityWatch/activitywatch/issues/360) - Using AW _behind_ proxies, not for tracking
- [LibHunt comparison](https://www.libhunt.com/compare-activitywatch-vs-mitmproxy) - Tool comparison only
- [mitmproxy traffic logging discussion #6844](https://github.com/mitmproxy/mitmproxy/discussions/6844) - Logging to CSV/text

---

## Benefits of Integration

### Unique Capabilities

| Benefit                       | Description                                                                          |
| ----------------------------- | ------------------------------------------------------------------------------------ |
| **Protocol-level tracking**   | Capture URLs that browser extensions miss (apps, background requests, electron apps) |
| **Cross-browser unification** | Single watcher for Chrome, Firefox, Safari, Edge - no per-browser extensions         |
| **App traffic visibility**    | Track requests from Slack, Discord, Spotify, VS Code, mobile devices                 |
| **Full request metadata**     | HTTP method, headers, response codes, timing, payload sizes                          |
| **Privacy auditing**          | See exactly what data apps send to servers                                           |
| **No fingerprinting bypass**  | Works regardless of browser privacy settings/incognito mode                          |
| **Device-wide coverage**      | Any device configured to use the proxy (phones, tablets, IoT)                        |

### Comparison with Browser Extensions

| Aspect            | Browser Extension   | mitmproxy Integration        |
| ----------------- | ------------------- | ---------------------------- |
| Browser support   | Per-browser install | All browsers via proxy       |
| Incognito/Private | Often disabled      | Full coverage                |
| Desktop apps      | No coverage         | Full coverage                |
| Mobile devices    | Limited             | Full coverage (proxy config) |
| Protocol depth    | Limited API         | Full HTTP/HTTPS inspection   |
| Setup complexity  | Simple              | Certificate trust required   |

---

## Proposed Architecture

### Data Flow

```
┌─────────────────┐     ┌─────────────┐     ┌────────────────┐
│ Browser/App     │────▶│  mitmproxy  │────▶│ Target Server  │
└─────────────────┘     └──────┬──────┘     └────────────────┘
                               │
                               ▼
                        ┌─────────────┐
                        │ AW Addon    │
                        │ (Python)    │
                        └──────┬──────┘
                               │
                               ▼ HTTP API
                        ┌─────────────┐
                        │ActivityWatch│
                        │   Server    │
                        └─────────────┘
```

### Event Schema

```json
{
  "timestamp": "2026-02-27T10:30:00.000Z",
  "duration": 0,
  "data": {
    "url": "https://api.github.com/users/example",
    "method": "GET",
    "host": "api.github.com",
    "path": "/users/example",
    "status_code": 200,
    "request_size": 0,
    "response_size": 1234,
    "duration_ms": 150,
    "content_type": "application/json",
    "app": "Chrome"
  }
}
```

### Proof of Concept Implementation

```python
# ~/.mitmproxy/aw-watcher.py
"""
mitmproxy addon that logs HTTP requests to ActivityWatch.

Usage:
    mitmproxy -s aw-watcher.py
    mitmdump -s aw-watcher.py
    mitmweb -s aw-watcher.py
"""

from mitmproxy import http, ctx
from datetime import datetime, timezone
import requests
import time


class ActivityWatchAddon:
    """Sends HTTP request events to ActivityWatch API."""

    def __init__(self):
        self.aw_url = "http://localhost:5600/api/0"
        self.bucket_id = "aw-watcher-mitmproxy"
        self.hostname = "mitmproxy"
        self.enabled = True

    def load(self, loader):
        """Initialize bucket on addon load."""
        self._ensure_bucket()
        ctx.log.info(f"[aw-watcher] Loaded, bucket: {self.bucket_id}")

    def _ensure_bucket(self):
        """Create ActivityWatch bucket if it doesn't exist."""
        bucket_url = f"{self.aw_url}/buckets/{self.bucket_id}"

        # Check if bucket exists
        try:
            resp = requests.get(bucket_url)
            if resp.status_code == 200:
                ctx.log.info("[aw-watcher] Bucket already exists")
                return
        except requests.RequestException:
            pass

        # Create bucket
        try:
            resp = requests.post(bucket_url, json={
                "client": "aw-watcher-mitmproxy",
                "type": "web.request",
                "hostname": self.hostname,
            })
            ctx.log.info("[aw-watcher] Created bucket")
        except requests.RequestException as e:
            ctx.log.error(f"[aw-watcher] Failed to create bucket: {e}")
            self.enabled = False

    def request(self, flow: http.HTTPFlow):
        """Process each HTTP request."""
        if not self.enabled:
            return

        # Skip unnecessary requests
        if self._should_skip(flow):
            return

        event = self._create_event(flow)
        self._send_event(event)

    def response(self, flow: http.HTTPFlow):
        """Process HTTP response for additional metadata."""
        if not self.enabled:
            return

        # Could send enhanced event with response data here
        # For now, we log on request only to avoid duplicates

    def _should_skip(self, flow: http.HTTPFlow) -> bool:
        """Filter out noise requests."""
        host = flow.request.host.lower()

        # Skip common noise
        skip_hosts = [
            "localhost",
            "127.0.0.1",
            "activitywatch",  # Avoid self-referential logging
        ]

        return any(skip in host for skip in skip_hosts)

    def _create_event(self, flow: http.HTTPFlow) -> dict:
        """Create ActivityWatch event from HTTP flow."""
        timestamp = flow.request.timestamp_start or time.time()

        # Convert to ISO format
        if isinstance(timestamp, (int, float)):
            dt = datetime.fromtimestamp(timestamp, tz=timezone.utc)
            timestamp_str = dt.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
        else:
            timestamp_str = timestamp

        return {
            "timestamp": timestamp_str,
            "duration": 0,
            "data": {
                "url": flow.request.pretty_url,
                "method": flow.request.method,
                "host": flow.request.host,
                "path": flow.request.path,
                "scheme": flow.request.scheme,
                "port": flow.request.port,
            }
        }

    def _send_event(self, event: dict):
        """Send event to ActivityWatch API."""
        url = f"{self.aw_url}/buckets/{self.bucket_id}/events"

        try:
            resp = requests.post(url, json=[event])
            if resp.status_code not in (200, 201, 204):
                ctx.log.warning(f"[aw-watcher] Failed to send event: {resp.status_code}")
        except requests.RequestException as e:
            ctx.log.error(f"[aw-watcher] Request failed: {e}")


# mitmproxy addon entry point
addons = [ActivityWatchAddon()]
```

### Enhanced Version with Response Data

```python
# Enhanced version that waits for response
class ActivityWatchAddonEnhanced:
    """Waits for response to include status code and timing."""

    def __init__(self):
        self.aw_url = "http://localhost:5600/api/0"
        self.bucket_id = "aw-watcher-mitmproxy-enhanced"
        self.pending = {}  # Store request start times

    def request(self, flow: http.HTTPFlow):
        """Store request start time."""
        self.pending[id(flow)] = {
            "start_time": time.time(),
            "request": flow.request,
        }

    def response(self, flow: http.HTTPFlow):
        """Send event with full request/response data."""
        flow_id = id(flow)
        if flow_id not in self.pending:
            return

        pending = self.pending.pop(flow_id)
        duration_ms = (time.time() - pending["start_time"]) * 1000

        event = {
            "timestamp": datetime.fromtimestamp(
                pending["start_time"], tz=timezone.utc
            ).isoformat(),
            "duration": duration_ms / 1000,  # seconds
            "data": {
                "url": flow.request.pretty_url,
                "method": flow.request.method,
                "host": flow.request.host,
                "path": flow.request.path,
                "status_code": flow.response.status_code,
                "duration_ms": round(duration_ms, 2),
                "request_size": len(flow.request.raw_content) if flow.request.raw_content else 0,
                "response_size": len(flow.response.raw_content) if flow.response.raw_content else 0,
                "content_type": flow.response.headers.get("Content-Type", ""),
            }
        }

        self._send_event(event)
```

---

## Setup Instructions

### Prerequisites

1. **mitmproxy installed** (via Nix: `nix-shell -p mitmproxy`)
2. **ActivityWatch running** at `http://localhost:5600`
3. **Python requests library**

### Installation

```bash
# Create addon directory
mkdir -p ~/.mitmproxy

# Save addon script
cat > ~/.mitmproxy/aw-watcher.py << 'EOF'
# [Insert addon code from above]
EOF

# Test addon
mitmdump -s ~/.mitmproxy/aw-watcher.py
```

### Certificate Setup (HTTPS)

```bash
# Start mitmproxy once to generate certs
mitmdump

# Install CA certificate (macOS)
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ~/.mitmproxy/mitmproxy-ca-cert.pem

# Configure system proxy (macOS)
networksetup -setwebproxy Wi-Fi 127.0.0.1 8080
networksetup -setsecurewebproxy Wi-Fi 127.0.0.1 8080
```

### Running

```bash
# Start ActivityWatch (if not running)
open -a ActivityWatch

# Start mitmproxy with addon
mitmproxy -s ~/.mitmproxy/aw-watcher.py

# Or web interface
mitmweb -s ~/.mitmproxy/aw-watcher.py

# Or headless
mitmdump -s ~/.mitmproxy/aw-watcher.py
```

---

## Challenges and Mitigations

| Challenge                         | Mitigation                                                  |
| --------------------------------- | ----------------------------------------------------------- |
| **HTTPS requires cert trust**     | Install mitmproxy CA cert in system/browser keychain        |
| **High event volume**             | Aggregate by host, debounce rapid requests, filter noise    |
| **Identifying "active use"**      | Correlate with `aw-watcher-window` events                   |
| **Mobile devices**                | Configure device WiFi proxy to point to mitmproxy host      |
| **Performance overhead**          | Use async requests, batch events, run on capable hardware   |
| **Privacy concerns**              | Local-only, filter sensitive URLs, no external transmission |
| **TLS 1.3 / Certificate Pinning** | Some apps may fail; fallback to SNI-based logging only      |

---

## Future Enhancements

### Short Term

- [ ] Aggregate requests by host/session
- [ ] Correlate with active window watcher
- [ ] Add category detection (work/social/entertainment)
- [ ] Filter list configuration

### Medium Term

- [ ] Web UI for configuration
- [ ] Real-time dashboard
- [ ] Export to other time tracking tools
- [ ] Mobile device auto-discovery

### Long Term

- [ ] ML-based activity categorization
- [ ] Productivity scoring
- [ ] Privacy report generation
- [ ] Multi-user support

---

## Related Projects

- [ActivityWatch](https://activitywatch.net/) - Time tracking application
- [mitmproxy](https://www.mitmproxy.org/) - HTTPS proxy framework
- [aw-watcher-web](https://github.com/ActivityWatch/aw-watcher-web) - Browser extension (reference)
- [aw-watcher-netstatus](https://github.com/sameersismail/aw-watcher-netstatus) - Network status watcher

---

## References

- [mitmproxy Addon Documentation](https://docs.mitmproxy.org/stable/addons/overview/)
- [mitmproxy Event Hooks API](https://docs.mitmproxy.org/stable/api/events.html)
- [ActivityWatch API Documentation](https://activitywatch.readthedocs.io/en/latest/api.html)
- [ActivityWatch Bucket Types](https://activitywatch.readthedocs.io/en/latest/buckets.html)

---

## Conclusion

A mitmproxy addon for ActivityWatch would provide unique protocol-level insights that no browser extension can match. This is a greenfield opportunity with no existing implementations.

**Recommendation:** Build a proof-of-concept to validate the approach and gather real-world usage data.

---

_Document created: 2026-02-27_
