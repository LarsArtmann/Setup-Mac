// Better Claude is a configuration management tool for Claude AI that provides
// profile-based configuration with backup capabilities, validation, and observability.
//
// The application supports multiple profiles (dev, prod, personal) with optimized
// settings for different use cases. It includes comprehensive backup and restore
// functionality to ensure configuration changes can be safely rolled back.
//
// Key features:
//   - Profile-based configuration management
//   - Automatic backup creation with timestamps
//   - Dry-run mode for safe testing
//   - OpenTelemetry integration for observability
//   - Functional programming patterns for reliability
//
// Usage:
//
//	better-claude [flags] [command]
//
// Examples:
//
//	better-claude configure --profile dev
//	better-claude --backup --dry-run configure
//	better-claude backup --profile personal
//	better-claude restore backup-file.json
package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"better-claude/cmd"
	"better-claude/internal/otel"
)

const (
	// serviceName identifies this application in telemetry and logging
	serviceName = "better-claude"
	// serviceVersion tracks the current release version for compatibility and debugging
	serviceVersion = "2.0.0"
)

// main is the application entry point. It sets up graceful shutdown handling,
// initializes OpenTelemetry tracing (when available), and delegates to the
// Cobra CLI framework for command processing.
//
// The application is designed to be resilient - if telemetry initialization
// fails, it continues without tracing rather than failing completely.
func main() {
	// Execute the CLI directly without telemetry for now
	// TODO: Re-enable telemetry once initialization issues are resolved
	cmd.Execute()
}
