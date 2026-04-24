# dnsblockd-processor

Blocklist processor that converts DNS blocklists into Unbound `local-data` entries and a domain-to-list mapping JSON file.

Supports multiple input formats:
- **Hosts** (`0.0.0.0 domain.com` or `127.0.0.1 domain.com`)
- **Domains** (one domain per line)
- **Adblock** (`||domain.com^`)
- **Dnsmasq** (`address=/domain.com/` or `local=/domain.com/`)

## Usage

```
dnsblockd-processor BLOCK_IP WHITELIST_FILE UNBOUND_OUTPUT MAPPING_OUTPUT [LIST_FILE NAME]...
```

| Argument | Description |
|----------|-------------|
| `BLOCK_IP` | IP address to redirect blocked domains to |
| `WHITELIST_FILE` | File with whitelisted domains (one per line) |
| `UNBOUND_OUTPUT` | Output path for Unbound `local-data` entries |
| `MAPPING_OUTPUT` | Output path for domain-to-list JSON mapping |
| `LIST_FILE NAME` | Pairs of blocklist file path and source name |

## Example

```bash
dnsblockd-processor \
  192.168.1.10 \
  /etc/dnsblockd/whitelist.txt \
  /etc/dnsblockd/unbound.conf \
  /etc/dnsblockd/mapping.json \
  /etc/dnsblockd/lists/ads.txt ads \
  /etc/dnsblockd/lists/malware.txt malware
```

## Output

**Unbound entries** (`unbound.conf`):
```
local-data: "ads.example.com A 192.168.1.10"
local-data: "tracker.example.com A 192.168.1.10"
```

**Mapping JSON** (`mapping.json`):
```json
{"ads.example.com":"ads","tracker.example.com":"malware"}
```

## Features

- Deduplicates across all lists (first match wins)
- Skips localhost/LAN domains
- Whitelist support
- Path traversal protection
- Zero dependencies (pure stdlib)

## License

MIT
