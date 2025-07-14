package cmd

import (
	"context"
	"fmt"
	"os"

	"better-claude/internal/otel"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	cfgFile string
	dryRun  bool
	backup  bool
	profile string
)

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "better-claude",
	Short: "A powerful configuration manager for Claude AI",
	Long: `Better Claude is a configuration management tool that helps you maintain
different profiles for Claude AI with proper backup, validation, and OTEL instrumentation.

Features:
- Profile-based configuration management (dev/prod/personal)
- Automatic backups before changes
- Configuration validation and error handling
- OpenTelemetry instrumentation for observability
- Functional programming patterns with samber/lo`,
	Run: func(cmd *cobra.Command, args []string) {
		ctx := context.Background()
		ctx, span := otel.StartSpan(ctx, "root-command")
		defer span.End()

		// If no subcommand specified, run the configure command by default
		configureCmd.Run(cmd, args)
	},
}

// Execute adds all child commands to the root command and sets flags appropriately.
func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)

	// Global flags
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.claude.yaml)")
	rootCmd.PersistentFlags().BoolVar(&dryRun, "dry-run", false, "Preview changes without applying them")
	rootCmd.PersistentFlags().BoolVar(&backup, "backup", false, "Create backup before applying changes")
	rootCmd.PersistentFlags().StringVar(&profile, "profile", "personal", "Configuration profile (dev/prod/personal)")

	// Bind flags to viper
	viper.BindPFlag("dry-run", rootCmd.PersistentFlags().Lookup("dry-run"))
	viper.BindPFlag("backup", rootCmd.PersistentFlags().Lookup("backup"))
	viper.BindPFlag("profile", rootCmd.PersistentFlags().Lookup("profile"))
}

// initConfig reads in config file and ENV variables.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := os.UserHomeDir()
		cobra.CheckErr(err)

		// Search config in home directory with name ".claude" (without extension).
		viper.AddConfigPath(home)
		viper.AddConfigPath(".")
		viper.SetConfigType("yaml")
		viper.SetConfigName(".claude")
	}

	// Environment variable support
	viper.SetEnvPrefix("CLAUDE")
	viper.AutomaticEnv()

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
	}
}