package cmd

import (
	"context"
	"fmt"
	"strings"

	"github.com/bitfield/script"
	"go.opentelemetry.io/otel/attribute"

	"better-claude/internal/logger"
	"better-claude/internal/otel"
)

// updatePackages updates the claude-code package using bun
func updatePackages(ctx context.Context, log logger.Logger, dryRun bool) error {
	ctx, span := otel.StartSpan(ctx, "update-packages")
	defer span.End()

	log.Info("Updating claude-code package...")

	// Check if bun is available
	if _, err := script.Exec("which bun").String(); err != nil {
		span.SetAttributes(attribute.String("reason", "bun_not_found"))
		log.Warning("bun not found - skipping claude-code update")
		return nil
	}

	cmd := "bun update -g @anthropic-ai/claude-code"
	span.SetAttributes(attribute.String("command", cmd))

	if dryRun {
		log.Warning(fmt.Sprintf("[DRY-RUN] Would execute: %s", cmd))
		return nil
	}

	_, err := script.Exec(cmd).String()
	if err != nil {
		span.RecordError(err)
		return fmt.Errorf("failed to update claude-code: %w", err)
	}

	log.Success("✓ claude-code package updated")
	return nil
}

// startClaude starts the claude command with forwarded arguments
func startClaude(ctx context.Context, log logger.Logger, dryRun bool, args []string) error {
	ctx, span := otel.StartSpan(ctx, "start-claude")
	defer span.End()

	span.SetAttributes(
		attribute.StringSlice("args", args),
		attribute.Bool("dry_run", dryRun),
	)

	if dryRun {
		log.Warning(fmt.Sprintf("[DRY-RUN] Would start claude with args: %v", args))
		return nil
	}

	log.Info("Starting claude with forwarded arguments...")

	cmdArgs := append([]string{"claude"}, args...)
	cmd := strings.Join(cmdArgs, " ")
	span.SetAttributes(attribute.String("full_command", cmd))

	// Execute claude with forwarded args
	_, err := script.Exec(cmd).String()
	if err != nil {
		span.RecordError(err)
		return fmt.Errorf("failed to start claude: %w", err)
	}

	return nil
}