# Better Claude Go Tool

A powerful configuration management tool for Claude AI with railway-oriented programming patterns, functional composition, and comprehensive observability.

## 🚀 Features

### Core Functionality
- **Profile-based Configuration**: Support for development, production, and personal profiles
- **Railway-Oriented Programming**: Error handling using Result types and functional composition
- **Functional Programming Patterns**: Built with `samber/lo` for functional operations
- **OpenTelemetry Instrumentation**: Full observability with traces, metrics, and logs
- **Automatic Backups**: Safe configuration changes with automatic backup creation
- **Configuration Validation**: Comprehensive validation of all settings

### Profiles Available

| Profile | Parallel Tasks | Notification Threshold | OTEL Export Interval | Use Case |
|---------|---------------|----------------------|-------------------|----------|
| **dev/development** | 50 | 500ms | 5000ms | High performance for development |
| **prod/production** | 10 | 2000ms | Disabled | Conservative for production |
| **personal/default** | 20 | 1000ms | 10000ms | Balanced for personal use |

## 🛠️ Installation

### From Binary
```bash
# Copy to local bin directory
cp better-claude ~/.local/bin/
chmod +x ~/.local/bin/better-claude

# Add to PATH in ~/.bashrc or ~/.zshrc
export PATH="$PATH:$HOME/.local/bin"
```

### From Source
```bash
# Clone and build
git clone <repository>
cd better-claude-go
go build -o better-claude main.go
```

## 📖 Usage

### Basic Commands

```bash
# Configure with personal profile (default)
better-claude configure --profile personal

# Configure with development profile and create backup
better-claude configure --profile dev --backup

# Test configuration without applying changes
better-claude configure --profile prod --dry-run

# Create backup of current configuration
better-claude backup --profile personal

# Restore from backup
better-claude restore /path/to/backup.json

# Show help
better-claude --help
```

### Justfile Integration

The tool is integrated into the Setup-Mac justfile with convenient commands:

```bash
# Configure Claude with personal profile
just claude-config

# Configure with development profile
just claude-config dev

# Configure with backup (recommended for production)
just claude-config-safe prod

# Create backup
just claude-backup personal

# Test configuration (dry-run)
just claude-test dev

# Restore from backup
just claude-restore /path/to/backup.json
```

## 🏗️ Architecture

### Railway-Oriented Programming

The application uses railway-oriented programming patterns with Result types:

```go
// Pipeline example
result := NewPipeline(profile).
    Then(loadProfileWithLogging).
    Then(createBackupIfRequested).
    Then(configureClaudeSettings).
    Then(configureEnvironmentVariables).
    Then(updatePackages).
    Then(validateConfiguration).
    Result()
```

### Functional Composition

Built with functional programming principles:

- **Result Types**: `Result[T]` for error handling
- **Pipeline Operations**: Chainable operations with early termination on failure
- **Pure Functions**: Side-effect free transformations
- **Composition**: Building complex operations from simple functions

### Key Components

```
better-claude-go/
├── cmd/                    # Cobra CLI commands
│   ├── backup.go          # Backup operations
│   ├── configure.go       # Main configuration logic
│   ├── restore.go         # Restore operations
│   └── root.go           # Root command and setup
├── internal/
│   ├── config/           # Configuration management
│   ├── functional/       # Railway-oriented programming
│   ├── logger/          # Structured logging
│   ├── otel/            # OpenTelemetry setup
│   └── profiles/        # Profile management
├── domain/              # Domain logic and events
├── infrastructure/      # External integrations
└── main.go             # Application entry point
```

## 🧪 Testing

### Unit Tests
```bash
go test ./... -v
```

### Integration Tests
```bash
# Test with different profiles
better-claude configure --profile dev --dry-run
better-claude configure --profile prod --dry-run
better-claude configure --profile personal --dry-run
```

### CI/CD Pipeline

GitHub Actions workflow includes:
- **Testing**: Unit tests, integration tests, and security scans
- **Building**: Multi-platform binary builds (Linux, macOS, Windows)
- **Validation**: Profile validation and dry-run testing
- **Release**: Automatic releases with binary artifacts

## 📊 Observability

### OpenTelemetry Integration

The application includes comprehensive observability:

```yaml
# Traces
- Command execution spans
- Configuration operation traces
- Error tracking and attribution

# Metrics
- Configuration success/failure rates
- Profile usage statistics
- Performance metrics

# Logs
- Structured logging with levels
- Contextual information
- Error details and stack traces
```

### Example Log Output

```json
{
  "time": "2025-07-13T19:45:30.486892+02:00",
  "level": "INFO",
  "msg": "Using profile: personal",
  "service": "better-claude",
  "version": "2.0.0"
}
```

## 🔧 Configuration

### Environment Variables

```bash
# Enable debug mode
CLAUDE_DEBUG=1

# Set custom profile
CLAUDE_PROFILE=dev

# OpenTelemetry configuration
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
```

### Profile Customization

Profiles are defined in `internal/profiles/manager.go` and can be extended:

```go
type ProfileConfig struct {
    Profile Profile
    Config  Config
    EnvVars map[string]string
}
```

## 🚀 Advanced Usage

### Custom Pipeline Operations

Create custom pipeline operations using the functional programming primitives:

```go
import "better-claude/internal/functional"

// Custom operation
customOperation := func(input string) functional.Result[string] {
    return functional.Try(func() (string, error) {
        // Your logic here
        return processedInput, nil
    })
}

// Use in pipeline
result := functional.NewPipeline("input").
    Then(customOperation).
    Result()
```

### Error Recovery

Handle errors gracefully with recovery functions:

```go
result := operation().Recover(func(err error) string {
    log.Warning("Operation failed, using default: %v", err)
    return "default_value"
})
```

## 🔐 Security

### Security Features
- **Input Validation**: All inputs are validated before processing
- **Secure Defaults**: Conservative settings for production profiles
- **Backup Safety**: Automatic backups before making changes
- **Error Handling**: Comprehensive error handling prevents data loss

### Security Scanning

The CI/CD pipeline includes:
- Gosec security scanner
- Dependency vulnerability checks
- SARIF report generation
- Automated security updates

## 📝 Contributing

### Development Setup

```bash
# Clone repository
git clone <repository>
cd better-claude-go

# Install dependencies
go mod download

# Run tests
go test ./... -v

# Build
go build -o better-claude main.go
```

### Code Style

- Follow Go conventions and `gofmt`
- Use functional programming patterns
- Write comprehensive tests
- Include OpenTelemetry traces for observability
- Document public APIs

## 📜 License

Generated with 🤖 [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>

## 🔗 Related

- [samber/lo](https://github.com/samber/lo) - Functional programming utilities
- [OpenTelemetry Go](https://opentelemetry.io/docs/languages/go/) - Observability framework
- [Cobra](https://cobra.dev/) - CLI framework
- [Viper](https://github.com/spf13/viper) - Configuration management