package domain

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// ConfigurationAggregateTestSuite contains tests for Configuration aggregate
type ConfigurationAggregateTestSuite struct {
	suite.Suite
	testProfile Profile
	testValue   ConfigValue
	testKey     ConfigKey
}

func (suite *ConfigurationAggregateTestSuite) SetupTest() {
	// Setup test data using proper constructors
	profile, err := NewProfile("dev")
	suite.Require().NoError(err)
	suite.testProfile = *profile

	value, err := NewConfigValue("test-value")
	suite.Require().NoError(err)
	suite.testValue = *value

	key, err := NewConfigKey("testKey")
	suite.Require().NoError(err)
	suite.testKey = *key
}

// Test Configuration aggregate creation
func (suite *ConfigurationAggregateTestSuite) TestNewConfiguration_Success() {
	config, err := NewConfiguration(suite.testProfile, "testUser")

	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), config)
	assert.NotEmpty(suite.T(), config.ID())
	assert.Equal(suite.T(), 1, config.Version())
	assert.True(suite.T(), config.Profile().IsEqual(suite.testProfile))
	assert.NotEmpty(suite.T(), config.Settings())
	assert.NotNil(suite.T(), config.EnvVariables())
	assert.Len(suite.T(), config.UncommittedEvents(), 1)
}

func (suite *ConfigurationAggregateTestSuite) TestNewConfiguration_EmptyProfile() {
	emptyProfile := Profile{value: ""}
	
	config, err := NewConfiguration(emptyProfile, "testUser")

	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), config)
	assert.Contains(suite.T(), err.Error(), "profile cannot be empty")
}

// Test configuration changes
func (suite *ConfigurationAggregateTestSuite) TestChangeConfiguration_Success() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Clear uncommitted events to focus on the change
	config.MarkEventsAsCommitted()

	// Change a setting
	newValue, _ := NewConfigValue("dark")
	err = config.ChangeConfiguration(ConfigKeyTheme, *newValue, "testUser")

	assert.NoError(suite.T(), err)
	assert.Len(suite.T(), config.UncommittedEvents(), 1)
	
	// Verify the setting was changed
	setting, exists := config.GetSetting(ConfigKeyTheme)
	assert.True(suite.T(), exists)
	assert.True(suite.T(), setting.IsEqual(*newValue))
}

func (suite *ConfigurationAggregateTestSuite) TestChangeConfiguration_InvalidValue() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Try to set invalid theme
	invalidValue, _ := NewConfigValue("invalid-theme")
	err = config.ChangeConfiguration(ConfigKeyTheme, *invalidValue, "testUser")

	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "invalid theme")
}

func (suite *ConfigurationAggregateTestSuite) TestChangeConfiguration_ValidationFailing() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Force validation to fail by setting invalid status
	config.validationStatus.IsValid = false
	config.validationStatus.Errors = []string{"test error"}

	newValue, _ := NewConfigValue("dark")
	err = config.ChangeConfiguration(ConfigKeyTheme, *newValue, "testUser")

	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "cannot change configuration while validation is failing")
}

func (suite *ConfigurationAggregateTestSuite) TestChangeConfiguration_NoChange() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Get current value
	currentValue, exists := config.GetSetting(ConfigKeyTheme)
	suite.Require().True(exists)

	// Clear events
	config.MarkEventsAsCommitted()

	// Try to set the same value
	err = config.ChangeConfiguration(ConfigKeyTheme, currentValue, "testUser")

	assert.NoError(suite.T(), err)
	assert.Len(suite.T(), config.UncommittedEvents(), 0) // No event should be raised
}

// Test profile switching
func (suite *ConfigurationAggregateTestSuite) TestSwitchProfile_Success() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Switch to production profile
	prodProfile, _ := NewProfile("prod")
	config.MarkEventsAsCommitted()

	err = config.SwitchProfile(*prodProfile, "testUser")

	assert.NoError(suite.T(), err)
	assert.True(suite.T(), config.Profile().IsEqual(*prodProfile))
	assert.Len(suite.T(), config.UncommittedEvents(), 1)
}

func (suite *ConfigurationAggregateTestSuite) TestSwitchProfile_SameProfile() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	err = config.SwitchProfile(suite.testProfile, "testUser")

	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "already using profile")
}

// Test backup creation
func (suite *ConfigurationAggregateTestSuite) TestCreateBackup_Success() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	config.MarkEventsAsCommitted()
	backupPath := "/test/backup/path"

	err = config.CreateBackup(backupPath, "testUser")

	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), backupPath, config.GetLastBackupPath())
	assert.Len(suite.T(), config.UncommittedEvents(), 1)
}

func (suite *ConfigurationAggregateTestSuite) TestCreateBackup_EmptyPath() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	err = config.CreateBackup("", "testUser")

	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "backup path cannot be empty")
}

// Test validation
func (suite *ConfigurationAggregateTestSuite) TestValidateConfiguration_Success() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	config.MarkEventsAsCommitted()

	errors := config.ValidateConfiguration("testUser")

	assert.Empty(suite.T(), errors)
	assert.True(suite.T(), config.GetValidationStatus().IsValid)
	assert.Len(suite.T(), config.UncommittedEvents(), 1)
}

func (suite *ConfigurationAggregateTestSuite) TestValidateConfiguration_WithErrors() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Set an invalid theme to force validation error
	invalidValue, _ := NewConfigValue("")
	config.settings[ConfigKeyTheme] = *invalidValue

	errors := config.ValidateConfiguration("testUser")

	assert.NotEmpty(suite.T(), errors)
	assert.False(suite.T(), config.GetValidationStatus().IsValid)
	assert.Greater(suite.T(), config.GetValidationStatus().ErrorCount, 0)
}

// Test event sourcing
func (suite *ConfigurationAggregateTestSuite) TestLoadFromHistory_Success() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	originalID := config.ID()
	config.MarkEventsAsCommitted()

	// Create some events to replay
	newProfile, _ := NewProfile("prod")
	newValue, _ := NewConfigValue("light")
	
	events := []DomainEvent{
		NewConfigurationCreated(originalID, suite.testProfile, config.Settings(), "testUser", 1),
		NewConfigurationChanged(originalID, ConfigKeyTheme, *newValue, *newValue, "testUser", suite.testProfile, 2),
		NewProfileSwitched(originalID, suite.testProfile, *newProfile, "testUser", 1, 3),
	}

	// Create new aggregate and load from history
	newConfig := &Configuration{}
	err = newConfig.LoadFromHistory(events)

	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), originalID, newConfig.ID())
	assert.Equal(suite.T(), 3, newConfig.Version())
	assert.True(suite.T(), newConfig.Profile().IsEqual(*newProfile))
}

func (suite *ConfigurationAggregateTestSuite) TestLoadFromHistory_InvalidEvent() {
	config := &Configuration{}
	
	// Create an empty events slice to test error handling
	events := []DomainEvent{}

	err := config.LoadFromHistory(events)

	// Loading empty events should not error
	assert.NoError(suite.T(), err)
}

// Test aggregate root interface compliance
func (suite *ConfigurationAggregateTestSuite) TestAggregateRootInterface() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Test that Configuration implements AggregateRoot
	var aggregateRoot AggregateRoot = config

	assert.NotEmpty(suite.T(), aggregateRoot.ID())
	assert.Greater(suite.T(), aggregateRoot.Version(), 0)
	assert.NotEmpty(suite.T(), aggregateRoot.UncommittedEvents())

	aggregateRoot.MarkEventsAsCommitted()
	assert.Empty(suite.T(), aggregateRoot.UncommittedEvents())
}

// Test immutability of returned values
func (suite *ConfigurationAggregateTestSuite) TestImmutabilityOfReturnedValues() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Get settings map
	settings := config.Settings()
	originalSize := len(settings)

	// Try to modify the returned map
	newKey, _ := NewConfigKey("newKey")
	newValue, _ := NewConfigValue("newValue")
	settings[*newKey] = *newValue

	// Verify original config is unchanged
	newSettings := config.Settings()
	assert.Equal(suite.T(), originalSize, len(newSettings))
	_, exists := newSettings[*newKey]
	assert.False(suite.T(), exists)
}

func (suite *ConfigurationAggregateTestSuite) TestImmutabilityOfEnvVariables() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Get env variables map
	envVars := config.EnvVariables()
	originalSize := len(envVars)

	// Try to modify the returned map
	envVars["NEW_VAR"] = "new_value"

	// Verify original config is unchanged
	newEnvVars := config.EnvVariables()
	assert.Equal(suite.T(), originalSize, len(newEnvVars))
	_, exists := newEnvVars["NEW_VAR"]
	assert.False(suite.T(), exists)
}

// Test business rule validation
func (suite *ConfigurationAggregateTestSuite) TestBusinessRules_ParallelTasksCount() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Test empty value
	emptyValue, _ := NewConfigValue("")
	err = config.ChangeConfiguration(ConfigKeyParallelTasksCount, *emptyValue, "testUser")
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "parallel tasks count cannot be empty")
}

func (suite *ConfigurationAggregateTestSuite) TestBusinessRules_ThemeValidation() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	testCases := []struct {
		theme       string
		shouldError bool
	}{
		{"dark", false},
		{"light", false},
		{"dark-daltonized", false},
		{"auto", false},
		{"invalid-theme", true},
		{"", true},
	}

	for _, tc := range testCases {
		value, _ := NewConfigValue(tc.theme)
		err := config.ChangeConfiguration(ConfigKeyTheme, *value, "testUser")
		
		if tc.shouldError {
			assert.Error(suite.T(), err, "Theme '%s' should be invalid", tc.theme)
		} else {
			assert.NoError(suite.T(), err, "Theme '%s' should be valid", tc.theme)
		}
	}
}

func (suite *ConfigurationAggregateTestSuite) TestBusinessRules_AutoUpdates() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	// Test valid values
	trueValue, _ := NewConfigValue("true")
	err = config.ChangeConfiguration(ConfigKeyAutoUpdates, *trueValue, "testUser")
	assert.NoError(suite.T(), err)

	falseValue, _ := NewConfigValue("false")
	err = config.ChangeConfiguration(ConfigKeyAutoUpdates, *falseValue, "testUser")
	assert.NoError(suite.T(), err)

	// Test invalid value
	invalidValue, _ := NewConfigValue("maybe")
	err = config.ChangeConfiguration(ConfigKeyAutoUpdates, *invalidValue, "testUser")
	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "auto updates must be 'true' or 'false'")
}

// Test concurrency safety (aggregate should be used by single thread)
func (suite *ConfigurationAggregateTestSuite) TestVersionIncrement() {
	config, err := NewConfiguration(suite.testProfile, "testUser")
	suite.Require().NoError(err)

	initialVersion := config.Version()

	// Each operation should increment version
	newValue, _ := NewConfigValue("dark")
	config.ChangeConfiguration(ConfigKeyTheme, *newValue, "testUser")
	assert.Equal(suite.T(), initialVersion+1, config.Version())

	prodProfile, _ := NewProfile("prod")
	config.SwitchProfile(*prodProfile, "testUser")
	assert.Equal(suite.T(), initialVersion+2, config.Version())

	config.CreateBackup("/test/path", "testUser")
	assert.Equal(suite.T(), initialVersion+3, config.Version())

	config.ValidateConfiguration("testUser")
	assert.Equal(suite.T(), initialVersion+4, config.Version())
}

func (suite *ConfigurationAggregateTestSuite) TestDefaultSettingsPerProfile() {
	profiles := []struct {
		profile            Profile
		expectedParallel   string
		expectedThreshold  string
	}{
		{ProfileDev, "50", "500"},
		{ProfileProd, "10", "2000"},
		{ProfilePersonal, "20", "1000"},
	}

	for _, p := range profiles {
		config, err := NewConfiguration(p.profile, "testUser")
		suite.Require().NoError(err)

		parallelTasks, exists := config.GetSetting(ConfigKeyParallelTasksCount)
		assert.True(suite.T(), exists)
		assert.Equal(suite.T(), p.expectedParallel, parallelTasks.Value())

		threshold, exists := config.GetSetting(ConfigKeyMessageIdleNotifThresholdMs)
		assert.True(suite.T(), exists)
		assert.Equal(suite.T(), p.expectedThreshold, threshold.Value())
	}
}

// Run the configuration aggregate test suite
func TestConfigurationAggregateTestSuite(t *testing.T) {
	suite.Run(t, new(ConfigurationAggregateTestSuite))
}