// Package config provides type-safe configuration management for Better Claude.
// It defines profile-based configuration with strong typing and validation.
package config

// Profile represents different configuration profiles for environment-specific settings.
// Profiles allow users to quickly switch between optimized settings for different use cases.
type Profile string

const (
	// ProfileDev is optimized for development work with high performance settings
	ProfileDev Profile = "dev"
	// ProfileDevelopment is an alias for ProfileDev for user convenience
	ProfileDevelopment Profile = "development"
	// ProfileProd provides conservative settings suitable for production environments
	ProfileProd Profile = "prod"
	// ProfileProduction is an alias for ProfileProd for user convenience
	ProfileProduction Profile = "production"
	// ProfilePersonal offers balanced settings for personal use
	ProfilePersonal Profile = "personal"
	// ProfileDefault is an alias for ProfilePersonal
	ProfileDefault Profile = "default"
)

// ConfigKey represents configuration keys with type safety to prevent typos.
// Using typed constants helps catch configuration errors at compile time.
type ConfigKey string

const (
	// KeyTheme controls the Claude interface theme (e.g., "dark-daltonized")
	KeyTheme ConfigKey = "theme"
	// KeyParallelTasksCount sets the number of concurrent tasks (performance tuning)
	KeyParallelTasksCount ConfigKey = "parallelTasksCount"
	// KeyPreferredNotifChannel configures notification delivery method
	KeyPreferredNotifChannel ConfigKey = "preferredNotifChannel"
	// KeyMessageIdleNotifThresholdMs sets the idle time before notifications (in milliseconds)
	KeyMessageIdleNotifThresholdMs ConfigKey = "messageIdleNotifThresholdMs"
	// KeyAutoUpdates controls automatic package updates (security consideration)
	KeyAutoUpdates ConfigKey = "autoUpdates"
	// KeyDiffTool specifies the diff utility for comparing changes
	KeyDiffTool ConfigKey = "diffTool"
)

// Config represents the claude configuration structure with viper support.
// All fields are strings to maintain compatibility with Claude CLI and allow
// flexible configuration through environment variables and config files.
type Config struct {
	// Theme controls the visual appearance of the Claude interface
	Theme string `mapstructure:"theme" yaml:"theme" json:"theme"`
	// ParallelTasksCount determines how many operations run concurrently (performance setting)
	ParallelTasksCount string `mapstructure:"parallelTasksCount" yaml:"parallelTasksCount" json:"parallelTasksCount"`
	// PreferredNotifChannel sets the preferred method for receiving notifications
	PreferredNotifChannel string `mapstructure:"preferredNotifChannel" yaml:"preferredNotifChannel" json:"preferredNotifChannel"`
	// MessageIdleNotifThresholdMs configures when idle notifications are triggered
	MessageIdleNotifThresholdMs string `mapstructure:"messageIdleNotifThresholdMs" yaml:"messageIdleNotifThresholdMs" json:"messageIdleNotifThresholdMs"`
	// AutoUpdates controls whether Claude automatically updates packages
	AutoUpdates string `mapstructure:"autoUpdates" yaml:"autoUpdates" json:"autoUpdates"`
	// DiffTool specifies which tool to use for displaying diffs
	DiffTool string `mapstructure:"diffTool" yaml:"diffTool" json:"diffTool"`
	// Env contains environment variables to be set for Claude operations
	Env map[string]string `mapstructure:"env" yaml:"env" json:"env"`
}

// ProfileConfig contains configuration for a specific profile including both
// Claude settings and environment variables. This combines all profile-specific
// configuration in a single structure for easy management.
type ProfileConfig struct {
	// Profile identifies which profile this configuration represents
	Profile Profile
	// Config contains the Claude-specific configuration settings
	Config Config
	// EnvVars contains environment variables specific to this profile
	EnvVars map[string]string
}

// ConfigManager interface defines the contract for configuration management.
// This interface allows for different implementations (file-based, remote, etc.)
// while maintaining a consistent API for configuration operations.
type ConfigManager interface {
	// WriteConfig applies a single configuration setting
	WriteConfig(key ConfigKey, value string) error
	// WriteEnvConfig applies a set of environment variables
	WriteEnvConfig(envVars map[string]string) error
	// ReadConfig retrieves the current configuration
	ReadConfig() (*Config, error)
	// InvalidateCache clears any cached configuration data
	InvalidateCache()
}

// BackupManager interface defines the contract for backup operations.
// This allows for different backup strategies while maintaining a consistent API.
type BackupManager interface {
	// CreateBackup creates a timestamped backup for the specified profile
	CreateBackup(profile Profile) (string, error)
	// RestoreBackup restores configuration from a backup file
	RestoreBackup(backupPath string) error
	// ListBackups returns available backup files
	ListBackups() ([]string, error)
}
