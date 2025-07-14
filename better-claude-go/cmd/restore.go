package cmd

import (
	"context"
	"fmt"

	"github.com/samber/lo"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"go.opentelemetry.io/otel/attribute"

	"better-claude/internal/config"
	"better-claude/internal/logger"
	"better-claude/internal/otel"
)

// restoreCmd represents the restore command
var restoreCmd = &cobra.Command{
	Use:   "restore [backup-file]",
	Short: "Restore Claude configuration from a backup",
	Long: `Restore Claude configuration from a previously created backup file.
	
If no backup file is specified, the command will list available backups.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := context.Background()
		ctx, span := otel.StartSpan(ctx, "restore-command")
		defer span.End()

		dryRun := viper.GetBool("dry-run")

		span.SetAttributes(
			attribute.Bool("dry_run", dryRun),
			attribute.Int("args_count", len(args)),
		)

		log := logger.NewColorLogger()
		backupManager := config.NewFileBackupManager(log, dryRun)

		// If no backup file specified, list available backups
		if len(args) == 0 {
			backups, err := backupManager.ListBackups()
			if err != nil {
				span.RecordError(err)
				return fmt.Errorf("failed to list backups: %w", err)
			}

			if len(backups) == 0 {
				log.Warning("No backups found")
				return nil
			}

			log.Info("Available backups:")
			lo.ForEach(backups, func(backup string, index int) {
				fmt.Printf("  %d. %s\n", index+1, backup)
			})

			log.Info("To restore a backup, run: better-claude restore <backup-file>")
			return nil
		}

		backupFile := args[0]
		span.SetAttributes(attribute.String("backup_file", backupFile))

		log.Info(fmt.Sprintf("Restoring configuration from: %s", backupFile))

		if err := backupManager.RestoreBackup(backupFile); err != nil {
			span.RecordError(err)
			return fmt.Errorf("failed to restore backup: %w", err)
		}

		log.Success("Configuration restored successfully!")
		return nil
	},
}

func init() {
	rootCmd.AddCommand(restoreCmd)
}