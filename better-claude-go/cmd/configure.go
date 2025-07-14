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
	"better-claude/internal/profiles"
)

// configureCmd represents the configure command
var configureCmd = &cobra.Command{
	Use:   "configure",
	Short: "Configure Claude with the specified profile",
	Long: `Configure Claude AI settings using predefined profiles.
	
Profiles available:
- dev/development: High performance settings for development
- prod/production: Conservative settings for production  
- personal/default: Balanced settings for personal use`,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := context.Background()
		ctx, span := otel.StartSpan(ctx, "configure-command")
		defer span.End()

		// Get configuration options
		dryRun := viper.GetBool("dry-run")
		backup := viper.GetBool("backup")
		profileName := viper.GetString("profile")

		span.SetAttributes(
			attribute.String("profile", profileName),
			attribute.Bool("dry_run", dryRun),
			attribute.Bool("backup", backup),
		)

		// Initialize logger
		log := logger.NewColorLogger()

		// Initialize profile manager
		profileManager := profiles.NewStaticProfileManager(log)

		// Validate profile
		if err := profileManager.ValidateProfile(profiles.Profile(profileName)); err != nil {
			span.RecordError(err)
			return err
		}

		// Load profile configuration
		profileConfig, err := profileManager.LoadProfile(profiles.Profile(profileName))
		if err != nil {
			span.RecordError(err)
			return fmt.Errorf("failed to load profile: %w", err)
		}

		log.Info(fmt.Sprintf("Using profile: %s", profileName))

		// Create backup if requested
		if backup {
			backupManager := config.NewFileBackupManager(log, dryRun)
			backupPath, err := backupManager.CreateBackup(profiles.Profile(profileName))
			if err != nil {
				span.RecordError(err)
				return fmt.Errorf("failed to create backup: %w", err)
			}
			if backupPath != "" {
				log.Success(fmt.Sprintf("Backup created: %s", backupPath))
			}
		}

		// Initialize config manager
		configManager := config.NewViperConfigManager(log, dryRun)

		// Configure Claude settings using functional programming patterns
		settingsMap := map[config.ConfigKey]string{
			config.KeyTheme:                        profileConfig.Config.Theme,
			config.KeyParallelTasksCount:          profileConfig.Config.ParallelTasksCount,
			config.KeyPreferredNotifChannel:       profileConfig.Config.PreferredNotifChannel,
			config.KeyMessageIdleNotifThresholdMs: profileConfig.Config.MessageIdleNotifThresholdMs,
			config.KeyAutoUpdates:                 profileConfig.Config.AutoUpdates,
			config.KeyDiffTool:                    profileConfig.Config.DiffTool,
		}

		// Use samber/lo for functional operations
		keys := lo.Keys(settingsMap)
		errors := lo.FilterMap(keys, func(key config.ConfigKey, _ int) (error, bool) {
			value := settingsMap[key]
			err := configManager.WriteConfig(key, value)
			return err, err != nil
		})

		if len(errors) > 0 {
			firstError := errors[0]
			span.RecordError(firstError)
			return fmt.Errorf("failed to configure settings: %w", firstError)
		}

		// Configure environment variables
		if err := configManager.WriteEnvConfig(profileConfig.EnvVars); err != nil {
			span.RecordError(err)
			return fmt.Errorf("failed to configure environment variables: %w", err)
		}

		// Update packages
		if err := updatePackages(ctx, log, dryRun); err != nil {
			log.Warning(fmt.Sprintf("Package update failed: %v", err))
		}

		log.Success("Claude configuration complete!")

		// Auto-start claude with forwarded args if provided
		if len(args) > 0 {
			return startClaude(ctx, log, dryRun, args)
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(configureCmd)
}