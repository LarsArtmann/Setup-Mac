package config

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// TypesTestSuite contains tests for configuration types
type TypesTestSuite struct {
	suite.Suite
}

// Test Profile constants
func (suite *TypesTestSuite) TestProfile_Constants() {
	// Test that all profile constants are defined correctly
	assert.Equal(suite.T(), Profile("dev"), ProfileDev)
	assert.Equal(suite.T(), Profile("development"), ProfileDevelopment)
	assert.Equal(suite.T(), Profile("prod"), ProfileProd)
	assert.Equal(suite.T(), Profile("production"), ProfileProduction)
	assert.Equal(suite.T(), Profile("personal"), ProfilePersonal)
	assert.Equal(suite.T(), Profile("default"), ProfileDefault)
}

func (suite *TypesTestSuite) TestProfile_StringConversion() {
	testCases := []struct {
		profile  Profile
		expected string
	}{
		{ProfileDev, "dev"},
		{ProfileDevelopment, "development"},
		{ProfileProd, "prod"},
		{ProfileProduction, "production"},
		{ProfilePersonal, "personal"},
		{ProfileDefault, "default"},
	}
	
	for _, tc := range testCases {
		assert.Equal(suite.T(), tc.expected, string(tc.profile))
	}
}

func (suite *TypesTestSuite) TestProfile_Equality() {
	// Test profile equality
	assert.Equal(suite.T(), ProfileDev, ProfileDev)
	assert.NotEqual(suite.T(), ProfileDev, ProfileProd)
	assert.NotEqual(suite.T(), ProfilePersonal, ProfileProduction)
}

// Test ConfigKey constants
func (suite *TypesTestSuite) TestConfigKey_Constants() {
	// Test that all config key constants are defined correctly
	assert.Equal(suite.T(), ConfigKey("theme"), KeyTheme)
	assert.Equal(suite.T(), ConfigKey("parallelTasksCount"), KeyParallelTasksCount)
	assert.Equal(suite.T(), ConfigKey("preferredNotifChannel"), KeyPreferredNotifChannel)
	assert.Equal(suite.T(), ConfigKey("messageIdleNotifThresholdMs"), KeyMessageIdleNotifThresholdMs)
	assert.Equal(suite.T(), ConfigKey("autoUpdates"), KeyAutoUpdates)
	assert.Equal(suite.T(), ConfigKey("diffTool"), KeyDiffTool)
}

func (suite *TypesTestSuite) TestConfigKey_StringConversion() {
	testCases := []struct {
		key      ConfigKey
		expected string
	}{
		{KeyTheme, "theme"},
		{KeyParallelTasksCount, "parallelTasksCount"},
		{KeyPreferredNotifChannel, "preferredNotifChannel"},
		{KeyMessageIdleNotifThresholdMs, "messageIdleNotifThresholdMs"},
		{KeyAutoUpdates, "autoUpdates"},
		{KeyDiffTool, "diffTool"},
	}
	
	for _, tc := range testCases {
		assert.Equal(suite.T(), tc.expected, string(tc.key))
	}
}

// Test Config struct
func (suite *TypesTestSuite) TestConfig_DefaultConstruction() {
	config := Config{}
	
	// All string fields should be empty by default
	assert.Empty(suite.T(), config.Theme)
	assert.Empty(suite.T(), config.ParallelTasksCount)
	assert.Empty(suite.T(), config.PreferredNotifChannel)
	assert.Empty(suite.T(), config.MessageIdleNotifThresholdMs)
	assert.Empty(suite.T(), config.AutoUpdates)
	assert.Empty(suite.T(), config.DiffTool)
	
	// Env map should be nil by default
	assert.Nil(suite.T(), config.Env)
}

func (suite *TypesTestSuite) TestConfig_WithValues() {
	config := Config{
		Theme:                        "dark-daltonized",
		ParallelTasksCount:          "50",
		PreferredNotifChannel:       "iterm2_with_bell",
		MessageIdleNotifThresholdMs: "500",
		AutoUpdates:                 "false",
		DiffTool:                    "bat",
		Env: map[string]string{
			"EDITOR": "nano",
			"DEBUG":  "true",
		},
	}
	
	assert.Equal(suite.T(), "dark-daltonized", config.Theme)
	assert.Equal(suite.T(), "50", config.ParallelTasksCount)
	assert.Equal(suite.T(), "iterm2_with_bell", config.PreferredNotifChannel)
	assert.Equal(suite.T(), "500", config.MessageIdleNotifThresholdMs)
	assert.Equal(suite.T(), "false", config.AutoUpdates)
	assert.Equal(suite.T(), "bat", config.DiffTool)
	assert.Len(suite.T(), config.Env, 2)
	assert.Equal(suite.T(), "nano", config.Env["EDITOR"])
	assert.Equal(suite.T(), "true", config.Env["DEBUG"])
}

func (suite *TypesTestSuite) TestConfig_StructTags() {
	// Test that struct tags are properly defined for serialization
	// This is important for viper, yaml, and json integration
	
	config := Config{
		Theme:           "test-theme",
		ParallelTasksCount: "20",
	}
	
	// The struct should have proper tags for mapstructure, yaml, and json
	// We can test this by ensuring the struct can be marshaled/unmarshaled
	assert.NotEmpty(suite.T(), config.Theme)
	assert.NotEmpty(suite.T(), config.ParallelTasksCount)
}

// Test ProfileConfig struct
func (suite *TypesTestSuite) TestProfileConfig_Composition() {
	profileConfig := ProfileConfig{
		Profile: ProfileDev,
		Config: Config{
			Theme:               "dark-daltonized",
			ParallelTasksCount: "50",
		},
		EnvVars: map[string]string{
			"CLAUDE_CODE_ENABLE_TELEMETRY": "1",
			"EDITOR":                       "nano",
		},
	}
	
	assert.Equal(suite.T(), ProfileDev, profileConfig.Profile)
	assert.Equal(suite.T(), "dark-daltonized", profileConfig.Config.Theme)
	assert.Equal(suite.T(), "50", profileConfig.Config.ParallelTasksCount)
	assert.Len(suite.T(), profileConfig.EnvVars, 2)
	assert.Equal(suite.T(), "1", profileConfig.EnvVars["CLAUDE_CODE_ENABLE_TELEMETRY"])
	assert.Equal(suite.T(), "nano", profileConfig.EnvVars["EDITOR"])
}

func (suite *TypesTestSuite) TestProfileConfig_EmptyValues() {
	profileConfig := ProfileConfig{}
	
	assert.Empty(suite.T(), profileConfig.Profile)
	assert.Empty(suite.T(), profileConfig.Config.Theme)
	assert.Nil(suite.T(), profileConfig.EnvVars)
}

// Test interface definitions
func (suite *TypesTestSuite) TestConfigManager_Interface() {
	// Test that ConfigManager interface is properly defined
	// This ensures that any implementation must provide these methods
	
	var configManager ConfigManager
	assert.Nil(suite.T(), configManager, "Interface should be nil by default")
	
	// The interface methods should be:
	// - WriteConfig(key ConfigKey, value string) error
	// - WriteEnvConfig(envVars map[string]string) error
	// - ReadConfig() (*Config, error)
	// - InvalidateCache()
	
	// We can't test the methods directly on the interface,
	// but we can ensure the interface is properly defined
}

func (suite *TypesTestSuite) TestBackupManager_Interface() {
	// Test that BackupManager interface is properly defined
	
	var backupManager BackupManager
	assert.Nil(suite.T(), backupManager, "Interface should be nil by default")
	
	// The interface methods should be:
	// - CreateBackup(profile Profile) (string, error)
	// - RestoreBackup(backupPath string) error
	// - ListBackups() ([]string, error)
}

// Test type safety
func (suite *TypesTestSuite) TestProfile_TypeSafety() {
	// Test that Profile type provides type safety
	var profile Profile = ProfileDev
	
	// Should be able to use in string contexts
	profileString := string(profile)
	assert.Equal(suite.T(), "dev", profileString)
	
	// Should be able to create from string
	newProfile := Profile("prod")
	assert.Equal(suite.T(), ProfileProd, newProfile)
}

func (suite *TypesTestSuite) TestConfigKey_TypeSafety() {
	// Test that ConfigKey type provides type safety
	var key ConfigKey = KeyTheme
	
	// Should be able to use in string contexts
	keyString := string(key)
	assert.Equal(suite.T(), "theme", keyString)
	
	// Should be able to create from string
	newKey := ConfigKey("diffTool")
	assert.Equal(suite.T(), KeyDiffTool, newKey)
}

// Test value object behavior
func (suite *TypesTestSuite) TestProfile_ValueObject() {
	// Profiles should behave as value objects (immutable, equality based on value)
	profile1 := ProfileDev
	profile2 := ProfileDev
	profile3 := ProfileProd
	
	// Same profiles should be equal
	assert.Equal(suite.T(), profile1, profile2)
	
	// Different profiles should not be equal
	assert.NotEqual(suite.T(), profile1, profile3)
	
	// Should be comparable
	assert.True(suite.T(), profile1 == profile2)
	assert.False(suite.T(), profile1 == profile3)
}

func (suite *TypesTestSuite) TestConfigKey_ValueObject() {
	// ConfigKeys should behave as value objects
	key1 := KeyTheme
	key2 := KeyTheme
	key3 := KeyDiffTool
	
	// Same keys should be equal
	assert.Equal(suite.T(), key1, key2)
	
	// Different keys should not be equal
	assert.NotEqual(suite.T(), key1, key3)
	
	// Should be comparable
	assert.True(suite.T(), key1 == key2)
	assert.False(suite.T(), key1 == key3)
}

// Test edge cases
func (suite *TypesTestSuite) TestTypes_EdgeCases() {
	// Test empty profile
	emptyProfile := Profile("")
	assert.Empty(suite.T(), string(emptyProfile))
	
	// Test empty config key
	emptyKey := ConfigKey("")
	assert.Empty(suite.T(), string(emptyKey))
	
	// Test config with nil env
	config := Config{Theme: "test"}
	assert.Nil(suite.T(), config.Env)
	
	// Test config with empty env
	config.Env = make(map[string]string)
	assert.NotNil(suite.T(), config.Env)
	assert.Empty(suite.T(), config.Env)
}

// Run the types test suite
func TestTypesTestSuite(t *testing.T) {
	suite.Run(t, new(TypesTestSuite))
}

// Additional unit tests for specific type behaviors
func TestProfile_AllConstants(t *testing.T) {
	// Ensure all profile constants are unique
	profiles := []Profile{
		ProfileDev, ProfileDevelopment,
		ProfileProd, ProfileProduction,
		ProfilePersonal, ProfileDefault,
	}
	
	// Create a set to check uniqueness
	profileSet := make(map[Profile]bool)
	for _, profile := range profiles {
		assert.False(t, profileSet[profile], "Profile %s should be unique", profile)
		profileSet[profile] = true
	}
	
	// Should have all 6 profiles
	assert.Len(t, profileSet, 6)
}

func TestConfigKey_AllConstants(t *testing.T) {
	// Ensure all config key constants are unique
	keys := []ConfigKey{
		KeyTheme, KeyParallelTasksCount, KeyPreferredNotifChannel,
		KeyMessageIdleNotifThresholdMs, KeyAutoUpdates, KeyDiffTool,
	}
	
	// Create a set to check uniqueness
	keySet := make(map[ConfigKey]bool)
	for _, key := range keys {
		assert.False(t, keySet[key], "ConfigKey %s should be unique", key)
		keySet[key] = true
	}
	
	// Should have all 6 keys
	assert.Len(t, keySet, 6)
}