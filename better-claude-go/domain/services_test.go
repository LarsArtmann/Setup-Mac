package domain

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// DomainServicesTestSuite contains tests for domain services
type DomainServicesTestSuite struct {
	suite.Suite
	validationService *ConfigurationValidationService
	migrationService  *ProfileMigrationService
}

func (suite *DomainServicesTestSuite) SetupTest() {
	suite.validationService = NewConfigurationValidationService()
	suite.migrationService = NewProfileMigrationService()
}

// Test ConfigurationValidationService
func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateTheme() {
	testCases := []struct {
		theme       string
		shouldError bool
		description string
	}{
		{"dark", false, "valid dark theme"},
		{"light", false, "valid light theme"},
		{"dark-daltonized", false, "valid dark-daltonized theme"},
		{"auto", false, "valid auto theme"},
		{"invalid-theme", true, "invalid theme"},
		{"", true, "empty theme"},
		{"Dark", true, "case sensitive - uppercase"},
		{"LIGHT", true, "case sensitive - all caps"},
		{"dark ", true, "theme with trailing space"},
		{" dark", true, "theme with leading space"},
	}

	for _, tc := range testCases {
		themeValue, _ := NewConfigValue(tc.theme)
		err := suite.validationService.ValidateTheme(*themeValue)

		if tc.shouldError {
			assert.Error(suite.T(), err, tc.description)
		} else {
			assert.NoError(suite.T(), err, tc.description)
		}
	}
}

func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateParallelTasksCount() {
	testCases := []struct {
		count       string
		shouldError bool
		description string
	}{
		{"1", false, "minimum valid count"},
		{"50", false, "typical valid count"},
		{"1000", false, "maximum valid count"},
		{"0", true, "zero count"},
		{"-1", true, "negative count"},
		{"1001", true, "above maximum"},
		{"", true, "empty count"},
		{"abc", true, "non-numeric"},
		{"50.5", true, "decimal number"},
		{"50 ", true, "number with space"},
		{" 50", true, "number with leading space"},
	}

	for _, tc := range testCases {
		countValue, _ := NewConfigValue(tc.count)
		err := suite.validationService.ValidateParallelTasksCount(*countValue)

		if tc.shouldError {
			assert.Error(suite.T(), err, tc.description)
		} else {
			assert.NoError(suite.T(), err, tc.description)
		}
	}
}

func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateMessageIdleThreshold() {
	testCases := []struct {
		threshold   string
		shouldError bool
		description string
	}{
		{"0", false, "minimum valid threshold"},
		{"1000", false, "typical valid threshold"},
		{"60000", false, "maximum valid threshold"},
		{"-1", true, "negative threshold"},
		{"60001", true, "above maximum"},
		{"", true, "empty threshold"},
		{"abc", true, "non-numeric"},
		{"1000.5", true, "decimal number"},
	}

	for _, tc := range testCases {
		thresholdValue, _ := NewConfigValue(tc.threshold)
		err := suite.validationService.ValidateMessageIdleThreshold(*thresholdValue)

		if tc.shouldError {
			assert.Error(suite.T(), err, tc.description)
		} else {
			assert.NoError(suite.T(), err, tc.description)
		}
	}
}

func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateAutoUpdates() {
	testCases := []struct {
		value       string
		shouldError bool
		description string
	}{
		{"true", false, "valid true"},
		{"false", false, "valid false"},
		{"True", true, "case sensitive - uppercase"},
		{"FALSE", true, "case sensitive - all caps"},
		{"yes", true, "yes instead of true"},
		{"no", true, "no instead of false"},
		{"1", true, "numeric 1"},
		{"0", true, "numeric 0"},
		{"", true, "empty value"},
		{"maybe", true, "invalid value"},
	}

	for _, tc := range testCases {
		autoUpdatesValue, _ := NewConfigValue(tc.value)
		err := suite.validationService.ValidateAutoUpdates(*autoUpdatesValue)

		if tc.shouldError {
			assert.Error(suite.T(), err, tc.description)
		} else {
			assert.NoError(suite.T(), err, tc.description)
		}
	}
}

func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateNotificationChannel() {
	testCases := []struct {
		channel     string
		shouldError bool
		description string
	}{
		{"none", false, "valid none channel"},
		{"iterm2", false, "valid iterm2 channel"},
		{"iterm2_with_bell", false, "valid iterm2 with bell"},
		{"system", false, "valid system channel"},
		{"invalid", true, "invalid channel"},
		{"", true, "empty channel"},
		{"iTerm2", true, "case sensitive"},
		{"iterm2-with-bell", true, "dash instead of underscore"},
		{"terminal", true, "unsupported terminal"},
	}

	for _, tc := range testCases {
		channelValue, _ := NewConfigValue(tc.channel)
		err := suite.validationService.ValidateNotificationChannel(*channelValue)

		if tc.shouldError {
			assert.Error(suite.T(), err, tc.description)
		} else {
			assert.NoError(suite.T(), err, tc.description)
		}
	}
}

func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateDiffTool() {
	testCases := []struct {
		tool        string
		shouldError bool
		description string
	}{
		{"bat", false, "valid bat tool"},
		{"diff", false, "valid diff tool"},
		{"code", false, "valid vscode tool"},
		{"nano", false, "valid nano tool"},
		{"vim", false, "valid vim tool"},
		{"invalid", true, "invalid tool"},
		{"", true, "empty tool"},
		{"BAT", true, "case sensitive"},
		{"vs-code", true, "unsupported variant"},
		{"emacs", true, "unsupported editor"},
	}

	for _, tc := range testCases {
		toolValue, _ := NewConfigValue(tc.tool)
		err := suite.validationService.ValidateDiffTool(*toolValue)

		if tc.shouldError {
			assert.Error(suite.T(), err, tc.description)
		} else {
			assert.NoError(suite.T(), err, tc.description)
		}
	}
}

func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateEnvironmentVariable() {
	testCases := []struct {
		name        string
		value       string
		shouldError bool
		description string
	}{
		{"CUSTOM_VAR", "value", false, "valid custom variable"},
		{"CLAUDE_CODE_ENABLE_TELEMETRY", "1", false, "valid claude variable"},
		{"EDITOR", "nano", false, "valid editor variable"},
		{"PATH", "dangerous", true, "system PATH variable"},
		{"HOME", "dangerous", true, "system HOME variable"},
		{"USER", "dangerous", true, "system USER variable"},
		{"SHELL", "dangerous", true, "system SHELL variable"},
		{"PWD", "dangerous", true, "system PWD variable"},
		{"TERM", "dangerous", true, "system TERM variable"},
		{"", "value", true, "empty variable name"},
		{"VALID_VAR", "", false, "empty value allowed"},
		{"invalid var", "value", true, "invalid variable name with space"},
		{"123INVALID", "value", true, "variable starting with number"},
	}

	for _, tc := range testCases {
		err := suite.validationService.ValidateEnvironmentVariable(tc.name, tc.value)

		if tc.shouldError {
			assert.Error(suite.T(), err, tc.description)
		} else {
			assert.NoError(suite.T(), err, tc.description)
		}
	}
}

func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateCompleteConfiguration() {
	// Test valid complete configuration
	profile, _ := NewProfile("dev")
	config, err := NewConfiguration(*profile, "testUser")
	suite.Require().NoError(err)

	errors := suite.validationService.ValidateCompleteConfiguration(config)
	assert.Empty(suite.T(), errors, "Valid configuration should pass validation")
}

func (suite *DomainServicesTestSuite) TestConfigurationValidationService_ValidateCompleteConfiguration_WithErrors() {
	// Test configuration with multiple errors
	profile, _ := NewProfile("dev")
	config, err := NewConfiguration(*profile, "testUser")
	suite.Require().NoError(err)

	// Introduce validation errors
	invalidTheme, _ := NewConfigValue("invalid-theme")
	config.settings[ConfigKeyTheme] = *invalidTheme

	invalidCount, _ := NewConfigValue("invalid")
	config.settings[ConfigKeyParallelTasksCount] = *invalidCount

	errors := suite.validationService.ValidateCompleteConfiguration(config)
	assert.NotEmpty(suite.T(), errors, "Invalid configuration should fail validation")
	assert.Contains(suite.T(), errors[0], "theme")
	assert.Greater(suite.T(), len(errors), 1, "Should have multiple validation errors")
}

// Test ProfileMigrationService
func (suite *DomainServicesTestSuite) TestProfileMigrationService_CalculateMigrationChanges() {
	devProfile, _ := NewProfile("dev")
	prodProfile, _ := NewProfile("prod")

	changes := suite.migrationService.CalculateMigrationChanges(*devProfile, *prodProfile)

	assert.NotEmpty(suite.T(), changes, "Migration between different profiles should have changes")
	
	// Verify specific expected changes between dev and prod profiles
	found := false
	for _, change := range changes {
		if change.Key.IsEqual(ConfigKeyParallelTasksCount) {
			assert.Equal(suite.T(), "50", change.OldValue.Value())
			assert.Equal(suite.T(), "10", change.NewValue.Value())
			found = true
			break
		}
	}
	assert.True(suite.T(), found, "Should find parallel tasks count change")
}

func (suite *DomainServicesTestSuite) TestProfileMigrationService_CalculateMigrationChanges_SameProfile() {
	devProfile, _ := NewProfile("dev")

	changes := suite.migrationService.CalculateMigrationChanges(*devProfile, *devProfile)

	assert.Empty(suite.T(), changes, "Migration to same profile should have no changes")
}

func (suite *DomainServicesTestSuite) TestProfileMigrationService_ValidateMigration() {
	devProfile, _ := NewProfile("dev")
	prodProfile, _ := NewProfile("prod")

	// Valid migration
	err := suite.migrationService.ValidateMigration(*devProfile, *prodProfile)
	assert.NoError(suite.T(), err, "Valid profile migration should succeed")

	// Invalid migration (same profile)
	err = suite.migrationService.ValidateMigration(*devProfile, *devProfile)
	assert.Error(suite.T(), err, "Migration to same profile should be invalid")
	assert.Contains(suite.T(), err.Error(), "same profile")
}

func (suite *DomainServicesTestSuite) TestProfileMigrationService_GetMigrationRisks() {
	devProfile, _ := NewProfile("dev")
	prodProfile, _ := NewProfile("prod")

	risks := suite.migrationService.GetMigrationRisks(*devProfile, *prodProfile)

	assert.NotEmpty(suite.T(), risks, "Migration from dev to prod should have risks")
	
	// Check for performance-related risks
	foundPerformanceRisk := false
	for _, risk := range risks {
		if risk.Category == "performance" {
			foundPerformanceRisk = true
			break
		}
	}
	assert.True(suite.T(), foundPerformanceRisk, "Should identify performance risks")
}

func (suite *DomainServicesTestSuite) TestProfileMigrationService_GetMigrationRisks_LowRisk() {
	personalProfile, _ := NewProfile("personal")
	devProfile, _ := NewProfile("dev")

	risks := suite.migrationService.GetMigrationRisks(*personalProfile, *devProfile)

	// Should have fewer or lower severity risks
	assert.NotEmpty(suite.T(), risks, "Migration should still have some risks")
	
	// Verify risk levels are appropriate
	for _, risk := range risks {
		assert.Contains(suite.T(), []string{"low", "medium"}, risk.Level, "Risk level should be low or medium")
	}
}

// Test Domain Service Integration
func (suite *DomainServicesTestSuite) TestDomainServices_Integration() {
	// Test that services work together properly
	profile, _ := NewProfile("dev")
	config, err := NewConfiguration(*profile, "testUser")
	suite.Require().NoError(err)

	// Validate initial configuration
	errors := suite.validationService.ValidateCompleteConfiguration(config)
	assert.Empty(suite.T(), errors, "Initial configuration should be valid")

	// Test profile migration
	prodProfile, _ := NewProfile("prod")
	migrationErr := suite.migrationService.ValidateMigration(*profile, *prodProfile)
	assert.NoError(suite.T(), migrationErr, "Migration should be valid")

	// Calculate changes
	changes := suite.migrationService.CalculateMigrationChanges(*profile, *prodProfile)
	assert.NotEmpty(suite.T(), changes, "Should have migration changes")

	// Apply changes and validate
	for _, change := range changes {
		err := config.ChangeConfiguration(change.Key, change.NewValue, "migrationUser")
		assert.NoError(suite.T(), err, "Should be able to apply migration changes")
	}

	// Switch profile
	err = config.SwitchProfile(*prodProfile, "migrationUser")
	assert.NoError(suite.T(), err, "Should be able to switch profile")

	// Validate final configuration
	finalErrors := suite.validationService.ValidateCompleteConfiguration(config)
	assert.Empty(suite.T(), finalErrors, "Final configuration should be valid")
}

// Test Edge Cases and Error Handling
func (suite *DomainServicesTestSuite) TestDomainServices_EdgeCases() {
	// Test with nil configuration
	assert.Panics(suite.T(), func() {
		suite.validationService.ValidateCompleteConfiguration(nil)
	}, "Should panic with nil configuration")

	// Test with empty values
	emptyValue, _ := NewConfigValue("")
	err := suite.validationService.ValidateTheme(*emptyValue)
	assert.Error(suite.T(), err, "Empty theme should be invalid")
}

func (suite *DomainServicesTestSuite) TestDomainServices_ThreadSafety() {
	// Basic test for thread safety (services should be stateless)
	service1 := NewConfigurationValidationService()
	service2 := NewConfigurationValidationService()

	// Services should be independent
	themeValue, _ := NewConfigValue("dark")
	err1 := service1.ValidateTheme(*themeValue)
	err2 := service2.ValidateTheme(*themeValue)

	assert.NoError(suite.T(), err1)
	assert.NoError(suite.T(), err2)
	
	// Both services should behave identically
	invalidValue, _ := NewConfigValue("invalid")
	err1 = service1.ValidateTheme(*invalidValue)
	err2 = service2.ValidateTheme(*invalidValue)

	assert.Error(suite.T(), err1)
	assert.Error(suite.T(), err2)
}

// Run the domain services test suite
func TestDomainServicesTestSuite(t *testing.T) {
	suite.Run(t, new(DomainServicesTestSuite))
}