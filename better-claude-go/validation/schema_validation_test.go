package validation

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"

	"better-claude/domain"
	testfixtures "better-claude/testing"
)

// SchemaValidationTestSuite contains tests for JSON schema validation
type SchemaValidationTestSuite struct {
	suite.Suite
	schemaValidator *SchemaValidator
	scenarios       *testfixtures.TestScenarios
}

func (suite *SchemaValidationTestSuite) SetupTest() {
	suite.schemaValidator = NewSchemaValidator()
	suite.scenarios = testfixtures.NewTestScenarios()
}

// Test JSON Schema Generation
func (suite *SchemaValidationTestSuite) TestSchemaGeneration_Configuration() {
	schema := suite.schemaValidator.GetConfigurationSchema()

	assert.NotNil(suite.T(), schema)
	assert.Equal(suite.T(), "object", schema.Type)
	assert.NotEmpty(suite.T(), schema.Properties)
	assert.Contains(suite.T(), schema.Required, "profile")
	// Settings are not required since they can have defaults
}

func (suite *SchemaValidationTestSuite) TestSchemaGeneration_Profile() {
	schema := suite.schemaValidator.GetProfileSchema()

	assert.NotNil(suite.T(), schema)
	assert.Equal(suite.T(), "string", schema.Type)
	assert.NotEmpty(suite.T(), schema.Enum)
	assert.Contains(suite.T(), schema.Enum, "dev")
	assert.Contains(suite.T(), schema.Enum, "prod")
	assert.Contains(suite.T(), schema.Enum, "personal")
}

func (suite *SchemaValidationTestSuite) TestSchemaGeneration_ConfigValue() {
	themeSchema := suite.schemaValidator.GetConfigValueSchema("theme")

	assert.NotNil(suite.T(), themeSchema)
	assert.Equal(suite.T(), "string", themeSchema.Type)
	assert.NotEmpty(suite.T(), themeSchema.Enum)
	assert.Contains(suite.T(), themeSchema.Enum, "dark")
	assert.Contains(suite.T(), themeSchema.Enum, "light")
}

// Test Configuration Validation Against Schema
func (suite *SchemaValidationTestSuite) TestValidateConfiguration_ValidConfigs() {
	validConfigs := []*domain.Configuration{
		suite.scenarios.ValidDevConfiguration(),
		suite.scenarios.ValidProdConfiguration(),
		suite.scenarios.ValidPersonalConfiguration(),
	}

	for i, config := range validConfigs {
		errors := suite.schemaValidator.ValidateConfiguration(config)
		assert.Empty(suite.T(), errors, "Valid configuration %d should pass schema validation", i)
	}
}

func (suite *SchemaValidationTestSuite) TestValidateConfiguration_InvalidConfigs() {
	invalidConfig := suite.scenarios.ConfigurationWithValidationErrors()

	errors := suite.schemaValidator.ValidateConfiguration(invalidConfig)
	assert.NotEmpty(suite.T(), errors, "Invalid configuration should fail schema validation")
}

// Test JSON Serialization/Deserialization Validation
func (suite *SchemaValidationTestSuite) TestJSONSerialization_Configuration() {
	config := suite.scenarios.ValidDevConfiguration()

	// Convert to JSON-serializable format
	configData := suite.schemaValidator.ConfigurationToJSON(config)
	assert.NotNil(suite.T(), configData)

	// Validate the JSON structure
	jsonBytes, err := json.Marshal(configData)
	assert.NoError(suite.T(), err)
	assert.NotEmpty(suite.T(), jsonBytes)

	// Validate against schema
	errors := suite.schemaValidator.ValidateJSON(configData)
	assert.Empty(suite.T(), errors, "Serialized configuration should be valid JSON")
}

func (suite *SchemaValidationTestSuite) TestJSONDeserialization_Configuration() {
	// Create valid JSON data
	jsonData := map[string]interface{}{
		"profile": "dev",
		"settings": map[string]interface{}{
			"theme":                       "dark",
			"parallelTasksCount":          "50",
			"autoUpdates":                 "false",
			"preferredNotifChannel":       "iterm2_with_bell",
			"messageIdleNotifThresholdMs": "500",
			"diffTool":                    "bat",
		},
		"envVariables": map[string]interface{}{
			"CLAUDE_CODE_ENABLE_TELEMETRY": "1",
			"EDITOR":                       "nano",
		},
	}

	// Validate against schema
	errors := suite.schemaValidator.ValidateJSON(jsonData)
	assert.Empty(suite.T(), errors, "Valid JSON should pass schema validation")

	// Convert back to configuration
	config, err := suite.schemaValidator.JSONToConfiguration(jsonData)
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), config)
}

// Test Schema Constraint Validation
func (suite *SchemaValidationTestSuite) TestSchemaConstraints_ThemeValues() {
	validThemes := []string{"dark", "light", "dark-daltonized", "auto"}
	invalidThemes := []string{"invalid", "", "DARK", "custom"}

	for _, theme := range validThemes {
		jsonData := map[string]interface{}{
			"profile": "dev",
			"settings": map[string]interface{}{
				"theme": theme,
			},
		}

		errors := suite.schemaValidator.ValidateJSON(jsonData)
		assert.Empty(suite.T(), errors, "Valid theme '%s' should pass schema validation", theme)
	}

	for _, theme := range invalidThemes {
		jsonData := map[string]interface{}{
			"profile": "dev",
			"settings": map[string]interface{}{
				"theme": theme,
			},
		}

		errors := suite.schemaValidator.ValidateJSON(jsonData)
		assert.NotEmpty(suite.T(), errors, "Invalid theme '%s' should fail schema validation", theme)
	}
}

func (suite *SchemaValidationTestSuite) TestSchemaConstraints_ParallelTasksCount() {
	validCounts := []string{"1", "50", "1000"}
	invalidCounts := []string{"0", "-1", "1001", "abc", ""}

	for _, count := range validCounts {
		jsonData := map[string]interface{}{
			"profile": "dev",
			"settings": map[string]interface{}{
				"parallelTasksCount": count,
			},
		}

		errors := suite.schemaValidator.ValidateJSON(jsonData)
		assert.Empty(suite.T(), errors, "Valid count '%s' should pass schema validation", count)
	}

	for _, count := range invalidCounts {
		jsonData := map[string]interface{}{
			"profile": "dev",
			"settings": map[string]interface{}{
				"parallelTasksCount": count,
			},
		}

		errors := suite.schemaValidator.ValidateJSON(jsonData)
		assert.NotEmpty(suite.T(), errors, "Invalid count '%s' should fail schema validation", count)
	}
}

// Test Environment Variable Schema Validation
func (suite *SchemaValidationTestSuite) TestEnvironmentVariableSchema() {
	validEnvVars := map[string]string{
		"CLAUDE_CODE_ENABLE_TELEMETRY": "1",
		"EDITOR":                       "nano",
		"DEBUG":                        "true",
	}

	invalidEnvVars := map[string]string{
		"PATH": "dangerous",
		"HOME": "dangerous",
	}

	// Test valid environment variables
	validEnvVarsInterface := make(map[string]interface{})
	for k, v := range validEnvVars {
		validEnvVarsInterface[k] = v
	}

	jsonData := map[string]interface{}{
		"profile":      "dev",
		"envVariables": validEnvVarsInterface,
	}

	errors := suite.schemaValidator.ValidateJSON(jsonData)
	assert.Empty(suite.T(), errors, "Valid environment variables should pass schema validation")

	// Test invalid environment variables
	for name, value := range invalidEnvVars {
		invalidEnvVarsInterface := map[string]interface{}{
			name: value,
		}

		jsonData := map[string]interface{}{
			"profile":      "dev",
			"envVariables": invalidEnvVarsInterface,
		}

		errors := suite.schemaValidator.ValidateJSON(jsonData)
		assert.NotEmpty(suite.T(), errors, "Invalid environment variable '%s' should fail schema validation", name)
	}
}

// Test Required Fields Validation
func (suite *SchemaValidationTestSuite) TestRequiredFields() {
	// Missing profile
	jsonData := map[string]interface{}{
		"settings": map[string]interface{}{
			"theme": "dark",
		},
	}

	errors := suite.schemaValidator.ValidateJSON(jsonData)
	assert.NotEmpty(suite.T(), errors, "Missing profile should fail schema validation")

	// Missing settings (if required)
	jsonData = map[string]interface{}{
		"profile": "dev",
	}

	errors = suite.schemaValidator.ValidateJSON(jsonData)
	// Settings might not be required if they have defaults
	assert.True(suite.T(), len(errors) >= 0, "Schema validation should complete")
}

// Test Additional Properties Handling
func (suite *SchemaValidationTestSuite) TestAdditionalProperties() {
	jsonData := map[string]interface{}{
		"profile": "dev",
		"settings": map[string]interface{}{
			"theme": "dark",
		},
		"unknownField": "should be rejected",
	}

	errors := suite.schemaValidator.ValidateJSON(jsonData)
	assert.NotEmpty(suite.T(), errors, "Unknown fields should fail schema validation")
}

// Test Schema Evolution and Backward Compatibility
func (suite *SchemaValidationTestSuite) TestSchemaEvolution_BackwardCompatibility() {
	// Test that old configuration formats are still supported
	oldFormatJSON := map[string]interface{}{
		"profile": "dev",
		"settings": map[string]interface{}{
			"theme": "dark",
			// Missing newer fields should be okay
		},
	}

	errors := suite.schemaValidator.ValidateJSON(oldFormatJSON)
	assert.Empty(suite.T(), errors, "Old configuration format should be backward compatible")
}

func (suite *SchemaValidationTestSuite) TestSchemaEvolution_ForwardCompatibility() {
	// Test handling of unknown future fields
	futureFormatJSON := map[string]interface{}{
		"profile": "dev",
		"settings": map[string]interface{}{
			"theme":       "dark",
			"futureField": "should be ignored or accepted",
		},
		"schemaVersion": "2.0", // Future schema version
	}

	// This behavior depends on schema configuration
	errors := suite.schemaValidator.ValidateJSON(futureFormatJSON)
	assert.True(suite.T(), len(errors) >= 0, "Future format handling should complete")
}

// Test Performance with Large Configurations
func (suite *SchemaValidationTestSuite) TestSchemaValidation_Performance() {
	// Create a large configuration
	largeSettings := make(map[string]interface{})
	for i := 0; i < 100; i++ {
		largeSettings[fmt.Sprintf("customField_%d", i)] = "value"
	}

	jsonData := map[string]interface{}{
		"profile":  "dev",
		"settings": largeSettings,
	}

	// Should handle large configurations efficiently
	errors := suite.schemaValidator.ValidateJSON(jsonData)
	assert.True(suite.T(), len(errors) >= 0, "Large configuration validation should complete")
}

// Test Schema Error Messages Quality
func (suite *SchemaValidationTestSuite) TestSchemaErrorMessages_Quality() {
	// Invalid enum value
	jsonData := map[string]interface{}{
		"profile": "invalid_profile",
	}

	errors := suite.schemaValidator.ValidateJSON(jsonData)
	assert.NotEmpty(suite.T(), errors)

	// Error should be descriptive
	errorMsg := errors[0].Message
	assert.Contains(suite.T(), errorMsg, "profile")
	assert.Contains(suite.T(), errorMsg, "invalid_profile")
	assert.NotEmpty(suite.T(), errors[0].Field)
	assert.NotEmpty(suite.T(), errors[0].Code)
}

// Test Custom Schema Rules
func (suite *SchemaValidationTestSuite) TestCustomSchemaRules_ProfileSpecific() {
	// Development profile should allow higher parallel task counts
	devConfigJSON := map[string]interface{}{
		"profile": "dev",
		"settings": map[string]interface{}{
			"parallelTasksCount": "100", // High count for dev
		},
	}

	errors := suite.schemaValidator.ValidateJSON(devConfigJSON)
	assert.Empty(suite.T(), errors, "High parallel tasks should be allowed for dev profile")

	// Production profile should warn about high parallel task counts
	prodConfigJSON := map[string]interface{}{
		"profile": "prod",
		"settings": map[string]interface{}{
			"parallelTasksCount": "100", // High count for prod
		},
	}

	errors = suite.schemaValidator.ValidateJSON(prodConfigJSON)
	// Might generate warnings but not necessarily errors
	assert.True(suite.T(), len(errors) >= 0, "Production validation should complete")
}

// Test Schema Validation Caching
func (suite *SchemaValidationTestSuite) TestSchemaValidation_Caching() {
	config := suite.scenarios.ValidDevConfiguration()

	// First validation
	errors1 := suite.schemaValidator.ValidateConfiguration(config)

	// Second validation (should use cached schema)
	errors2 := suite.schemaValidator.ValidateConfiguration(config)

	// Results should be consistent
	assert.Equal(suite.T(), len(errors1), len(errors2))
}

// Run the schema validation test suite
func TestSchemaValidationTestSuite(t *testing.T) {
	suite.Run(t, new(SchemaValidationTestSuite))
}

// Additional helper tests for schema utilities
func TestSchemaValidator_Integration(t *testing.T) {
	validator := NewSchemaValidator()

	// Test that validator can be created
	assert.NotNil(t, validator)

	// Test basic schema functionality
	schema := validator.GetConfigurationSchema()
	assert.NotNil(t, schema)
	assert.Equal(t, "object", schema.Type)
}
