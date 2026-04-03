# SigNoz NixOS Flake

A native NixOS packaging of [SigNoz](https://signoz.io) - OpenTelemetry-native observability platform with metrics, traces, and logs.

## Overview

This flake provides:
- **Native NixOS packages** for all SigNoz components
- **Full NixOS module** with systemd services
- **ClickHouse integration** (managed or external)
- **Flake-parts** architecture for modularity

## Structure

```
pkgs/signoz/
├── flake.nix          # Single file: packages + module exports
├── nixos-module.nix   # NixOS systemd services
└── README.md

Internal (inline in flake.nix):
├── signoz (main package)
│   ├── Go binary (query-service)
│   └── Embedded web assets (React frontend)
├── otelCollector (let-binding, used by module)
└── schemaMigrator (let-binding, used by module)
```

## Package

| Package | Description | Binary |
|---------|-------------|--------|
| `signoz` | Complete observability platform (backend + embedded frontend) | `signoz` |

Sub-components are built internally via `let` bindings and exposed through the NixOS module:
- `signoz-otel-collector` (via `legacyPackages`)
- `signoz-schema-migrator` (via `legacyPackages`)

## Quick Start

### 1. Add to your flake inputs

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    signoz.url = "path:/home/lars/projects/SystemNix/pkgs/signoz"; # or github:...
  };

  outputs = { self, nixpkgs, signoz }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        signoz.nixosModules.signoz
        ./configuration.nix
      ];
    };
  };
}
```

### 2. Enable SigNoz

```nix
# configuration.nix
{
  services.signoz = {
    enable = true;
    settings = {
      queryService = {
        port = 8080;
        dataDir = "/var/lib/signoz";
      };
      clickhouse = {
        url = "tcp://127.0.0.1:9000";
        database = "signoz_metrics";
      };
    };
    components = {
      queryService = true;
      otelCollector = true;
      clickhouse = true;  # Use managed ClickHouse
    };
  };
}
```

### 3. Deploy

```bash
nixos-rebuild switch --flake .#myhost
```

Access SigNoz at `http://localhost:8080`

## Configuration Options

### Full Example

```nix
services.signoz = {
  enable = true;

  settings = {
    # ClickHouse configuration
    clickhouse = {
      url = "tcp://127.0.0.1:9000";
      database = "signoz_metrics";
      tracesDatabase = "signoz_traces";
      logsDatabase = "signoz_logs";
    };

    # Query service
    queryService = {
      port = 8080;
      host = "0.0.0.0";
      jwtSecret = null;  # Auto-generated
      dataDir = "/var/lib/signoz";
    };

    # OTel Collector
    collector = {
      port = 4317;      # gRPC
      httpPort = 4318;  # HTTP
      configFile = null;  # Auto-generated
    };

    # Data retention
    retention = {
      metrics = 30;  # days
      traces = 7;    # days
      logs = 7;      # days
    };
  };

  # Component toggles
  components = {
    queryService = true;
    otelCollector = true;
    clickhouse = true;  # Set false to use external ClickHouse
  };
};
```

## External ClickHouse

To use an existing ClickHouse instance:

```nix
{
  services.signoz = {
    enable = true;
    components.clickhouse = false;  # Don't manage ClickHouse
    settings.clickhouse.url = "tcp://your-clickhouse-host:9000";
  };

  # Don't enable services.clickhouse
}
```

## Development

### Enter development shell

```bash
cd /home/lars/projects/SystemNix/pkgs/signoz
nix develop
```

### Build

```bash
# Build the main package (includes embedded frontend)
nix build .#signoz

# Or just:
nix build
```

### Update vendor hashes

When updating versions, you'll need to update the `vendorHash`:

```bash
# Get the new hash (will fail with correct hash)
nix build .#signoz-query-service 2>&1 | grep "got:"
```

## Architecture Details

### Query Service
- **Language**: Go 1.23
- **Web Framework**: Gorilla Mux
- **Database**: ClickHouse (via go-clickhouse)
- **Caching**: Redis (optional)
- **Features**: JWT auth, PromQL-compatible queries, alerts

### Frontend
- **Language**: TypeScript/React
- **Build Tool**: Vite
- **UI Components**: Ant Design
- **Charts**: Recharts

### OTel Collector
- **Base**: OpenTelemetry Collector Contrib
- **Custom Exporters**:
  - `clickhousetraces` - Trace ingestion
  - `signozclickhousemetrics` - Metrics ingestion
  - `clickhouselogsexporter` - Log ingestion

## Systemd Services

| Service | Description | Dependencies |
|---------|-------------|--------------|
| `signoz-schema-migration` | ClickHouse schema setup | `clickhouse.service` |
| `signoz-query-service` | Main API + frontend | `signoz-schema-migration.service` |
| `signoz-otel-collector` | Data ingestion | `signoz-query-service.service` |
| `clickhouse` | Database (optional) | - |

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 8080 | Query Service | Main UI + API |
| 4317 | OTel Collector | gRPC ingestion |
| 4318 | OTel Collector | HTTP ingestion |
| 9000 | ClickHouse | Native protocol |
| 8123 | ClickHouse | HTTP interface |

## Troubleshooting

### Check service status

```bash
systemctl status signoz-query-service
systemctl status signoz-otel-collector
journalctl -u signoz-query-service -f
```

### Verify ClickHouse connection

```bash
clickhouse-client --query "SHOW DATABASES"
```

### Test OTel endpoint

```bash
curl http://localhost:4318/v1/traces -X POST -H "Content-Type: application/json" \
  -d '{"resourceSpans":[]}'
```

## Migration from Prometheus/Grafana

1. **Parallel deployment**: Keep Prometheus while testing SigNoz
2. **Forward metrics**: Use OTel Collector's `prometheusreceiver` to send to both
3. **Recreate dashboards**: Manual migration (no automated converter)
4. **Retrain queries**: ClickHouse SQL vs PromQL (SigNoz has PromQL-compatible layer)

## Resource Requirements

| Component | RAM | CPU | Notes |
|-----------|-----|-----|-------|
| ClickHouse | 4GB+ | 2+ | Heavy user of RAM for queries |
| Query Service | 1GB | 1 | Scales with concurrent users |
| OTel Collector | 512MB | 1 | Scales with ingestion volume |
| **Total** | **6GB+** | **4+** | Recommended for production |

## Future Enhancements

- [ ] High availability (HA) ClickHouse cluster
- [ ] Kafka integration for high throughput
- [ ] Alertmanager integration
- [ ] SSO/LDAP authentication
- [ ] Custom dashboard templates

## License

Apache 2.0 - See [SigNoz License](https://github.com/SigNoz/signoz/blob/main/LICENSE)

## References

- [SigNoz Documentation](https://signoz.io/docs/)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [ClickHouse Documentation](https://clickhouse.com/docs)
- [NixOS ClickHouse Module](https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=clickhouse)
