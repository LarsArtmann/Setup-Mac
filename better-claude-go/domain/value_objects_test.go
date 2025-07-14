package domain

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// ValueObjectsTestSuite contains tests for domain value objects
type ValueObjectsTestSuite struct {
	suite.Suite
}

// Profile Value Object Tests
func (suite *ValueObjectsTestSuite) TestProfile_NewProfile_ValidValues() {
	validProfiles := []string{
		"dev", "development", 
		"prod", "production", 
		"personal", "default",
		"DEV", "DEVELOPMENT", // Test case normalization
		"  prod  ", // Test whitespace trimming
	}

	for _, profileValue := range validProfiles {
		profile, err := NewProfile(profileValue)
		
		assert.NoError(suite.T(), err, "Profile '%s' should be valid", profileValue)
		assert.NotNil(suite.T(), profile)
		assert.NotEmpty(suite.T(), profile.Value())
	}
}

func (suite *ValueObjectsTestSuite) TestProfile_NewProfile_InvalidValues() {
	invalidProfiles := []string{
		"invalid", "test", "staging", "local", "", " ", "dev-test",
	}

	for _, profileValue := range invalidProfiles {
		profile, err := NewProfile(profileValue)
		
		assert.Error(suite.T(), err, "Profile '%s' should be invalid", profileValue)
		assert.Nil(suite.T(), profile)
		assert.Contains(suite.T(), err.Error(), "invalid profile")
	}
}

func (suite *ValueObjectsTestSuite) TestProfile_Normalization() {
	testCases := []struct {
		input    string
		expected string
	}{
		{"DEV", "dev"},
		{"Development", "development"},
		{"  PROD  ", "prod"},
		{"Production", "production"},
		{" Personal ", "personal"},
		{"DEFAULT", "default"},
	}

	for _, tc := range testCases {
		profile, err := NewProfile(tc.input)
		
		assert.NoError(suite.T(), err)
		assert.Equal(suite.T(), tc.expected, profile.Value())
	}
}

func (suite *ValueObjectsTestSuite) TestProfile_Equality() {
	profile1, _ := NewProfile("dev")
	profile2, _ := NewProfile("dev")
	profile3, _ := NewProfile("prod")

	assert.True(suite.T(), profile1.IsEqual(*profile2))
	assert.False(suite.T(), profile1.IsEqual(*profile3))
}

func (suite *ValueObjectsTestSuite) TestProfile_TypeCheckers() {
	testCases := []struct {
		profileValue string
		isDev        bool
		isProd       bool
		isPersonal   bool
	}{
		{"dev", true, false, false},
		{"development", true, false, false},
		{"prod", false, true, false},
		{"production", false, true, false},
		{"personal", false, false, true},
		{"default", false, false, true},
	}

	for _, tc := range testCases {
		profile, _ := NewProfile(tc.profileValue)
		
		assert.Equal(suite.T(), tc.isDev, profile.IsDevelopment(), "Profile %s development check", tc.profileValue)
		assert.Equal(suite.T(), tc.isProd, profile.IsProduction(), "Profile %s production check", tc.profileValue)
		assert.Equal(suite.T(), tc.isPersonal, profile.IsPersonal(), "Profile %s personal check", tc.profileValue)
	}
}

func (suite *ValueObjectsTestSuite) TestProfile_StringRepresentation() {
	profile, _ := NewProfile("dev")
	
	assert.Equal(suite.T(), "dev", profile.String())
	assert.Equal(suite.T(), "dev", profile.Value())
}

func (suite *ValueObjectsTestSuite) TestProfile_Constants() {
	// Test that predefined constants work correctly
	assert.Equal(suite.T(), "dev", ProfileDev.Value())
	assert.Equal(suite.T(), "development", ProfileDevelopment.Value())
	assert.Equal(suite.T(), "prod", ProfileProd.Value())
	assert.Equal(suite.T(), "production", ProfileProduction.Value())
	assert.Equal(suite.T(), "personal", ProfilePersonal.Value())
	assert.Equal(suite.T(), "default", ProfileDefault.Value())
}

// ConfigKey Value Object Tests
func (suite *ValueObjectsTestSuite) TestConfigKey_NewConfigKey_ValidValues() {
	validKeys := []string{
		"theme", "parallelTasksCount", "autoUpdates",
		"test_key", "TEST_KEY", "key123", "key_with_underscores",
	}

	for _, keyValue := range validKeys {
		key, err := NewConfigKey(keyValue)
		
		assert.NoError(suite.T(), err, "ConfigKey '%s' should be valid", keyValue)
		assert.NotNil(suite.T(), key)
		assert.NotEmpty(suite.T(), key.Value())
	}
}

func (suite *ValueObjectsTestSuite) TestConfigKey_NewConfigKey_InvalidValues() {
	invalidKeys := []string{
		"", " ", "key with spaces", "key-with-dashes", 
		"key.with.dots", "key@with@symbols", "key/with/slashes",
		"key with\ttabs", "key\nwith\nnewlines",
	}

	for _, keyValue := range invalidKeys {
		key, err := NewConfigKey(keyValue)
		
		assert.Error(suite.T(), err, "ConfigKey '%s' should be invalid", keyValue)
		assert.Nil(suite.T(), key)
	}
}

func (suite *ValueObjectsTestSuite) TestConfigKey_Trimming() {
	key, err := NewConfigKey("  validKey  ")
	
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), "validKey", key.Value())
}

func (suite *ValueObjectsTestSuite) TestConfigKey_Equality() {
	key1, _ := NewConfigKey("theme")
	key2, _ := NewConfigKey("theme")
	key3, _ := NewConfigKey("parallelTasksCount")

	assert.True(suite.T(), key1.IsEqual(*key2))
	assert.False(suite.T(), key1.IsEqual(*key3))
}

func (suite *ValueObjectsTestSuite) TestConfigKey_StringRepresentation() {
	key, _ := NewConfigKey("theme")
	
	assert.Equal(suite.T(), "theme", key.String())
	assert.Equal(suite.T(), "theme", key.Value())
}

func (suite *ValueObjectsTestSuite) TestConfigKey_Constants() {
	// Test that predefined constants work correctly
	assert.Equal(suite.T(), "theme", ConfigKeyTheme.Value())
	assert.Equal(suite.T(), "parallelTasksCount", ConfigKeyParallelTasksCount.Value())
	assert.Equal(suite.T(), "preferredNotifChannel", ConfigKeyPreferredNotifChannel.Value())
	assert.Equal(suite.T(), "messageIdleNotifThresholdMs", ConfigKeyMessageIdleNotifThresholdMs.Value())
	assert.Equal(suite.T(), "autoUpdates", ConfigKeyAutoUpdates.Value())
	assert.Equal(suite.T(), "diffTool", ConfigKeyDiffTool.Value())
}

// ConfigValue Value Object Tests
func (suite *ValueObjectsTestSuite) TestConfigValue_NewConfigValue_Success() {
	testValues := []string{
		"", "simple_value", "value with spaces", "123", 
		"true", "false", "complex-value-123", "🎨",
	}

	for _, value := range testValues {
		configValue, err := NewConfigValue(value)
		
		assert.NoError(suite.T(), err, "ConfigValue should accept any string value")
		assert.NotNil(suite.T(), configValue)
		assert.Equal(suite.T(), value, configValue.Value())
	}
}

func (suite *ValueObjectsTestSuite) TestConfigValue_IsEmpty() {
	testCases := []struct {
		value    string
		isEmpty  bool
	}{
		{"", true},
		{" ", true},
		{"  \t\n  ", true},
		{"value", false},
		{" value ", false},
		{"0", false},
		{"false", false},
	}

	for _, tc := range testCases {
		configValue, _ := NewConfigValue(tc.value)
		
		assert.Equal(suite.T(), tc.isEmpty, configValue.IsEmpty(), "Value '%s' empty check", tc.value)
	}
}

func (suite *ValueObjectsTestSuite) TestConfigValue_Equality() {
	value1, _ := NewConfigValue("test")
	value2, _ := NewConfigValue("test")
	value3, _ := NewConfigValue("different")

	assert.True(suite.T(), value1.IsEqual(*value2))
	assert.False(suite.T(), value1.IsEqual(*value3))
}

func (suite *ValueObjectsTestSuite) TestConfigValue_StringRepresentation() {
	value, _ := NewConfigValue("test_value")
	
	assert.Equal(suite.T(), "test_value", value.String())
	assert.Equal(suite.T(), "test_value", value.Value())
}

// Value Object Immutability Tests
func (suite *ValueObjectsTestSuite) TestValueObjects_Immutability() {
	// Profile immutability
	profile, _ := NewProfile("dev")
	originalValue := profile.Value()
	
	// Cannot modify the value from outside (it's private)
	// This test ensures the structure supports immutability
	assert.Equal(suite.T(), originalValue, profile.Value())

	// ConfigKey immutability
	key, _ := NewConfigKey("theme")
	originalKeyValue := key.Value()
	assert.Equal(suite.T(), originalKeyValue, key.Value())

	// ConfigValue immutability
	value, _ := NewConfigValue("test")
	originalConfigValue := value.Value()
	assert.Equal(suite.T(), originalConfigValue, value.Value())
}

// Edge Cases and Error Conditions
func (suite *ValueObjectsTestSuite) TestProfile_EdgeCases() {
	// Unicode characters
	_, err := NewProfile("dév")
	assert.Error(suite.T(), err)

	// Very long string
	longProfile := "dev" + string(make([]byte, 1000))
	_, err = NewProfile(longProfile)
	assert.Error(suite.T(), err)
}

func (suite *ValueObjectsTestSuite) TestConfigKey_EdgeCases() {
	// Single character
	key, err := NewConfigKey("a")
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), "a", key.Value())

	// Numbers only
	key, err = NewConfigKey("123")
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), "123", key.Value())

	// Mixed case
	key, err = NewConfigKey("MyKey")
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), "MyKey", key.Value())

	// Very long valid key
	longKey := string(make([]byte, 100))
	for i := range longKey {
		longKey = longKey[:i] + "a" + longKey[i+1:]
	}
	key, err = NewConfigKey(longKey)
	assert.NoError(suite.T(), err)
}

func (suite *ValueObjectsTestSuite) TestConfigValue_EdgeCases() {
	// Very long value
	longValue := string(make([]byte, 10000))
	for i := range longValue {
		longValue = longValue[:i] + "x" + longValue[i+1:]
	}
	value, err := NewConfigValue(longValue)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), longValue, value.Value())

	// Special characters
	specialValue := "!@#$%^&*()[]{}|;:'\",.<>?/~`"
	value, err = NewConfigValue(specialValue)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), specialValue, value.Value())

	// Unicode
	unicodeValue := "🎨🚀✨"
	value, err = NewConfigValue(unicodeValue)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), unicodeValue, value.Value())
}

// Type Safety Tests
func (suite *ValueObjectsTestSuite) TestValueObjects_TypeSafety() {
	// Ensure value objects prevent type confusion
	profile, _ := NewProfile("dev")
	key, _ := NewConfigKey("theme")
	value, _ := NewConfigValue("dark")

	// These should be different types and not accidentally compared
	assert.IsType(suite.T(), Profile{}, *profile)
	assert.IsType(suite.T(), ConfigKey{}, *key)
	assert.IsType(suite.T(), ConfigValue{}, *value)
}

// Factory Function Tests
func (suite *ValueObjectsTestSuite) TestMustCreateConfigKey_Success() {
	// Test that mustCreateConfigKey works for predefined constants
	assert.NotPanics(suite.T(), func() {
		key := mustCreateConfigKey("validKey")
		assert.Equal(suite.T(), "validKey", key.Value())
	})
}

func (suite *ValueObjectsTestSuite) TestMustCreateConfigKey_Panic() {
	// Test that mustCreateConfigKey panics for invalid keys
	assert.Panics(suite.T(), func() {
		mustCreateConfigKey("invalid key with spaces")
	})
}

func (suite *ValueObjectsTestSuite) TestMustCreateProfile_Success() {
	// Test that mustCreateProfile works for predefined constants
	assert.NotPanics(suite.T(), func() {
		profile := mustCreateProfile("dev")
		assert.Equal(suite.T(), "dev", profile.Value())
	})
}

func (suite *ValueObjectsTestSuite) TestMustCreateProfile_Panic() {
	// Test that mustCreateProfile panics for invalid profiles
	assert.Panics(suite.T(), func() {
		mustCreateProfile("invalid_profile")
	})
}

// Value Object Collections Tests
func (suite *ValueObjectsTestSuite) TestPredefinedProfiles_Uniqueness() {
	profiles := []Profile{
		ProfileDev, ProfileDevelopment, ProfileProd, 
		ProfileProduction, ProfilePersonal, ProfileDefault,
	}

	// Check that all profiles are unique
	seen := make(map[string]bool)
	for _, profile := range profiles {
		assert.False(suite.T(), seen[profile.Value()], "Profile %s should be unique", profile.Value())
		seen[profile.Value()] = true
	}

	assert.Equal(suite.T(), 6, len(seen), "Should have 6 unique profiles")
}

func (suite *ValueObjectsTestSuite) TestPredefinedConfigKeys_Uniqueness() {
	keys := []ConfigKey{
		ConfigKeyTheme, ConfigKeyParallelTasksCount, ConfigKeyPreferredNotifChannel,
		ConfigKeyMessageIdleNotifThresholdMs, ConfigKeyAutoUpdates, ConfigKeyDiffTool,
	}

	// Check that all keys are unique
	seen := make(map[string]bool)
	for _, key := range keys {
		assert.False(suite.T(), seen[key.Value()], "ConfigKey %s should be unique", key.Value())
		seen[key.Value()] = true
	}

	assert.Equal(suite.T(), 6, len(seen), "Should have 6 unique config keys")
}

// Performance Tests (basic)
func (suite *ValueObjectsTestSuite) TestValueObjects_Performance() {
	// Test that value object creation is reasonably fast
	// (This is a basic test; more sophisticated benchmarks could be added)
	
	for i := 0; i < 1000; i++ {
		_, err := NewProfile("dev")
		assert.NoError(suite.T(), err)
		
		_, err = NewConfigKey("testKey")
		assert.NoError(suite.T(), err)
		
		_, err = NewConfigValue("testValue")
		assert.NoError(suite.T(), err)
	}
}

// Run the value objects test suite
func TestValueObjectsTestSuite(t *testing.T) {
	suite.Run(t, new(ValueObjectsTestSuite))
}