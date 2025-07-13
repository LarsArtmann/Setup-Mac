package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/bitfield/script"
	"github.com/fatih/color"
)

// Core Types following functional programming principles
type Profile string

const (
	ProfileDev        Profile = "dev"
	ProfileDevelopment Profile = "development"
	ProfileProd       Profile = "prod"
	ProfileProduction Profile = "production"
	ProfilePersonal   Profile = "personal"
	ProfileDefault    Profile = "default"
)

type ConfigKey string

const (
	KeyTheme                        ConfigKey = "theme"
	KeyParallelTasksCount          ConfigKey = "parallelTasksCount"
	KeyPreferredNotifChannel       ConfigKey = "preferredNotifChannel"
	KeyMessageIdleNotifThresholdMs ConfigKey = "messageIdleNotifThresholdMs"
	KeyAutoUpdates                 ConfigKey = "autoUpdates"
	KeyDiffTool                    ConfigKey = "diffTool"
)

// Config represents the claude configuration structure
type Config struct {
	Theme                        string            `json:"theme"`
	ParallelTasksCount          string            `json:"parallelTasksCount"`
	PreferredNotifChannel       string            `json:"preferredNotifChannel"`
	MessageIdleNotifThresholdMs string            `json:"messageIdleNotifThresholdMs"`
	AutoUpdates                 string            `json:"autoUpdates"`
	DiffTool                    string            `json:"diffTool"`
	Env                         map[string]string `json:"env"`
}

// ProfileConfig contains configuration for a specific profile
type ProfileConfig struct {
	Profile Profile
	Config  Config
	EnvVars map[string]string
}

// ApplicationOptions represents command-line options
type ApplicationOptions struct {
	DryRun       bool
	CreateBackup bool
	Profile      Profile
	Help         bool
	ForwardArgs  []string
}

// Logger interface for colored output
type Logger interface {
	Info(message string)
	Success(message string)
	Warning(message string)
	Error(message string)
}

// ColorLogger implements Logger with colored output
type ColorLogger struct {
	info    *color.Color
	success *color.Color
	warning *color.Color
	error   *color.Color
}

func NewColorLogger() *ColorLogger {
	return &ColorLogger{
		info:    color.New(color.FgBlue, color.Bold),
		success: color.New(color.FgGreen, color.Bold),
		warning: color.New(color.FgYellow, color.Bold),
		error:   color.New(color.FgRed, color.Bold),
	}
}

func (l *ColorLogger) Info(message string) {
	l.info.Printf("[INFO] %s\n", message)
}

func (l *ColorLogger) Success(message string) {
	l.success.Printf("[SUCCESS] %s\n", message)
}

func (l *ColorLogger) Warning(message string) {
	l.warning.Printf("[WARNING] %s\n", message)
}

func (l *ColorLogger) Error(message string) {
	l.error.Printf("[ERROR] %s\n", message)
}

// ConfigReader interface for reading configuration
type ConfigReader interface {
	ReadConfig() (*Config, error)
	InvalidateCache()
}

// CachedConfigReader implements ConfigReader with caching
type CachedConfigReader struct {
	configPath  string
	cache       *Config
	cacheLoaded bool
	logger      Logger
}

func NewCachedConfigReader(logger Logger) *CachedConfigReader {
	homeDir, _ := os.UserHomeDir()
	return &CachedConfigReader{
		configPath:  filepath.Join(homeDir, ".claude.json"),
		cacheLoaded: false,
		logger:      logger,
	}
}

func (r *CachedConfigReader) ReadConfig() (*Config, error) {
	if !r.cacheLoaded {
		if err := r.loadConfig(); err != nil {
			return nil, fmt.Errorf("failed to load config: %w", err)
		}
	}
	return r.cache, nil
}

func (r *CachedConfigReader) loadConfig() error {
	content, err := script.File(r.configPath).String()
	if err != nil {
		// If file doesn't exist, return empty config
		r.cache = &Config{Env: make(map[string]string)}
		r.cacheLoaded = true
		return nil
	}

	var config Config
	if err := json.Unmarshal([]byte(content), &config); err != nil {
		return fmt.Errorf("failed to parse config JSON: %w", err)
	}

	if config.Env == nil {
		config.Env = make(map[string]string)
	}

	r.cache = &config
	r.cacheLoaded = true
	r.logger.Info("Configuration loaded from ~/.claude.json")
	return nil
}

func (r *CachedConfigReader) InvalidateCache() {
	r.cacheLoaded = false
	r.cache = nil
	r.logger.Info("Configuration cache invalidated")
}

// ConfigWriter interface for writing configuration
type ConfigWriter interface {
	WriteConfig(key ConfigKey, value string) error
	WriteEnvConfig(envVars map[string]string) error
}

// ClaudeConfigWriter implements ConfigWriter using claude CLI
type ClaudeConfigWriter struct {
	logger Logger
	dryRun bool
}

func NewClaudeConfigWriter(logger Logger, dryRun bool) *ClaudeConfigWriter {
	return &ClaudeConfigWriter{
		logger: logger,
		dryRun: dryRun,
	}
}

func (w *ClaudeConfigWriter) WriteConfig(key ConfigKey, value string) error {
	cmd := fmt.Sprintf("claude config set -g %s %s", string(key), value)
	
	if w.dryRun {
		w.logger.Warning(fmt.Sprintf("[DRY-RUN] Would execute: %s", cmd))
		return nil
	}

	w.logger.Info(fmt.Sprintf("Setting %s: %s", string(key), value))
	_, err := script.Exec(cmd).String()
	if err != nil {
		return fmt.Errorf("failed to set config %s: %w", string(key), err)
	}

	w.logger.Success(fmt.Sprintf("✓ %s updated", string(key)))
	return nil
}

func (w *ClaudeConfigWriter) WriteEnvConfig(envVars map[string]string) error {
	envJSON, err := json.Marshal(envVars)
	if err != nil {
		return fmt.Errorf("failed to marshal env vars: %w", err)
	}

	cmd := fmt.Sprintf("claude config set -g env '%s'", string(envJSON))
	
	if w.dryRun {
		w.logger.Warning(fmt.Sprintf("[DRY-RUN] Would execute: %s", cmd))
		return nil
	}

	w.logger.Info("Updating environment variables")
	_, err = script.Exec(cmd).String()
	if err != nil {
		return fmt.Errorf("failed to set env config: %w", err)
	}

	w.logger.Success("✓ Environment variables updated")
	return nil
}

// ProfileManager interface for managing configuration profiles
type ProfileManager interface {
	LoadProfile(profile Profile) (*ProfileConfig, error)
	GetAvailableProfiles() []Profile
	ValidateProfile(profile Profile) error
}

// StaticProfileManager implements ProfileManager with static configurations
type StaticProfileManager struct {
	logger Logger
}

func NewStaticProfileManager(logger Logger) *StaticProfileManager {
	return &StaticProfileManager{logger: logger}
}

func (m *StaticProfileManager) LoadProfile(profile Profile) (*ProfileConfig, error) {
	if err := m.ValidateProfile(profile); err != nil {
		return nil, err
	}

	switch profile {
	case ProfileDev, ProfileDevelopment:
		return &ProfileConfig{
			Profile: profile,
			Config: Config{
				Theme:                        "dark-daltonized",
				ParallelTasksCount:          "50",
				PreferredNotifChannel:       "iterm2_with_bell",
				MessageIdleNotifThresholdMs: "500",
				AutoUpdates:                 "false",
				DiffTool:                    "bat",
			},
			EnvVars: map[string]string{
				"EDITOR":                         "nano",
				"CLAUDE_CODE_ENABLE_TELEMETRY":   "1",
				"OTEL_METRICS_EXPORTER":          "otlp",
				"OTEL_LOGS_EXPORTER":             "otlp",
				"OTEL_EXPORTER_OTLP_PROTOCOL":    "grpc",
				"OTEL_EXPORTER_OTLP_ENDPOINT":    "http://localhost:4317",
				"OTEL_METRIC_EXPORT_INTERVAL":    "5000",
				"OTEL_LOGS_EXPORT_INTERVAL":      "2500",
			},
		}, nil

	case ProfileProd, ProfileProduction:
		return &ProfileConfig{
			Profile: profile,
			Config: Config{
				Theme:                        "dark-daltonized",
				ParallelTasksCount:          "10",
				PreferredNotifChannel:       "iterm2_with_bell",
				MessageIdleNotifThresholdMs: "2000",
				AutoUpdates:                 "false",
				DiffTool:                    "bat",
			},
			EnvVars: map[string]string{
				"EDITOR":                       "nano",
				"CLAUDE_CODE_ENABLE_TELEMETRY": "0",
				"OTEL_METRICS_EXPORTER":        "none",
				"OTEL_LOGS_EXPORTER":           "none",
			},
		}, nil

	case ProfilePersonal, ProfileDefault:
		fallthrough
	default:
		return &ProfileConfig{
			Profile: ProfilePersonal,
			Config: Config{
				Theme:                        "dark-daltonized",
				ParallelTasksCount:          "20",
				PreferredNotifChannel:       "iterm2_with_bell",
				MessageIdleNotifThresholdMs: "1000",
				AutoUpdates:                 "false",
				DiffTool:                    "bat",
			},
			EnvVars: map[string]string{
				"EDITOR":                         "nano",
				"CLAUDE_CODE_ENABLE_TELEMETRY":   "1",
				"OTEL_METRICS_EXPORTER":          "otlp",
				"OTEL_LOGS_EXPORTER":             "otlp",
				"OTEL_EXPORTER_OTLP_PROTOCOL":    "grpc",
				"OTEL_EXPORTER_OTLP_ENDPOINT":    "http://localhost:4317",
				"OTEL_METRIC_EXPORT_INTERVAL":    "10000",
				"OTEL_LOGS_EXPORT_INTERVAL":      "5000",
			},
		}, nil
	}
}

func (m *StaticProfileManager) GetAvailableProfiles() []Profile {
	return []Profile{ProfileDev, ProfileProd, ProfilePersonal}
}

func (m *StaticProfileManager) ValidateProfile(profile Profile) error {
	validProfiles := []Profile{
		ProfileDev, ProfileDevelopment,
		ProfileProd, ProfileProduction,
		ProfilePersonal, ProfileDefault,
	}

	for _, valid := range validProfiles {
		if profile == valid {
			return nil
		}
	}

	return fmt.Errorf("invalid profile '%s'. Valid profiles: dev, prod, personal", profile)
}

// ClaudeConfigurator is the main application struct
type ClaudeConfigurator struct {
	configReader   ConfigReader
	configWriter   ConfigWriter
	profileManager ProfileManager
	logger         Logger
	options        ApplicationOptions
}

func NewClaudeConfigurator(options ApplicationOptions) *ClaudeConfigurator {
	logger := NewColorLogger()
	
	return &ClaudeConfigurator{
		configReader:   NewCachedConfigReader(logger),
		configWriter:   NewClaudeConfigWriter(logger, options.DryRun),
		profileManager: NewStaticProfileManager(logger),
		logger:         logger,
		options:        options,
	}
}

func (c *ClaudeConfigurator) Run() error {
	if c.options.Help {
		c.showHelp()
		return nil
	}

	if c.options.DryRun {
		c.logger.Warning("🔍 DRY-RUN MODE: No changes will be applied")
	}

	profile := c.options.Profile
	if profile == "" {
		profile = ProfilePersonal
	}

	c.logger.Info(fmt.Sprintf("Using profile: %s", profile))

	// Load profile configuration
	profileConfig, err := c.profileManager.LoadProfile(profile)
	if err != nil {
		return fmt.Errorf("failed to load profile: %w", err)
	}

	// Configure Claude settings
	if err := c.configureClaudeSettings(profileConfig); err != nil {
		return fmt.Errorf("failed to configure Claude settings: %w", err)
	}

	// Configure environment variables
	if err := c.configureEnvironmentVariables(profileConfig); err != nil {
		return fmt.Errorf("failed to configure environment variables: %w", err)
	}

	// Update packages
	if err := c.updatePackages(); err != nil {
		c.logger.Warning(fmt.Sprintf("Package update failed: %v", err))
	}

	// Validate configuration
	if err := c.validateConfiguration(profileConfig); err != nil {
		return fmt.Errorf("configuration validation failed: %w", err)
	}

	c.logger.Success("Claude configuration complete!")

	// Auto-start claude with forwarded args
	if len(c.options.ForwardArgs) > 0 {
		return c.startClaude(c.options.ForwardArgs)
	}

	return nil
}

func (c *ClaudeConfigurator) configureClaudeSettings(profileConfig *ProfileConfig) error {
	c.logger.Info("Configuring Claude settings...")

	currentConfig, err := c.configReader.ReadConfig()
	if err != nil {
		return err
	}

	settingsMap := map[ConfigKey]string{
		KeyTheme:                        profileConfig.Config.Theme,
		KeyParallelTasksCount:          profileConfig.Config.ParallelTasksCount,
		KeyPreferredNotifChannel:       profileConfig.Config.PreferredNotifChannel,
		KeyMessageIdleNotifThresholdMs: profileConfig.Config.MessageIdleNotifThresholdMs,
		KeyAutoUpdates:                 profileConfig.Config.AutoUpdates,
		KeyDiffTool:                    profileConfig.Config.DiffTool,
	}

	configChanged := false
	for key, newValue := range settingsMap {
		currentValue := c.getCurrentConfigValue(currentConfig, key)
		
		if currentValue != newValue {
			if err := c.configWriter.WriteConfig(key, newValue); err != nil {
				return err
			}
			configChanged = true
		} else {
			c.logger.Info(fmt.Sprintf("✓ %s already set to %s (skipping)", string(key), newValue))
		}
	}

	if configChanged && !c.options.DryRun {
		c.configReader.InvalidateCache()
	}

	return nil
}

func (c *ClaudeConfigurator) getCurrentConfigValue(config *Config, key ConfigKey) string {
	switch key {
	case KeyTheme:
		return config.Theme
	case KeyParallelTasksCount:
		return config.ParallelTasksCount
	case KeyPreferredNotifChannel:
		return config.PreferredNotifChannel
	case KeyMessageIdleNotifThresholdMs:
		return config.MessageIdleNotifThresholdMs
	case KeyAutoUpdates:
		return config.AutoUpdates
	case KeyDiffTool:
		return config.DiffTool
	default:
		return ""
	}
}

func (c *ClaudeConfigurator) configureEnvironmentVariables(profileConfig *ProfileConfig) error {
	c.logger.Info("Configuring environment variables...")

	currentConfig, err := c.configReader.ReadConfig()
	if err != nil {
		return err
	}

	// Compare current env with target env
	envChanged := false
	for key, newValue := range profileConfig.EnvVars {
		currentValue, exists := currentConfig.Env[key]
		if !exists || currentValue != newValue {
			envChanged = true
			break
		}
	}

	if envChanged {
		if err := c.configWriter.WriteEnvConfig(profileConfig.EnvVars); err != nil {
			return err
		}
		if !c.options.DryRun {
			c.configReader.InvalidateCache()
		}
	} else {
		c.logger.Info("✓ Environment variables already configured (skipping)")
	}

	return nil
}

func (c *ClaudeConfigurator) updatePackages() error {
	c.logger.Info("Updating claude-code package...")

	// Check if bun is available
	if _, err := script.Exec("which bun").String(); err != nil {
		c.logger.Warning("bun not found - skipping claude-code update")
		return nil
	}

	cmd := "bun update -g @anthropic-ai/claude-code"
	
	if c.options.DryRun {
		c.logger.Warning(fmt.Sprintf("[DRY-RUN] Would execute: %s", cmd))
		return nil
	}

	_, err := script.Exec(cmd).String()
	if err != nil {
		return fmt.Errorf("failed to update claude-code: %w", err)
	}

	c.logger.Success("✓ claude-code package updated")
	return nil
}

func (c *ClaudeConfigurator) validateConfiguration(profileConfig *ProfileConfig) error {
	if c.options.DryRun {
		c.logger.Warning("[DRY-RUN] Would validate configuration")
		return nil
	}

	c.logger.Info("Validating configuration...")

	// Reload config from file to validate changes
	c.configReader.InvalidateCache()
	currentConfig, err := c.configReader.ReadConfig()
	if err != nil {
		return err
	}

	validationErrors := make([]string, 0)

	settingsMap := map[ConfigKey]string{
		KeyTheme:                        profileConfig.Config.Theme,
		KeyParallelTasksCount:          profileConfig.Config.ParallelTasksCount,
		KeyPreferredNotifChannel:       profileConfig.Config.PreferredNotifChannel,
		KeyMessageIdleNotifThresholdMs: profileConfig.Config.MessageIdleNotifThresholdMs,
		KeyAutoUpdates:                 profileConfig.Config.AutoUpdates,
		KeyDiffTool:                    profileConfig.Config.DiffTool,
	}

	for key, expectedValue := range settingsMap {
		currentValue := c.getCurrentConfigValue(currentConfig, key)
		if currentValue != expectedValue {
			validationErrors = append(validationErrors, 
				fmt.Sprintf("%s: expected '%s', got '%s'", string(key), expectedValue, currentValue))
		}
	}

	if len(validationErrors) > 0 {
		for _, err := range validationErrors {
			c.logger.Error(fmt.Sprintf("❌ %s", err))
		}
		return fmt.Errorf("configuration validation failed")
	}

	c.logger.Success("✓ Configuration validation passed")
	return nil
}

func (c *ClaudeConfigurator) startClaude(args []string) error {
	if c.options.DryRun {
		c.logger.Warning(fmt.Sprintf("[DRY-RUN] Would start claude with args: %v", args))
		return nil
	}

	c.logger.Info("Starting claude with forwarded arguments...")
	
	cmdArgs := append([]string{"claude"}, args...)
	cmd := strings.Join(cmdArgs, " ")
	
	// Execute claude with forwarded args
	_, err := script.Exec(cmd).String()
	if err != nil {
		return fmt.Errorf("failed to start claude: %w", err)
	}

	return nil
}

func (c *ClaudeConfigurator) showHelp() {
	fmt.Println("Better Claude Configuration Tool")
	fmt.Println("================================")
	fmt.Println("")
	fmt.Println("Usage: better-claude [OPTIONS] [-- CLAUDE_ARGS...]")
	fmt.Println("")
	fmt.Println("Options:")
	fmt.Println("  --dry-run              Preview changes without applying them")
	fmt.Println("  --backup               Create backup before applying changes")
	fmt.Println("  --profile PROFILE      Use configuration profile (dev/prod/personal)")
	fmt.Println("  --help                 Show this help message")
	fmt.Println("")
	fmt.Println("Profiles:")
	fmt.Println("  dev/development        High performance settings for development")
	fmt.Println("  prod/production        Conservative settings for production")
	fmt.Println("  personal/default       Balanced settings for personal use")
	fmt.Println("")
	fmt.Println("Arguments after '--' are forwarded to claude command")
	fmt.Println("Example: better-claude --profile dev -- chat")
}

func parseArgs() ApplicationOptions {
	args := os.Args[1:]
	options := ApplicationOptions{
		Profile: ProfilePersonal,
	}

	i := 0
	for i < len(args) {
		switch args[i] {
		case "--dry-run":
			options.DryRun = true
		case "--backup":
			options.CreateBackup = true
		case "--profile":
			if i+1 < len(args) {
				options.Profile = Profile(args[i+1])
				i++
			}
		case "--help":
			options.Help = true
		case "--":
			// Everything after -- is forwarded to claude
			if i+1 < len(args) {
				options.ForwardArgs = args[i+1:]
			}
			return options
		default:
			// Unknown option, could be part of forwarded args
			options.ForwardArgs = args[i:]
			return options
		}
		i++
	}

	return options
}

func main() {
	options := parseArgs()
	
	configurator := NewClaudeConfigurator(options)
	
	if err := configurator.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}