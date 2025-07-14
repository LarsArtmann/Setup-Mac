package main

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"better-claude/internal/config"
)

// TestFixtures provides reusable test data and builders
type TestFixtures struct{}

// ProfileConfigBuilder provides a fluent interface for building ProfileConfig test data
type ProfileConfigBuilder struct {
	profile config.Profile
	config  config.Config
	envVars map[string]string
}

func NewProfileConfigBuilder() *ProfileConfigBuilder {
	return &ProfileConfigBuilder{
		profile: config.ProfilePersonal,
		config: Config{
			Theme:                       "dark-daltonized",
			ParallelTasksCount:          "20",
			PreferredNotifChannel:       "iterm2_with_bell",
			MessageIdleNotifThresholdMs: "1000",
			AutoUpdates:                 "false",
			DiffTool:                    "bat",
			Env:                         make(map[string]string),
		},
		envVars: map[string]string{
			"EDITOR":                       "nano",
			"CLAUDE_CODE_ENABLE_TELEMETRY": "1",
		},
	}
}

func (b *ProfileConfigBuilder) WithProfile(profile Profile) *ProfileConfigBuilder {
	b.profile = profile
	return b
}

func (b *ProfileConfigBuilder) WithTheme(theme string) *ProfileConfigBuilder {
	b.config.Theme = theme
	return b
}

func (b *ProfileConfigBuilder) WithParallelTasksCount(count string) *ProfileConfigBuilder {
	b.config.ParallelTasksCount = count
	return b
}

func (b *ProfileConfigBuilder) WithNotificationChannel(channel string) *ProfileConfigBuilder {
	b.config.PreferredNotifChannel = channel
	return b
}

func (b *ProfileConfigBuilder) WithMessageIdleThreshold(threshold string) *ProfileConfigBuilder {
	b.config.MessageIdleNotifThresholdMs = threshold
	return b
}

func (b *ProfileConfigBuilder) WithAutoUpdates(enabled string) *ProfileConfigBuilder {
	b.config.AutoUpdates = enabled
	return b
}

func (b *ProfileConfigBuilder) WithDiffTool(tool string) *ProfileConfigBuilder {
	b.config.DiffTool = tool
	return b
}

func (b *ProfileConfigBuilder) WithEnvVar(key, value string) *ProfileConfigBuilder {
	if b.envVars == nil {
		b.envVars = make(map[string]string)
	}
	b.envVars[key] = value
	return b
}

func (b *ProfileConfigBuilder) WithEnvVars(envVars map[string]string) *ProfileConfigBuilder {
	b.envVars = envVars
	return b
}

func (b *ProfileConfigBuilder) Build() *ProfileConfig {
	return &ProfileConfig{
		Profile: b.profile,
		Config:  b.config,
		EnvVars: b.envVars,
	}
}

// ConfigBuilder provides a fluent interface for building Config test data
type ConfigBuilder struct {
	config config.Config
}

func NewConfigBuilder() *ConfigBuilder {
	return &ConfigBuilder{
		config: config.Config{
			Theme:                       "dark-daltonized",
			ParallelTasksCount:          "20",
			PreferredNotifChannel:       "iterm2_with_bell",
			MessageIdleNotifThresholdMs: "1000",
			AutoUpdates:                 "false",
			DiffTool:                    "bat",
			Env:                         make(map[string]string),
		},
	}
}

func (b *ConfigBuilder) WithTheme(theme string) *ConfigBuilder {
	b.config.Theme = theme
	return b
}

func (b *ConfigBuilder) WithParallelTasksCount(count string) *ConfigBuilder {
	b.config.ParallelTasksCount = count
	return b
}

func (b *ConfigBuilder) WithNotificationChannel(channel string) *ConfigBuilder {
	b.config.PreferredNotifChannel = channel
	return b
}

func (b *ConfigBuilder) WithMessageIdleThreshold(threshold string) *ConfigBuilder {
	b.config.MessageIdleNotifThresholdMs = threshold
	return b
}

func (b *ConfigBuilder) WithAutoUpdates(enabled string) *ConfigBuilder {
	b.config.AutoUpdates = enabled
	return b
}

func (b *ConfigBuilder) WithDiffTool(tool string) *ConfigBuilder {
	b.config.DiffTool = tool
	return b
}

func (b *ConfigBuilder) WithEnvVar(key, value string) *ConfigBuilder {
	if b.config.Env == nil {
		b.config.Env = make(map[string]string)
	}
	b.config.Env[key] = value
	return b
}

func (b *ConfigBuilder) WithEmptyEnv() *ConfigBuilder {
	b.config.Env = make(map[string]string)
	return b
}

func (b *ConfigBuilder) Build() Config {
	return b.config
}

// ApplicationOptionsBuilder provides a fluent interface for building ApplicationOptions test data
type ApplicationOptionsBuilder struct {
	options ApplicationOptions
}

func NewApplicationOptionsBuilder() *ApplicationOptionsBuilder {
	return &ApplicationOptionsBuilder{
		options: ApplicationOptions{
			DryRun:       false,
			CreateBackup: false,
			Profile:      ProfilePersonal,
			Help:         false,
			ForwardArgs:  []string{},
		},
	}
}

func (b *ApplicationOptionsBuilder) WithDryRun(dryRun bool) *ApplicationOptionsBuilder {
	b.options.DryRun = dryRun
	return b
}

func (b *ApplicationOptionsBuilder) WithCreateBackup(createBackup bool) *ApplicationOptionsBuilder {
	b.options.CreateBackup = createBackup
	return b
}

func (b *ApplicationOptionsBuilder) WithProfile(profile Profile) *ApplicationOptionsBuilder {
	b.options.Profile = profile
	return b
}

func (b *ApplicationOptionsBuilder) WithHelp(help bool) *ApplicationOptionsBuilder {
	b.options.Help = help
	return b
}

func (b *ApplicationOptionsBuilder) WithForwardArgs(args ...string) *ApplicationOptionsBuilder {
	b.options.ForwardArgs = args
	return b
}

func (b *ApplicationOptionsBuilder) Build() ApplicationOptions {
	return b.options
}

// Test data constants
var (
	ValidProfiles = []Profile{
		ProfileDev, ProfileDevelopment,
		ProfileProd, ProfileProduction,
		ProfilePersonal, ProfileDefault,
	}

	InvalidProfiles = []Profile{
		"invalid", "test", "", "DEV", "PROD",
	}

	ValidThemes = []string{
		"dark-daltonized", "light", "dark", "auto",
	}

	ValidNotificationChannels = []string{
		"iterm2_with_bell", "desktop", "none",
	}

	ValidDiffTools = []string{
		"bat", "diff", "delta", "code",
	}

	ValidParallelTasksCounts = []string{
		"1", "10", "20", "50", "100", "1000",
	}

	InvalidParallelTasksCounts = []string{
		"0", "-1", "1001", "abc", "", "10.5",
	}

	ValidMessageIdleThresholds = []string{
		"0", "500", "1000", "2000", "60000",
	}

	InvalidMessageIdleThresholds = []string{
		"-1", "60001", "abc", "", "1000.5",
	}

	ValidAutoUpdatesValues = []string{
		"true", "false",
	}

	InvalidAutoUpdatesValues = []string{
		"yes", "no", "1", "0", "", "TRUE", "FALSE",
	}
)

// Mock implementations for testing
type MockLogger struct {
	InfoMessages    []string
	SuccessMessages []string
	WarningMessages []string
	ErrorMessages   []string
}

func NewMockLogger() *MockLogger {
	return &MockLogger{
		InfoMessages:    []string{},
		SuccessMessages: []string{},
		WarningMessages: []string{},
		ErrorMessages:   []string{},
	}
}

func (m *MockLogger) Info(message string) {
	m.InfoMessages = append(m.InfoMessages, message)
}

func (m *MockLogger) Success(message string) {
	m.SuccessMessages = append(m.SuccessMessages, message)
}

func (m *MockLogger) Warning(message string) {
	m.WarningMessages = append(m.WarningMessages, message)
}

func (m *MockLogger) Error(message string) {
	m.ErrorMessages = append(m.ErrorMessages, message)
}

func (m *MockLogger) Reset() {
	m.InfoMessages = []string{}
	m.SuccessMessages = []string{}
	m.WarningMessages = []string{}
	m.ErrorMessages = []string{}
}

// MockConfigReader for testing
type MockConfigReader struct {
	config      *Config
	shouldError bool
	errorMsg    string
	cacheValid  bool
}

func NewMockConfigReader() *MockConfigReader {
	return &MockConfigReader{
		config: &Config{
			Theme:                       "dark-daltonized",
			ParallelTasksCount:          "20",
			PreferredNotifChannel:       "iterm2_with_bell",
			MessageIdleNotifThresholdMs: "1000",
			AutoUpdates:                 "false",
			DiffTool:                    "bat",
			Env:                         make(map[string]string),
		},
		shouldError: false,
		cacheValid:  true,
	}
}

func (m *MockConfigReader) ReadConfig() (*Config, error) {
	if m.shouldError {
		return nil, fmt.Errorf(m.errorMsg)
	}
	return m.config, nil
}

func (m *MockConfigReader) InvalidateCache() {
	m.cacheValid = false
}

func (m *MockConfigReader) SetConfig(config *Config) {
	m.config = config
}

func (m *MockConfigReader) SetError(shouldError bool, errorMsg string) {
	m.shouldError = shouldError
	m.errorMsg = errorMsg
}

// MockConfigWriter for testing
type MockConfigWriter struct {
	writtenConfigs map[ConfigKey]string
	writtenEnvVars map[string]string
	shouldError    bool
	errorMsg       string
}

func NewMockConfigWriter() *MockConfigWriter {
	return &MockConfigWriter{
		writtenConfigs: make(map[ConfigKey]string),
		writtenEnvVars: make(map[string]string),
		shouldError:    false,
	}
}

func (m *MockConfigWriter) WriteConfig(key ConfigKey, value string) error {
	if m.shouldError {
		return fmt.Errorf(m.errorMsg)
	}
	m.writtenConfigs[key] = value
	return nil
}

func (m *MockConfigWriter) WriteEnvConfig(envVars map[string]string) error {
	if m.shouldError {
		return fmt.Errorf(m.errorMsg)
	}
	for k, v := range envVars {
		m.writtenEnvVars[k] = v
	}
	return nil
}

func (m *MockConfigWriter) SetError(shouldError bool, errorMsg string) {
	m.shouldError = shouldError
	m.errorMsg = errorMsg
}

func (m *MockConfigWriter) GetWrittenConfig(key ConfigKey) (string, bool) {
	value, exists := m.writtenConfigs[key]
	return value, exists
}

func (m *MockConfigWriter) GetWrittenEnvVar(key string) (string, bool) {
	value, exists := m.writtenEnvVars[key]
	return value, exists
}

// MockBackupManager for testing
type MockBackupManager struct {
	backups        []string
	shouldError    bool
	errorMsg       string
	lastBackupPath string
}

func NewMockBackupManager() *MockBackupManager {
	return &MockBackupManager{
		backups:     []string{},
		shouldError: false,
	}
}

func (m *MockBackupManager) CreateBackup(profile Profile) (string, error) {
	if m.shouldError {
		return "", fmt.Errorf(m.errorMsg)
	}

	timestamp := time.Now().Format("20060102_150405")
	backupPath := filepath.Join(os.TempDir(), fmt.Sprintf("claude-config-%s-%s.json", profile, timestamp))
	m.lastBackupPath = backupPath
	m.backups = append(m.backups, backupPath)
	return backupPath, nil
}

func (m *MockBackupManager) RestoreBackup(backupPath string) error {
	if m.shouldError {
		return fmt.Errorf(m.errorMsg)
	}
	return nil
}

func (m *MockBackupManager) ListBackups() ([]string, error) {
	if m.shouldError {
		return nil, fmt.Errorf(m.errorMsg)
	}
	return m.backups, nil
}

func (m *MockBackupManager) SetError(shouldError bool, errorMsg string) {
	m.shouldError = shouldError
	m.errorMsg = errorMsg
}

func (m *MockBackupManager) GetLastBackupPath() string {
	return m.lastBackupPath
}
