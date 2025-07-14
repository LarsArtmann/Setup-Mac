package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// ValueObjectsTestSuite contains tests for value objects and domain invariants
type ValueObjectsTestSuite struct {
	suite.Suite
}

// Test Profile value object
func (suite *ValueObjectsTestSuite) TestProfile_Constants() {
	// Test that all profile constants are defined correctly
	assert.Equal(suite.T(), Profile("dev"), ProfileDev)
	assert.Equal(suite.T(), Profile("development"), ProfileDevelopment)
	assert.Equal(suite.T(), Profile("prod"), ProfileProd)
	assert.Equal(suite.T(), Profile("production"), ProfileProduction)
	assert.Equal(suite.T(), Profile("personal"), ProfilePersonal)
	assert.Equal(suite.T(), Profile("default"), ProfileDefault)
}

func (suite *ValueObjectsTestSuite) TestProfile_StringConversion() {
	profile := ProfileDev
	assert.Equal(suite.T(), "dev", string(profile))
}

func (suite *ValueObjectsTestSuite) TestProfile_Equality() {
	profile1 := ProfileDev
	profile2 := ProfileDev
	profile3 := ProfileProd
	
	assert.Equal(suite.T(), profile1, profile2)
	assert.NotEqual(suite.T(), profile1, profile3)
}

// Test ConfigKey value object
func (suite *ValueObjectsTestSuite) TestConfigKey_Constants() {
	// Test that all config key constants are defined correctly
	assert.Equal(suite.T(), ConfigKey("theme"), KeyTheme)
	assert.Equal(suite.T(), ConfigKey("parallelTasksCount"), KeyParallelTasksCount)
	assert.Equal(suite.T(), ConfigKey("preferredNotifChannel"), KeyPreferredNotifChannel)
	assert.Equal(suite.T(), ConfigKey("messageIdleNotifThresholdMs"), KeyMessageIdleNotifThresholdMs)
	assert.Equal(suite.T(), ConfigKey("autoUpdates"), KeyAutoUpdates)
	assert.Equal(suite.T(), ConfigKey("diffTool"), KeyDiffTool)
}

func (suite *ValueObjectsTestSuite) TestConfigKey_StringConversion() {
	key := KeyTheme
	assert.Equal(suite.T(), "theme", string(key))
}

func (suite *ValueObjectsTestSuite) TestConfigKey_Equality() {
	key1 := KeyTheme
	key2 := KeyTheme
	key3 := KeyDiffTool
	
	assert.Equal(suite.T(), key1, key2)
	assert.NotEqual(suite.T(), key1, key3)
}

// Test Config struct invariants
func (suite *ValueObjectsTestSuite) TestConfig_DefaultConstruction() {
	config := Config{}
	
	// Default config should have nil Env map
	assert.Nil(suite.T(), config.Env)
	
	// All string fields should be empty by default
	assert.Empty(suite.T(), config.Theme)
	assert.Empty(suite.T(), config.ParallelTasksCount)
	assert.Empty(suite.T(), config.PreferredNotifChannel)
	assert.Empty(suite.T(), config.MessageIdleNotifThresholdMs)
	assert.Empty(suite.T(), config.AutoUpdates)
	assert.Empty(suite.T(), config.DiffTool)
}

func (suite *ValueObjectsTestSuite) TestConfig_WithEnvironmentVariables() {
	config := Config{
		Env: map[string]string{
			"VAR1": "value1",
			"VAR2": "value2",
		},
	}
	
	assert.NotNil(suite.T(), config.Env)
	assert.Len(suite.T(), config.Env, 2)
	assert.Equal(suite.T(), "value1", config.Env["VAR1"])
	assert.Equal(suite.T(), "value2", config.Env["VAR2"])
}

func (suite *ValueObjectsTestSuite) TestConfig_ImmutabilityPrinciple() {
	// Test that we can create configs with different values
	config1 := Config{Theme: "dark"}
	config2 := Config{Theme: "light"}
	
	assert.NotEqual(suite.T(), config1.Theme, config2.Theme)
	
	// Original configs remain unchanged
	assert.Equal(suite.T(), "dark", config1.Theme)
	assert.Equal(suite.T(), "light", config2.Theme)
}

// Test ProfileConfig composition
func (suite *ValueObjectsTestSuite) TestProfileConfig_Composition() {
	profileConfig := ProfileConfig{
		Profile: ProfileDev,
		Config: Config{
			Theme: "dark-daltonized",
		},
		EnvVars: map[string]string{
			"EDITOR": "nano",
		},
	}
	
	assert.Equal(suite.T(), ProfileDev, profileConfig.Profile)
	assert.Equal(suite.T(), "dark-daltonized", profileConfig.Config.Theme)
	assert.Equal(suite.T(), "nano", profileConfig.EnvVars["EDITOR"])
}

func (suite *ValueObjectsTestSuite) TestProfileConfig_EnvVarsNotNil() {
	profileConfig := ProfileConfig{
		Profile: ProfileDev,
		Config:  Config{},
		EnvVars: make(map[string]string),
	}
	
	assert.NotNil(suite.T(), profileConfig.EnvVars)
	assert.Empty(suite.T(), profileConfig.EnvVars)
}

// Test ApplicationOptions value object
func (suite *ValueObjectsTestSuite) TestApplicationOptions_DefaultValues() {
	options := ApplicationOptions{}
	
	// Test default values
	assert.False(suite.T(), options.DryRun)
	assert.False(suite.T(), options.CreateBackup)
	assert.Empty(suite.T(), options.Profile)
	assert.False(suite.T(), options.Help)
	assert.Nil(suite.T(), options.ForwardArgs)
}

func (suite *ValueObjectsTestSuite) TestApplicationOptions_WithValues() {
	options := ApplicationOptions{
		DryRun:       true,
		CreateBackup: true,
		Profile:      ProfileDev,
		Help:         false,
		ForwardArgs:  []string{"chat", "--verbose"},
	}
	
	assert.True(suite.T(), options.DryRun)
	assert.True(suite.T(), options.CreateBackup)
	assert.Equal(suite.T(), ProfileDev, options.Profile)
	assert.False(suite.T(), options.Help)
	assert.Len(suite.T(), options.ForwardArgs, 2)
	assert.Equal(suite.T(), "chat", options.ForwardArgs[0])
	assert.Equal(suite.T(), "--verbose", options.ForwardArgs[1])
}

// Test ValidationError value object
func (suite *ValueObjectsTestSuite) TestValidationError_Error() {
	err := ValidationError{
		Field:   "testField",
		Value:   "testValue",
		Message: "test message",
	}
	
	errorMsg := err.Error()
	assert.Contains(suite.T(), errorMsg, "testField")
	assert.Contains(suite.T(), errorMsg, "testValue")
	assert.Contains(suite.T(), errorMsg, "test message")
	assert.Contains(suite.T(), errorMsg, "validation failed")
}

func (suite *ValueObjectsTestSuite) TestValidationError_WithNilValue() {
	err := ValidationError{
		Field:   "testField",
		Value:   nil,
		Message: "test message",
	}
	
	errorMsg := err.Error()
	assert.Contains(suite.T(), errorMsg, "testField")
	assert.Contains(suite.T(), errorMsg, "<nil>")
	assert.Contains(suite.T(), errorMsg, "test message")
}

func (suite *ValueObjectsTestSuite) TestValidationError_WithComplexValue() {
	complexValue := map[string]interface{}{
		"key1": "value1",
		"key2": 42,
	}
	
	err := ValidationError{
		Field:   "complexField",
		Value:   complexValue,
		Message: "complex validation error",
	}
	
	errorMsg := err.Error()
	assert.Contains(suite.T(), errorMsg, "complexField")
	assert.Contains(suite.T(), errorMsg, "complex validation error")
}

// Test ValidationErrors collection
func (suite *ValueObjectsTestSuite) TestValidationErrors_Empty() {
	errors := ValidationErrors{}
	
	assert.False(suite.T(), errors.HasErrors())
	assert.Empty(suite.T(), errors.Error())
}

func (suite *ValueObjectsTestSuite) TestValidationErrors_Single() {
	errors := ValidationErrors{
		ValidationError{Field: "field1", Value: "value1", Message: "error1"},
	}
	
	assert.True(suite.T(), errors.HasErrors())
	assert.Contains(suite.T(), errors.Error(), "field1")
	assert.Contains(suite.T(), errors.Error(), "error1")
}

func (suite *ValueObjectsTestSuite) TestValidationErrors_Multiple() {
	errors := ValidationErrors{
		ValidationError{Field: "field1", Value: "value1", Message: "error1"},
		ValidationError{Field: "field2", Value: "value2", Message: "error2"},
		ValidationError{Field: "field3", Value: "value3", Message: "error3"},
	}
	
	assert.True(suite.T(), errors.HasErrors())
	
	errorMsg := errors.Error()
	assert.Contains(suite.T(), errorMsg, "field1")
	assert.Contains(suite.T(), errorMsg, "field2")
	assert.Contains(suite.T(), errorMsg, "field3")
	assert.Contains(suite.T(), errorMsg, "error1")
	assert.Contains(suite.T(), errorMsg, "error2")
	assert.Contains(suite.T(), errorMsg, "error3")
	
	// Should separate errors with semicolon
	assert.Contains(suite.T(), errorMsg, ";")
}

// Test domain invariants
func (suite *ValueObjectsTestSuite) TestDomainInvariant_ProfileValidation() {
	// Profile should always be one of the predefined constants
	validProfiles := []Profile{
		ProfileDev, ProfileDevelopment,
		ProfileProd, ProfileProduction,
		ProfilePersonal, ProfileDefault,
	}
	
	for _, profile := range validProfiles {
		errors := profile.Validate()
		assert.False(suite.T(), errors.HasErrors(), "Profile %s should be valid", profile)
	}
}

func (suite *ValueObjectsTestSuite) TestDomainInvariant_ConfigValidation() {
	// Valid config should pass all validation rules
	config := NewConfigBuilder().
		WithTheme("dark-daltonized").
		WithParallelTasksCount("20").
		WithNotificationChannel("iterm2_with_bell").
		WithMessageIdleThreshold("1000").
		WithAutoUpdates("false").
		WithDiffTool("bat").
		WithEnvVar("VALID_VAR", "value").
		Build()
	
	errors := config.Validate()
	assert.False(suite.T(), errors.HasErrors(), "Valid config should pass validation")
}

func (suite *ValueObjectsTestSuite) TestDomainInvariant_EnvironmentVariableSafety() {
	// System environment variables should never be allowed
	systemVars := []string{"PATH", "HOME", "USER", "SHELL"}
	
	for _, sysVar := range systemVars {
		config := NewConfigBuilder().WithEnvVar(sysVar, "dangerous_value").Build()
		errors := config.Validate()
		
		assert.True(suite.T(), errors.HasErrors(), "System variable %s should not be allowed", sysVar)
		assert.Contains(suite.T(), errors.Error(), "not allowed")
	}
}

func (suite *ValueObjectsTestSuite) TestDomainInvariant_NumericRanges() {
	// Test parallel tasks count range invariant
	testCases := []struct {
		value     string
		shouldErr bool
	}{
		{"0", true},     // Below minimum
		{"1", false},    // Minimum valid
		{"500", false},  // Valid middle
		{"1000", false}, // Maximum valid
		{"1001", true},  // Above maximum
	}
	
	for _, tc := range testCases {
		config := NewConfigBuilder().WithParallelTasksCount(tc.value).Build()
		errors := config.Validate()
		
		if tc.shouldErr {
			assert.True(suite.T(), errors.HasErrors(), "Value %s should be invalid", tc.value)
		} else {
			// Focus only on parallel tasks count validation
			hasParallelTasksError := false
			for _, err := range errors {
				if err.Field == "parallelTasksCount" {
					hasParallelTasksError = true
					break
				}
			}
			assert.False(suite.T(), hasParallelTasksError, "Value %s should be valid for parallel tasks count", tc.value)
		}
	}
}

func (suite *ValueObjectsTestSuite) TestDomainInvariant_TimeThresholdRanges() {
	// Test message idle threshold range invariant
	testCases := []struct {
		value     string
		shouldErr bool
	}{
		{"-1", true},    // Below minimum
		{"0", false},    // Minimum valid
		{"30000", false}, // Valid middle
		{"60000", false}, // Maximum valid
		{"60001", true},  // Above maximum
	}
	
	for _, tc := range testCases {
		config := NewConfigBuilder().WithMessageIdleThreshold(tc.value).Build()
		errors := config.Validate()
		
		if tc.shouldErr {
			assert.True(suite.T(), errors.HasErrors(), "Value %s should be invalid", tc.value)
		} else {
			// Focus only on message idle threshold validation
			hasThresholdError := false
			for _, err := range errors {
				if err.Field == "messageIdleNotifThresholdMs" {
					hasThresholdError = true
					break
				}
			}
			assert.False(suite.T(), hasThresholdError, "Value %s should be valid for message idle threshold", tc.value)
		}
	}
}

func (suite *ValueObjectsTestSuite) TestDomainInvariant_EnumValues() {
	// Test that only predefined enum values are accepted
	
	// Valid notification channels
	for _, channel := range ValidNotificationChannels {
		config := NewConfigBuilder().WithNotificationChannel(channel).Build()
		errors := config.Validate()
		
		// Check specifically for notification channel errors
		hasChannelError := false
		for _, err := range errors {
			if err.Field == "preferredNotifChannel" {
				hasChannelError = true
				break
			}
		}
		assert.False(suite.T(), hasChannelError, "Valid channel %s should pass validation", channel)
	}
	
	// Valid diff tools
	for _, tool := range ValidDiffTools {
		config := NewConfigBuilder().WithDiffTool(tool).Build()
		errors := config.Validate()
		
		// Check specifically for diff tool errors
		hasToolError := false
		for _, err := range errors {
			if err.Field == "diffTool" {
				hasToolError = true
				break
			}
		}
		assert.False(suite.T(), hasToolError, "Valid tool %s should pass validation", tool)
	}
}

// Run the value objects test suite
func TestValueObjectsTestSuite(t *testing.T) {
	suite.Run(t, new(ValueObjectsTestSuite))
}