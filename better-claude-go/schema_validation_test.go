package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// SchemaValidationTestSuite contains tests for schema validation
type SchemaValidationTestSuite struct {
	suite.Suite
	validator *SchemaValidator
}

func (suite *SchemaValidationTestSuite) SetupTest() {
	suite.validator = NewSchemaValidator(ConfigSchema)
}

// Test Schema Validator Creation
func (suite *SchemaValidationTestSuite) TestNewSchemaValidator() {
	validator := NewSchemaValidator(ConfigSchema)
	assert.NotNil(suite.T(), validator)
	assert.Equal(suite.T(), ConfigSchema, validator.schema)
}

// Test Config Schema Validation
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateConfig_ValidConfig() {
	config := NewConfigBuilder().
		WithTheme("dark-daltonized").
		WithParallelTasksCount("20").
		WithNotificationChannel("iterm2_with_bell").
		WithMessageIdleThreshold("1000").
		WithAutoUpdates("false").
		WithDiffTool("bat").
		WithEnvVar("VALID_VAR", "value").
		Build()
	
	errors := suite.validator.ValidateConfig(config)
	assert.False(suite.T(), errors.HasErrors(), "Valid config should pass schema validation")
}

func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateConfig_MissingRequiredField() {
	config := NewConfigBuilder().
		WithTheme(""). // Empty required field
		Build()
	
	errors := suite.validator.ValidateConfig(config)
	assert.True(suite.T(), errors.HasErrors(), "Config missing required field should fail")
	assert.Contains(suite.T(), errors.Error(), "required", "Should mention required field")
}

func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateConfig_InvalidEnum() {
	config := NewConfigBuilder().
		WithTheme("invalid_theme").
		Build()
	
	errors := suite.validator.ValidateConfig(config)
	assert.True(suite.T(), errors.HasErrors(), "Invalid enum value should fail")
	assert.Contains(suite.T(), errors.Error(), "must be one of", "Should list valid enum values")
}

func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateConfig_InvalidPattern() {
	config := NewConfigBuilder().
		WithParallelTasksCount("abc"). // Invalid number pattern
		Build()
	
	errors := suite.validator.ValidateConfig(config)
	assert.True(suite.T(), errors.HasErrors(), "Invalid pattern should fail")
	assert.Contains(suite.T(), errors.Error(), "pattern", "Should mention pattern mismatch")
}

func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateConfig_StringConstraints() {
	// Test minimum length
	config := NewConfigBuilder().
		WithTheme(""). // Empty string fails minLength
		Build()
	
	errors := suite.validator.ValidateConfig(config)
	assert.True(suite.T(), errors.HasErrors(), "String below minimum length should fail")
}

// Test ProfileConfig Schema Validation
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateProfileConfig_Valid() {
	profileConfig := NewProfileConfigBuilder().
		WithProfile(ProfileDev).
		WithTheme("dark-daltonized").
		WithParallelTasksCount("50").
		WithEnvVar("EDITOR", "nano").
		Build()
	
	validator := NewSchemaValidator(ProfileConfigSchema)
	errors := validator.ValidateProfileConfig(*profileConfig)
	assert.False(suite.T(), errors.HasErrors(), "Valid profile config should pass")
}

func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateProfileConfig_InvalidProfile() {
	profileConfig := NewProfileConfigBuilder().
		WithProfile("invalid_profile").
		Build()
	
	validator := NewSchemaValidator(ProfileConfigSchema)
	errors := validator.ValidateProfileConfig(*profileConfig)
	assert.True(suite.T(), errors.HasErrors(), "Invalid profile should fail")
	assert.Contains(suite.T(), errors.Error(), "must be one of", "Should list valid profiles")
}

// Test ApplicationOptions Schema Validation
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateApplicationOptions_Valid() {
	options := NewApplicationOptionsBuilder().
		WithProfile(ProfileDev).
		WithDryRun(true).
		WithForwardArgs("chat", "status").
		Build()
	
	validator := NewSchemaValidator(ApplicationOptionsSchema)
	errors := validator.ValidateApplicationOptions(options)
	assert.False(suite.T(), errors.HasErrors(), "Valid application options should pass")
}

func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateApplicationOptions_InvalidForwardArgs() {
	options := NewApplicationOptionsBuilder().
		WithForwardArgs("command; dangerous", "rm | pipe").
		Build()
	
	validator := NewSchemaValidator(ApplicationOptionsSchema)
	errors := validator.ValidateApplicationOptions(options)
	assert.True(suite.T(), errors.HasErrors(), "Dangerous forward args should fail")
	assert.Contains(suite.T(), errors.Error(), "pattern", "Should mention pattern violation")
}

// Test Type Validation
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateType() {
	testCases := []struct {
		value        interface{}
		expectedType string
		shouldPass   bool
	}{
		{"string", "string", true},
		{42.0, "number", true},
		{42, "number", true},
		{true, "boolean", true},
		{map[string]interface{}{}, "object", true},
		{[]interface{}{}, "array", true},
		{nil, "null", true},
		{"string", "number", false},
		{42, "string", false},
		{true, "string", false},
	}
	
	for _, tc := range testCases {
		result := suite.validator.validateType(tc.value, tc.expectedType)
		assert.Equal(suite.T(), tc.shouldPass, result, 
			"Type validation for %v as %s should be %t", tc.value, tc.expectedType, tc.shouldPass)
	}
}

// Test Enum Validation
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateEnum() {
	enumValues := []string{"option1", "option2", "option3"}
	
	validCases := []string{"option1", "option2", "option3"}
	invalidCases := []string{"invalid", "OPTION1", "", "option4"}
	
	for _, value := range validCases {
		result := suite.validator.validateEnum(value, enumValues)
		assert.True(suite.T(), result, "Valid enum value %s should pass", value)
	}
	
	for _, value := range invalidCases {
		result := suite.validator.validateEnum(value, enumValues)
		assert.False(suite.T(), result, "Invalid enum value %s should fail", value)
	}
}

// Test Pattern Matching
func (suite *SchemaValidationTestSuite) TestSchemaValidator_MatchesPattern() {
	testCases := []struct {
		value   string
		pattern string
		matches bool
	}{
		// Positive integer pattern
		{"123", "^[1-9][0-9]*$", true},
		{"1", "^[1-9][0-9]*$", true},
		{"0", "^[1-9][0-9]*$", false},
		{"abc", "^[1-9][0-9]*$", false},
		{"", "^[1-9][0-9]*$", false},
		
		// Non-negative integer pattern
		{"0", "^[0-9]+$", true},
		{"123", "^[0-9]+$", true},
		{"abc", "^[0-9]+$", false},
		{"", "^[0-9]+$", false},
		
		// Environment variable name pattern
		{"VALID_NAME", "^[A-Z_][A-Z0-9_]*$", true},
		{"_VALID", "^[A-Z_][A-Z0-9_]*$", true},
		{"API_KEY_123", "^[A-Z_][A-Z0-9_]*$", true},
		{"123invalid", "^[A-Z_][A-Z0-9_]*$", false},
		{"invalid-name", "^[A-Z_][A-Z0-9_]*$", false},
		{"lowercase", "^[A-Z_][A-Z0-9_]*$", false},
		
		// No shell metacharacters pattern
		{"safe_command", "^[^;&|]*$", true},
		{"command args", "^[^;&|]*$", true},
		{"command; dangerous", "^[^;&|]*$", false},
		{"command & background", "^[^;&|]*$", false},
		{"command | pipe", "^[^;&|]*$", false},
	}
	
	for _, tc := range testCases {
		result := suite.validator.matchesPattern(tc.value, tc.pattern)
		assert.Equal(suite.T(), tc.matches, result,
			"Pattern matching for '%s' against '%s' should be %t", tc.value, tc.pattern, tc.matches)
	}
}

// Test String Constraints
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateString() {
	schema := map[string]interface{}{
		"minLength": 3,
		"maxLength": 10,
		"pattern":   "^[a-zA-Z]+$",
	}
	
	testCases := []struct {
		value       string
		shouldError bool
		errorType   string
	}{
		{"abc", false, ""},                    // Valid
		{"abcdefghij", false, ""},             // Valid at max length
		{"ab", true, "minimum length"},        // Too short
		{"abcdefghijk", true, "maximum length"}, // Too long
		{"abc123", true, "pattern"},           // Invalid pattern
	}
	
	for _, tc := range testCases {
		errors := suite.validator.validateString("test", tc.value, schema)
		
		if tc.shouldError {
			assert.True(suite.T(), errors.HasErrors(), "Should have error for: %s", tc.value)
			assert.Contains(suite.T(), errors.Error(), tc.errorType, "Error should mention: %s", tc.errorType)
		} else {
			assert.False(suite.T(), errors.HasErrors(), "Should not have error for: %s", tc.value)
		}
	}
}

// Test Number Constraints
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateNumber() {
	schema := map[string]interface{}{
		"minimum": 1,
		"maximum": 100,
	}
	
	testCases := []struct {
		value       float64
		shouldError bool
		errorType   string
	}{
		{50.0, false, ""},              // Valid
		{1.0, false, ""},               // Valid at minimum
		{100.0, false, ""},             // Valid at maximum
		{0.5, true, "minimum value"},   // Below minimum
		{101.0, true, "maximum value"}, // Above maximum
	}
	
	for _, tc := range testCases {
		errors := suite.validator.validateNumber("test", tc.value, schema)
		
		if tc.shouldError {
			assert.True(suite.T(), errors.HasErrors(), "Should have error for: %f", tc.value)
			assert.Contains(suite.T(), errors.Error(), tc.errorType, "Error should mention: %s", tc.errorType)
		} else {
			assert.False(suite.T(), errors.HasErrors(), "Should not have error for: %f", tc.value)
		}
	}
}

// Test Object Validation
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateObject() {
	schema := map[string]interface{}{
		"required": []string{"name", "type"},
		"properties": map[string]interface{}{
			"name": map[string]interface{}{
				"type": "string",
			},
			"type": map[string]interface{}{
				"type": "string",
				"enum": []string{"user", "admin"},
			},
		},
	}
	
	// Valid object
	validObj := map[string]interface{}{
		"name": "John",
		"type": "user",
	}
	errors := suite.validator.validateObject("", validObj, schema)
	assert.False(suite.T(), errors.HasErrors(), "Valid object should pass")
	
	// Missing required property
	missingReq := map[string]interface{}{
		"name": "John",
		// missing "type"
	}
	errors = suite.validator.validateObject("", missingReq, schema)
	assert.True(suite.T(), errors.HasErrors(), "Object missing required property should fail")
	assert.Contains(suite.T(), errors.Error(), "required", "Should mention required property")
	
	// Invalid property value
	invalidProp := map[string]interface{}{
		"name": "John",
		"type": "invalid_type",
	}
	errors = suite.validator.validateObject("", invalidProp, schema)
	assert.True(suite.T(), errors.HasErrors(), "Object with invalid property should fail")
}

// Test Array Validation
func (suite *SchemaValidationTestSuite) TestSchemaValidator_ValidateArray() {
	schema := map[string]interface{}{
		"items": map[string]interface{}{
			"type": "string",
			"pattern": "^[a-zA-Z]+$",
		},
	}
	
	// Valid array
	validArray := []interface{}{"abc", "def", "ghi"}
	errors := suite.validator.validateArray("", validArray, schema)
	assert.False(suite.T(), errors.HasErrors(), "Valid array should pass")
	
	// Invalid array item
	invalidArray := []interface{}{"abc", "123", "def"}
	errors = suite.validator.validateArray("", invalidArray, schema)
	assert.True(suite.T(), errors.HasErrors(), "Array with invalid item should fail")
	assert.Contains(suite.T(), errors.Error(), "[1]", "Should indicate array index")
}

// Test Struct to Map Conversion
func (suite *SchemaValidationTestSuite) TestStructToMap() {
	config := Config{
		Theme:                        "dark",
		ParallelTasksCount:          "20",
		PreferredNotifChannel:       "iterm2_with_bell",
		MessageIdleNotifThresholdMs: "1000",
		AutoUpdates:                 "false",
		DiffTool:                    "bat",
		Env: map[string]string{
			"VAR1": "value1",
		},
	}
	
	result := structToMap(config)
	
	assert.Equal(suite.T(), "dark", result["theme"])
	assert.Equal(suite.T(), "20", result["parallelTasksCount"])
	assert.Equal(suite.T(), "iterm2_with_bell", result["preferredNotifChannel"])
	assert.Equal(suite.T(), "1000", result["messageIdleNotifThresholdMs"])
	assert.Equal(suite.T(), "false", result["autoUpdates"])
	assert.Equal(suite.T(), "bat", result["diffTool"])
	assert.NotNil(suite.T(), result["env"])
}

// Test JSON Validation
func (suite *SchemaValidationTestSuite) TestValidateJSON_ValidJSON() {
	validJSON := `{
		"theme": "dark-daltonized",
		"parallelTasksCount": "20",
		"preferredNotifChannel": "iterm2_with_bell",
		"messageIdleNotifThresholdMs": "1000",
		"autoUpdates": "false",
		"diffTool": "bat",
		"env": {}
	}`
	
	errors := ValidateJSON(validJSON, ConfigSchema)
	assert.False(suite.T(), errors.HasErrors(), "Valid JSON should pass validation")
}

func (suite *SchemaValidationTestSuite) TestValidateJSON_InvalidJSON() {
	invalidJSON := `{
		"theme": "dark-daltonized",
		"parallelTasksCount": "20",
		"invalidField": true,
	}` // Trailing comma makes it invalid
	
	errors := ValidateJSON(invalidJSON, ConfigSchema)
	assert.True(suite.T(), errors.HasErrors(), "Invalid JSON should fail validation")
	assert.Contains(suite.T(), errors.Error(), "invalid JSON", "Should mention JSON parsing error")
}

func (suite *SchemaValidationTestSuite) TestValidateJSON_SchemaViolation() {
	jsonWithViolation := `{
		"theme": "invalid_theme",
		"parallelTasksCount": "abc",
		"env": {}
	}`
	
	errors := ValidateJSON(jsonWithViolation, ConfigSchema)
	assert.True(suite.T(), errors.HasErrors(), "JSON with schema violations should fail")
	assert.Contains(suite.T(), errors.Error(), "must be one of", "Should mention enum violation")
}

// Test Edge Cases
func (suite *SchemaValidationTestSuite) TestSchemaValidator_EdgeCases() {
	// Empty schema
	emptyValidator := NewSchemaValidator(map[string]interface{}{})
	config := NewConfigBuilder().Build()
	errors := emptyValidator.ValidateConfig(config)
	assert.False(suite.T(), errors.HasErrors(), "Empty schema should not cause errors")
	
	// Nil values
	var nilConfig Config
	errors = suite.validator.ValidateConfig(nilConfig)
	// Should handle nil gracefully (might have errors for required fields)
	assert.NotPanics(suite.T(), func() {
		suite.validator.ValidateConfig(nilConfig)
	})
}

// Test Schema Constants
func (suite *SchemaValidationTestSuite) TestSchemaConstants() {
	// Test that schema constants are properly defined
	assert.NotNil(suite.T(), ConfigSchema)
	assert.NotNil(suite.T(), ProfileConfigSchema)
	assert.NotNil(suite.T(), ApplicationOptionsSchema)
	
	// Test schema structure
	assert.Equal(suite.T(), "object", ConfigSchema["type"])
	assert.NotNil(suite.T(), ConfigSchema["properties"])
	assert.NotNil(suite.T(), ConfigSchema["required"])
	
	// Test required fields
	required, ok := ConfigSchema["required"].([]string)
	assert.True(suite.T(), ok, "Required should be a string slice")
	assert.Contains(suite.T(), required, "theme", "Theme should be required")
}

// Run the schema validation test suite
func TestSchemaValidationTestSuite(t *testing.T) {
	suite.Run(t, new(SchemaValidationTestSuite))
}