package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/bitfield/script"
	"github.com/samber/lo"
	"github.com/spf13/viper"

	"better-claude/internal/logger"
)

// ViperConfigManager implements ConfigManager using viper for configuration management
type ViperConfigManager struct {
	logger      logger.Logger
	dryRun      bool
	configPath  string
	viper       *viper.Viper
	cache       *Config
	cacheLoaded bool
}

func NewViperConfigManager(logger logger.Logger, dryRun bool) *ViperConfigManager {
	homeDir := lo.Must(os.UserHomeDir())
	v := viper.New()

	// Configure viper for Claude config
	v.SetConfigName(".claude")
	v.SetConfigType("json")
	v.AddConfigPath(homeDir)
	v.AddConfigPath(".")

	// Environment variable support
	v.SetEnvPrefix("CLAUDE")
	v.AutomaticEnv()

	return &ViperConfigManager{
		logger:     logger,
		dryRun:     dryRun,
		configPath: filepath.Join(homeDir, ".claude.json"),
		viper:      v,
	}
}

func (m *ViperConfigManager) WriteConfig(key ConfigKey, value string) error {
	cmd := fmt.Sprintf("claude config set -g %s %s", string(key), value)

	if m.dryRun {
		m.logger.Warning(fmt.Sprintf("[DRY-RUN] Would execute: %s", cmd))
		return nil
	}

	m.logger.Info(fmt.Sprintf("Setting %s: %s", string(key), value))
	_, err := script.Exec(cmd).String()
	if err != nil {
		return fmt.Errorf("failed to set config %s: %w", string(key), err)
	}

	m.logger.Success(fmt.Sprintf("✓ %s updated", string(key)))
	m.InvalidateCache()
	return nil
}

func (m *ViperConfigManager) WriteEnvConfig(envVars map[string]string) error {
	envJSON := lo.Must(json.Marshal(envVars))
	cmd := fmt.Sprintf("claude config set -g env '%s'", string(envJSON))

	if m.dryRun {
		m.logger.Warning(fmt.Sprintf("[DRY-RUN] Would execute: %s", cmd))
		return nil
	}

	m.logger.Info("Updating environment variables")
	_, err := script.Exec(cmd).String()
	if err != nil {
		return fmt.Errorf("failed to set env config: %w", err)
	}

	m.logger.Success("✓ Environment variables updated")
	m.InvalidateCache()
	return nil
}

func (m *ViperConfigManager) ReadConfig() (*Config, error) {
	if !m.cacheLoaded {
		if err := m.loadConfig(); err != nil {
			return nil, fmt.Errorf("failed to load config: %w", err)
		}
	}
	return m.cache, nil
}

func (m *ViperConfigManager) loadConfig() error {
	// Try to read config file
	if err := m.viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			// Config file not found; use defaults
			m.cache = &Config{Env: make(map[string]string)}
			m.cacheLoaded = true
			return nil
		}
		return fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	if err := m.viper.Unmarshal(&config); err != nil {
		return fmt.Errorf("failed to unmarshal config: %w", err)
	}

	if config.Env == nil {
		config.Env = make(map[string]string)
	}

	m.cache = &config
	m.cacheLoaded = true
	m.logger.Info("Configuration loaded from ~/.claude.json")
	return nil
}

func (m *ViperConfigManager) InvalidateCache() {
	m.cacheLoaded = false
	m.cache = nil
	m.logger.Info("Configuration cache invalidated")
}

// GetCurrentConfigValue returns the current value for a given config key using functional patterns
func (m *ViperConfigManager) GetCurrentConfigValue(config *Config, key ConfigKey) string {
	configValueMap := map[ConfigKey]func(*Config) string{
		KeyTheme:                       func(c *Config) string { return c.Theme },
		KeyParallelTasksCount:          func(c *Config) string { return c.ParallelTasksCount },
		KeyPreferredNotifChannel:       func(c *Config) string { return c.PreferredNotifChannel },
		KeyMessageIdleNotifThresholdMs: func(c *Config) string { return c.MessageIdleNotifThresholdMs },
		KeyAutoUpdates:                 func(c *Config) string { return c.AutoUpdates },
		KeyDiffTool:                    func(c *Config) string { return c.DiffTool },
	}

	getValue, exists := configValueMap[key]
	if !exists {
		return ""
	}
	return getValue(config)
}
