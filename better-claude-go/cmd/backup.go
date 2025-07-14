package cmd

import (
	"context"
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"go.opentelemetry.io/otel/attribute"

	"better-claude/internal/config"
	"better-claude/internal/logger"
	"better-claude/internal/otel"
	"better-claude/internal/profiles"
)

// backupCmd represents the backup command
var backupCmd = &cobra.Command{
	Use:   "backup",
	Short: "Create a backup of the current Claude configuration",
	Long: `Create a timestamped backup of the current Claude configuration.
	
The backup will be saved with the current profile name and timestamp:
claude-config-{profile}-{timestamp}.json`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := context.Background()
		ctx, span := otel.StartSpan(ctx, "backup-command")
		defer span.End()

		dryRun := viper.GetBool("dry-run")
		profileName := viper.GetString("profile")

		span.SetAttributes(
			attribute.String("profile", profileName),
			attribute.Bool("dry_run", dryRun),
		)

		log := logger.NewColorLogger()
		backupManager := config.NewFileBackupManager(log, dryRun)

		backupPath, err := backupManager.CreateBackup(profiles.Profile(profileName))
		if err != nil {
			span.RecordError(err)
			return fmt.Errorf("failed to create backup: %w", err)
		}

		if backupPath != "" {
			log.Success(fmt.Sprintf("Backup created: %s", backupPath))
		} else {
			log.Warning("No configuration file found to backup")
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(backupCmd)
}