package validation

import (
	"encoding/json"
	"fmt"
	"strconv"

	"better-claude/domain"
)

// JSONSchema represents a JSON schema definition
type JSONSchema struct {
	Type                 string                    `json:"type"`
	Properties           map[string]*JSONSchema    `json:"properties,omitempty"`
	Required             []string                  `json:"required,omitempty"`
	Enum                 []interface{}             `json:"enum,omitempty"`
	Items                *JSONSchema               `json:"items,omitempty"`
	AdditionalProperties interface{}               `json:"additionalProperties,omitempty"`
	Pattern              string                    `json:"pattern,omitempty"`
	Minimum              *float64                  `json:"minimum,omitempty"`
	Maximum              *float64                  `json:"maximum,omitempty"`
	MinLength            *int                      `json:"minLength,omitempty"`
	MaxLength            *int                      `json:"maxLength,omitempty"`
	Description          string                    `json:"description,omitempty"`
}

// SchemaValidator provides JSON schema validation for domain objects
type SchemaValidator struct {
	configurationSchema *JSONSchema
	profileSchema       *JSONSchema
	configValueSchemas  map[string]*JSONSchema
	securityValidator   *SecurityValidator
}

// NewSchemaValidator creates a new schema validator
func NewSchemaValidator() *SchemaValidator {
	validator := &SchemaValidator{
		configValueSchemas: make(map[string]*JSONSchema),
		securityValidator:  NewSecurityValidator(),
	}
	
	validator.initializeSchemas()
	return validator
}

// GetConfigurationSchema returns the schema for Configuration objects
func (sv *SchemaValidator) GetConfigurationSchema() *JSONSchema {
	return sv.configurationSchema
}

// GetProfileSchema returns the schema for Profile values
func (sv *SchemaValidator) GetProfileSchema() *JSONSchema {
	return sv.profileSchema
}

// GetConfigValueSchema returns the schema for specific config values
func (sv *SchemaValidator) GetConfigValueSchema(key string) *JSONSchema {
	if schema, exists := sv.configValueSchemas[key]; exists {
		return schema
	}
	
	// Return generic string schema for unknown keys
	return &JSONSchema{
		Type:        "string",
		Description: fmt.Sprintf("Configuration value for %s", key),
	}
}

// ValidateConfiguration validates a configuration against the schema
func (sv *SchemaValidator) ValidateConfiguration(config *domain.Configuration) []ValidationError {
	// Convert configuration to JSON-compatible format
	configData := sv.ConfigurationToJSON(config)
	
	// Validate against schema
	return sv.ValidateJSON(configData)
}

// ValidateJSON validates JSON data against the configuration schema
func (sv *SchemaValidator) ValidateJSON(data map[string]interface{}) []ValidationError {
	var errors []ValidationError
	
	// Validate against main configuration schema
	schemaErrors := sv.validateAgainstSchema(data, sv.configurationSchema, "")
	errors = append(errors, schemaErrors...)
	
	// Additional security validation
	securityErrors := sv.validateSecurity(data)
	errors = append(errors, securityErrors...)
	
	return errors
}

// ConfigurationToJSON converts a Configuration to JSON-compatible format
func (sv *SchemaValidator) ConfigurationToJSON(config *domain.Configuration) map[string]interface{} {
	settings := make(map[string]interface{})
	for key, value := range config.Settings() {
		settings[key.Value()] = value.Value()
	}
	
	envVars := make(map[string]interface{})
	for key, value := range config.EnvVariables() {
		envVars[key] = value
	}
	
	return map[string]interface{}{
		"profile":      config.Profile().Value(),
		"settings":     settings,
		"envVariables": envVars,
	}
}

// JSONToConfiguration converts JSON data back to a Configuration
func (sv *SchemaValidator) JSONToConfiguration(data map[string]interface{}) (*domain.Configuration, error) {
	// Extract profile
	profileStr, ok := data["profile"].(string)
	if !ok {
		return nil, fmt.Errorf("profile field is required and must be a string")
	}
	
	profile, err := domain.NewProfile(profileStr)
	if err != nil {
		return nil, fmt.Errorf("invalid profile: %w", err)
	}
	
	// Create configuration
	config, err := domain.NewConfiguration(*profile, "schema-created")
	if err != nil {
		return nil, fmt.Errorf("failed to create configuration: %w", err)
	}
	
	// Apply settings if present
	if settingsData, ok := data["settings"].(map[string]interface{}); ok {
		for keyStr, valueData := range settingsData {
			key, err := domain.NewConfigKey(keyStr)
			if err != nil {
				continue // Skip invalid keys
			}
			
			valueStr, ok := valueData.(string)
			if !ok {
				continue // Skip non-string values
			}
			
			value, err := domain.NewConfigValue(valueStr)
			if err != nil {
				continue // Skip invalid values
			}
			
			config.ChangeConfiguration(*key, *value, "schema-created")
		}
	}
	
	return config, nil
}

// Private methods for schema initialization and validation

func (sv *SchemaValidator) initializeSchemas() {
	sv.profileSchema = &JSONSchema{
		Type: "string",
		Enum: []interface{}{
			"dev", "development", "prod", "production", "personal", "default",
		},
		Description: "Configuration profile that determines default settings",
	}
	
	sv.configurationSchema = &JSONSchema{
		Type: "object",
		Properties: map[string]*JSONSchema{
			"profile": sv.profileSchema,
			"settings": {
				Type: "object",
				Properties: map[string]*JSONSchema{
					"theme":                        sv.createThemeSchema(),
					"parallelTasksCount":          sv.createParallelTasksCountSchema(),
					"autoUpdates":                 sv.createAutoUpdatesSchema(),
					"preferredNotifChannel":       sv.createNotificationChannelSchema(),
					"messageIdleNotifThresholdMs": sv.createMessageThresholdSchema(),
					"diffTool":                    sv.createDiffToolSchema(),
				},
				AdditionalProperties: false,
				Description:          "Configuration settings map",
			},
			"envVariables": {
				Type:                 "object",
				AdditionalProperties: true,
				Description:          "Environment variables map",
			},
		},
		Required:             []string{"profile"},
		AdditionalProperties: false,
		Description:          "Complete configuration object",
	}
	
	// Store individual config value schemas
	sv.configValueSchemas["theme"] = sv.createThemeSchema()
	sv.configValueSchemas["parallelTasksCount"] = sv.createParallelTasksCountSchema()
	sv.configValueSchemas["autoUpdates"] = sv.createAutoUpdatesSchema()
	sv.configValueSchemas["preferredNotifChannel"] = sv.createNotificationChannelSchema()
	sv.configValueSchemas["messageIdleNotifThresholdMs"] = sv.createMessageThresholdSchema()
	sv.configValueSchemas["diffTool"] = sv.createDiffToolSchema()
}

func (sv *SchemaValidator) createThemeSchema() *JSONSchema {
	return &JSONSchema{
		Type: "string",
		Enum: []interface{}{
			"dark", "light", "dark-daltonized", "auto",
		},
		Description: "UI theme for the application",
	}
}

func (sv *SchemaValidator) createParallelTasksCountSchema() *JSONSchema {
	min := float64(1)
	max := float64(1000)
	return &JSONSchema{
		Type:        "string",
		Pattern:     "^[1-9][0-9]*$",
		Minimum:     &min,
		Maximum:     &max,
		Description: "Number of parallel tasks (1-1000)",
	}
}

func (sv *SchemaValidator) createAutoUpdatesSchema() *JSONSchema {
	return &JSONSchema{
		Type: "string",
		Enum: []interface{}{
			"true", "false",
		},
		Description: "Whether to enable automatic updates",
	}
}

func (sv *SchemaValidator) createNotificationChannelSchema() *JSONSchema {
	return &JSONSchema{
		Type: "string",
		Enum: []interface{}{
			"none", "iterm2", "iterm2_with_bell", "system",
		},
		Description: "Preferred notification channel",
	}
}

func (sv *SchemaValidator) createMessageThresholdSchema() *JSONSchema {
	min := float64(0)
	max := float64(60000)
	return &JSONSchema{
		Type:        "string",
		Pattern:     "^[0-9]+$",
		Minimum:     &min,
		Maximum:     &max,
		Description: "Message idle notification threshold in milliseconds (0-60000)",
	}
}

func (sv *SchemaValidator) createDiffToolSchema() *JSONSchema {
	return &JSONSchema{
		Type: "string",
		Enum: []interface{}{
			"bat", "diff", "code", "nano", "vim",
		},
		Description: "Preferred diff tool for code comparison",
	}
}

func (sv *SchemaValidator) validateAgainstSchema(data interface{}, schema *JSONSchema, path string) []ValidationError {
	var errors []ValidationError
	
	switch schema.Type {
	case "object":
		errors = append(errors, sv.validateObject(data, schema, path)...)
	case "string":
		errors = append(errors, sv.validateString(data, schema, path)...)
	case "array":
		errors = append(errors, sv.validateArray(data, schema, path)...)
	}
	
	return errors
}

func (sv *SchemaValidator) validateObject(data interface{}, schema *JSONSchema, path string) []ValidationError {
	var errors []ValidationError
	
	objData, ok := data.(map[string]interface{})
	if !ok {
		errors = append(errors, ValidationError{
			Field:    path,
			Value:    fmt.Sprintf("%v", data),
			Message:  "expected object, got " + fmt.Sprintf("%T", data),
			Code:     "SCHEMA_TYPE_MISMATCH",
			Severity: ValidationSeverityError,
		})
		return errors
	}
	
	// Validate required fields
	for _, required := range schema.Required {
		if _, exists := objData[required]; !exists {
			errors = append(errors, ValidationError{
				Field:    sv.joinPath(path, required),
				Value:    "",
				Message:  fmt.Sprintf("required field '%s' is missing", required),
				Code:     "SCHEMA_REQUIRED_FIELD_MISSING",
				Severity: ValidationSeverityError,
			})
		}
	}
	
	// Validate properties
	for propName, propValue := range objData {
		propPath := sv.joinPath(path, propName)
		
		if propSchema, exists := schema.Properties[propName]; exists {
			propErrors := sv.validateAgainstSchema(propValue, propSchema, propPath)
			errors = append(errors, propErrors...)
		} else {
			// Handle additional properties
			if schema.AdditionalProperties == false {
				errors = append(errors, ValidationError{
					Field:    propPath,
					Value:    fmt.Sprintf("%v", propValue),
					Message:  fmt.Sprintf("additional property '%s' is not allowed", propName),
					Code:     "SCHEMA_ADDITIONAL_PROPERTY_NOT_ALLOWED",
					Severity: ValidationSeverityError,
				})
			}
		}
	}
	
	return errors
}

func (sv *SchemaValidator) validateString(data interface{}, schema *JSONSchema, path string) []ValidationError {
	var errors []ValidationError
	
	strData, ok := data.(string)
	if !ok {
		errors = append(errors, ValidationError{
			Field:    path,
			Value:    fmt.Sprintf("%v", data),
			Message:  "expected string, got " + fmt.Sprintf("%T", data),
			Code:     "SCHEMA_TYPE_MISMATCH",
			Severity: ValidationSeverityError,
		})
		return errors
	}
	
	// Validate enum values
	if len(schema.Enum) > 0 {
		validEnum := false
		for _, enumValue := range schema.Enum {
			if enumStr, ok := enumValue.(string); ok && enumStr == strData {
				validEnum = true
				break
			}
		}
		
		if !validEnum {
			errors = append(errors, ValidationError{
				Field:    path,
				Value:    strData,
				Message:  fmt.Sprintf("value '%s' is not in allowed enum values %v", strData, schema.Enum),
				Code:     "SCHEMA_ENUM_VALUE_INVALID",
				Severity: ValidationSeverityError,
			})
		}
	}
	
	// Validate pattern
	if schema.Pattern != "" {
		// Simple pattern validation (could be enhanced with regex)
		if !sv.matchesPattern(strData, schema.Pattern) {
			errors = append(errors, ValidationError{
				Field:    path,
				Value:    strData,
				Message:  fmt.Sprintf("value '%s' does not match required pattern '%s'", strData, schema.Pattern),
				Code:     "SCHEMA_PATTERN_MISMATCH",
				Severity: ValidationSeverityError,
			})
		}
	}
	
	// Validate length constraints
	if schema.MinLength != nil && len(strData) < *schema.MinLength {
		errors = append(errors, ValidationError{
			Field:    path,
			Value:    strData,
			Message:  fmt.Sprintf("string length %d is less than minimum %d", len(strData), *schema.MinLength),
			Code:     "SCHEMA_MIN_LENGTH_VIOLATION",
			Severity: ValidationSeverityError,
		})
	}
	
	if schema.MaxLength != nil && len(strData) > *schema.MaxLength {
		errors = append(errors, ValidationError{
			Field:    path,
			Value:    strData,
			Message:  fmt.Sprintf("string length %d exceeds maximum %d", len(strData), *schema.MaxLength),
			Code:     "SCHEMA_MAX_LENGTH_VIOLATION",
			Severity: ValidationSeverityError,
		})
	}
	
	// Validate numeric constraints for string numbers
	if schema.Minimum != nil || schema.Maximum != nil {
		if numValue, err := strconv.ParseFloat(strData, 64); err == nil {
			if schema.Minimum != nil && numValue < *schema.Minimum {
				errors = append(errors, ValidationError{
					Field:    path,
					Value:    strData,
					Message:  fmt.Sprintf("numeric value %f is less than minimum %f", numValue, *schema.Minimum),
					Code:     "SCHEMA_MIN_VALUE_VIOLATION",
					Severity: ValidationSeverityError,
				})
			}
			
			if schema.Maximum != nil && numValue > *schema.Maximum {
				errors = append(errors, ValidationError{
					Field:    path,
					Value:    strData,
					Message:  fmt.Sprintf("numeric value %f exceeds maximum %f", numValue, *schema.Maximum),
					Code:     "SCHEMA_MAX_VALUE_VIOLATION",
					Severity: ValidationSeverityError,
				})
			}
		}
	}
	
	return errors
}

func (sv *SchemaValidator) validateArray(data interface{}, schema *JSONSchema, path string) []ValidationError {
	var errors []ValidationError
	
	arrData, ok := data.([]interface{})
	if !ok {
		errors = append(errors, ValidationError{
			Field:    path,
			Value:    fmt.Sprintf("%v", data),
			Message:  "expected array, got " + fmt.Sprintf("%T", data),
			Code:     "SCHEMA_TYPE_MISMATCH",
			Severity: ValidationSeverityError,
		})
		return errors
	}
	
	// Validate array items
	if schema.Items != nil {
		for i, item := range arrData {
			itemPath := fmt.Sprintf("%s[%d]", path, i)
			itemErrors := sv.validateAgainstSchema(item, schema.Items, itemPath)
			errors = append(errors, itemErrors...)
		}
	}
	
	return errors
}

func (sv *SchemaValidator) validateSecurity(data map[string]interface{}) []ValidationError {
	var errors []ValidationError
	
	// Validate environment variables for security
	if envVars, ok := data["envVariables"].(map[string]interface{}); ok {
		for name, value := range envVars {
			if valueStr, ok := value.(string); ok {
				securityErrors := sv.securityValidator.ValidateEnvironmentVariableValue(name, valueStr)
				errors = append(errors, securityErrors...)
				
				// Additional schema-specific security checks
				if sv.isSystemVariable(name) {
					errors = append(errors, ValidationError{
						Field:    "envVariables." + name,
						Value:    valueStr,
						Message:  fmt.Sprintf("system environment variable '%s' is not allowed", name),
						Code:     "SCHEMA_SYSTEM_ENV_VAR_NOT_ALLOWED",
						Severity: ValidationSeverityCritical,
					})
				}
			}
		}
	}
	
	// Validate configuration values for security
	if settings, ok := data["settings"].(map[string]interface{}); ok {
		for key, value := range settings {
			if valueStr, ok := value.(string); ok {
				configKey, err := domain.NewConfigKey(key)
				if err == nil {
					configValue, err := domain.NewConfigValue(valueStr)
					if err == nil {
						securityErrors := sv.securityValidator.ValidateConfigValue(*configKey, *configValue)
						errors = append(errors, securityErrors...)
					}
				}
			}
		}
	}
	
	return errors
}

func (sv *SchemaValidator) matchesPattern(value, pattern string) bool {
	// Simple pattern matching for common cases
	switch pattern {
	case "^[1-9][0-9]*$":
		// Positive integer pattern
		if value == "" {
			return false
		}
		if value[0] == '0' && len(value) > 1 {
			return false
		}
		for _, r := range value {
			if r < '0' || r > '9' {
				return false
			}
		}
		return true
	case "^[0-9]+$":
		// Non-negative integer pattern
		if value == "" {
			return false
		}
		for _, r := range value {
			if r < '0' || r > '9' {
				return false
			}
		}
		return true
	default:
		// For complex patterns, assume they match (could be enhanced with regex library)
		return true
	}
}

func (sv *SchemaValidator) isSystemVariable(name string) bool {
	systemVars := []string{
		"PATH", "HOME", "USER", "SHELL", "PWD", "TERM", "LANG", "TZ",
		"PS1", "PS2", "IFS", "TMPDIR", "LOGNAME", "HOSTNAME",
	}
	
	for _, sysVar := range systemVars {
		if name == sysVar {
			return true
		}
	}
	
	return false
}

func (sv *SchemaValidator) joinPath(parent, child string) string {
	if parent == "" {
		return child
	}
	return parent + "." + child
}

// SchemaExporter provides functionality to export schemas in different formats
type SchemaExporter struct {
	validator *SchemaValidator
}

// NewSchemaExporter creates a new schema exporter
func NewSchemaExporter(validator *SchemaValidator) *SchemaExporter {
	return &SchemaExporter{validator: validator}
}

// ExportJSONSchema exports the configuration schema as JSON
func (se *SchemaExporter) ExportJSONSchema() ([]byte, error) {
	return json.MarshalIndent(se.validator.GetConfigurationSchema(), "", "  ")
}

// ExportOpenAPISchema exports the schema in OpenAPI format
func (se *SchemaExporter) ExportOpenAPISchema() map[string]interface{} {
	return map[string]interface{}{
		"openapi": "3.0.0",
		"info": map[string]interface{}{
			"title":   "Claude Configuration Schema",
			"version": "1.0.0",
		},
		"components": map[string]interface{}{
			"schemas": map[string]interface{}{
				"Configuration": se.validator.GetConfigurationSchema(),
				"Profile":       se.validator.GetProfileSchema(),
			},
		},
	}
}