package main

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strings"
)

// SchemaValidator provides JSON schema-like validation for configuration
type SchemaValidator struct {
	schema map[string]interface{}
}

// ConfigSchema defines the validation schema for Config struct
var ConfigSchema = map[string]interface{}{
	"type": "object",
	"properties": map[string]interface{}{
		"theme": map[string]interface{}{
			"type":      "string",
			"minLength": 1,
			"enum":      []string{"dark-daltonized", "light", "dark", "auto"},
		},
		"parallelTasksCount": map[string]interface{}{
			"type":    "string",
			"pattern": "^[1-9][0-9]*$",
			"minimum": 1,
			"maximum": 1000,
		},
		"preferredNotifChannel": map[string]interface{}{
			"type": "string",
			"enum": []string{"iterm2_with_bell", "desktop", "none"},
		},
		"messageIdleNotifThresholdMs": map[string]interface{}{
			"type":    "string",
			"pattern": "^[0-9]+$",
			"minimum": 0,
			"maximum": 60000,
		},
		"autoUpdates": map[string]interface{}{
			"type": "string",
			"enum": []string{"true", "false"},
		},
		"diffTool": map[string]interface{}{
			"type": "string",
			"enum": []string{"bat", "diff", "delta", "code"},
		},
		"env": map[string]interface{}{
			"type": "object",
			"patternProperties": map[string]interface{}{
				"^[A-Z_][A-Z0-9_]*$": map[string]interface{}{
					"type": "string",
				},
			},
			"additionalProperties": false,
		},
	},
	"required": []string{"theme"},
}

// ProfileConfigSchema defines the validation schema for ProfileConfig struct
var ProfileConfigSchema = map[string]interface{}{
	"type": "object",
	"properties": map[string]interface{}{
		"profile": map[string]interface{}{
			"type": "string",
			"enum": []string{"dev", "development", "prod", "production", "personal", "default"},
		},
		"config": ConfigSchema,
		"envVars": map[string]interface{}{
			"type": "object",
			"patternProperties": map[string]interface{}{
				"^[A-Z_][A-Z0-9_]*$": map[string]interface{}{
					"type": "string",
				},
			},
		},
	},
	"required": []string{"profile", "config"},
}

// ApplicationOptionsSchema defines the validation schema for ApplicationOptions struct
var ApplicationOptionsSchema = map[string]interface{}{
	"type": "object",
	"properties": map[string]interface{}{
		"dryRun": map[string]interface{}{
			"type": "boolean",
		},
		"createBackup": map[string]interface{}{
			"type": "boolean",
		},
		"profile": map[string]interface{}{
			"type": "string",
			"enum": []string{"dev", "development", "prod", "production", "personal", "default"},
		},
		"help": map[string]interface{}{
			"type": "boolean",
		},
		"forwardArgs": map[string]interface{}{
			"type": "array",
			"items": map[string]interface{}{
				"type":    "string",
				"pattern": "^[^;&|]*$", // No shell metacharacters
			},
		},
	},
}

// NewSchemaValidator creates a new schema validator
func NewSchemaValidator(schema map[string]interface{}) *SchemaValidator {
	return &SchemaValidator{schema: schema}
}

// ValidateConfig validates a Config struct against the schema
func (v *SchemaValidator) ValidateConfig(config Config) ValidationErrors {
	var errors ValidationErrors

	// Convert struct to map for validation
	configMap := structToMap(config)

	// Validate against schema
	schemaErrors := v.validateValue("", configMap, v.schema)
	errors = append(errors, schemaErrors...)

	return errors
}

// ValidateProfileConfig validates a ProfileConfig struct against the schema
func (v *SchemaValidator) ValidateProfileConfig(profileConfig ProfileConfig) ValidationErrors {
	var errors ValidationErrors

	// Convert struct to map for validation
	profileMap := structToMap(profileConfig)

	// Validate against schema
	schemaErrors := v.validateValue("", profileMap, ProfileConfigSchema)
	errors = append(errors, schemaErrors...)

	return errors
}

// ValidateApplicationOptions validates ApplicationOptions against the schema
func (v *SchemaValidator) ValidateApplicationOptions(options ApplicationOptions) ValidationErrors {
	var errors ValidationErrors

	// Convert struct to map for validation
	optionsMap := structToMap(options)

	// Validate against schema
	schemaErrors := v.validateValue("", optionsMap, ApplicationOptionsSchema)
	errors = append(errors, schemaErrors...)

	return errors
}

// validateValue recursively validates a value against a schema
func (v *SchemaValidator) validateValue(path string, value interface{}, schema interface{}) ValidationErrors {
	var errors ValidationErrors

	schemaMap, ok := schema.(map[string]interface{})
	if !ok {
		return errors
	}

	// Check type
	if expectedType, exists := schemaMap["type"]; exists {
		typeStr, ok := expectedType.(string)
		if ok {
			if !v.validateType(value, typeStr) {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("expected type %s", typeStr),
				})
				return errors // Stop validation on type mismatch
			}
		}
	}

	// Check enum values
	if enumValues, exists := schemaMap["enum"]; exists {
		if enumSlice, ok := enumValues.([]string); ok {
			if !v.validateEnum(value, enumSlice) {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("must be one of: %s", strings.Join(enumSlice, ", ")),
				})
			}
		}
	}

	// Check string constraints
	if strValue, ok := value.(string); ok {
		errors = append(errors, v.validateString(path, strValue, schemaMap)...)
	}

	// Check numeric constraints
	if numValue, ok := value.(float64); ok {
		errors = append(errors, v.validateNumber(path, numValue, schemaMap)...)
	}

	// Check object properties
	if objValue, ok := value.(map[string]interface{}); ok {
		errors = append(errors, v.validateObject(path, objValue, schemaMap)...)
	}

	// Check array items
	if arrValue, ok := value.([]interface{}); ok {
		errors = append(errors, v.validateArray(path, arrValue, schemaMap)...)
	}

	return errors
}

// validateType checks if value matches expected type
func (v *SchemaValidator) validateType(value interface{}, expectedType string) bool {
	switch expectedType {
	case "string":
		_, ok := value.(string)
		return ok
	case "number":
		_, ok := value.(float64)
		if !ok {
			_, ok = value.(int)
		}
		return ok
	case "boolean":
		_, ok := value.(bool)
		return ok
	case "object":
		_, ok := value.(map[string]interface{})
		return ok
	case "array":
		_, ok := value.([]interface{})
		return ok
	case "null":
		return value == nil
	default:
		return false
	}
}

// validateEnum checks if value is in allowed enum values
func (v *SchemaValidator) validateEnum(value interface{}, enumValues []string) bool {
	strValue, ok := value.(string)
	if !ok {
		return false
	}

	for _, enumValue := range enumValues {
		if strValue == enumValue {
			return true
		}
	}

	return false
}

// validateString validates string constraints
func (v *SchemaValidator) validateString(path, value string, schema map[string]interface{}) ValidationErrors {
	var errors ValidationErrors

	// Check minLength
	if minLength, exists := schema["minLength"]; exists {
		if minLen, ok := minLength.(int); ok {
			if len(value) < minLen {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("minimum length is %d", minLen),
				})
			}
		}
	}

	// Check maxLength
	if maxLength, exists := schema["maxLength"]; exists {
		if maxLen, ok := maxLength.(int); ok {
			if len(value) > maxLen {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("maximum length is %d", maxLen),
				})
			}
		}
	}

	// Check pattern (basic regex)
	if pattern, exists := schema["pattern"]; exists {
		if patternStr, ok := pattern.(string); ok {
			// Simple pattern matching for common cases
			if !v.matchesPattern(value, patternStr) {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("does not match pattern %s", patternStr),
				})
			}
		}
	}

	return errors
}

// validateNumber validates numeric constraints
func (v *SchemaValidator) validateNumber(path string, value float64, schema map[string]interface{}) ValidationErrors {
	var errors ValidationErrors

	// Check minimum
	if minimum, exists := schema["minimum"]; exists {
		if min, ok := minimum.(float64); ok {
			if value < min {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("minimum value is %v", min),
				})
			}
		} else if min, ok := minimum.(int); ok {
			if value < float64(min) {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("minimum value is %d", min),
				})
			}
		}
	}

	// Check maximum
	if maximum, exists := schema["maximum"]; exists {
		if max, ok := maximum.(float64); ok {
			if value > max {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("maximum value is %v", max),
				})
			}
		} else if max, ok := maximum.(int); ok {
			if value > float64(max) {
				errors = append(errors, ValidationError{
					Field:   path,
					Value:   value,
					Message: fmt.Sprintf("maximum value is %d", max),
				})
			}
		}
	}

	return errors
}

// validateObject validates object properties
func (v *SchemaValidator) validateObject(path string, value map[string]interface{}, schema map[string]interface{}) ValidationErrors {
	var errors ValidationErrors

	// Check required properties
	if required, exists := schema["required"]; exists {
		if requiredSlice, ok := required.([]string); ok {
			for _, requiredProp := range requiredSlice {
				if _, exists := value[requiredProp]; !exists {
					fieldPath := path
					if fieldPath != "" {
						fieldPath += "."
					}
					fieldPath += requiredProp

					errors = append(errors, ValidationError{
						Field:   fieldPath,
						Value:   nil,
						Message: "required property is missing",
					})
				}
			}
		}
	}

	// Check properties
	if properties, exists := schema["properties"]; exists {
		if propsMap, ok := properties.(map[string]interface{}); ok {
			for propName, propValue := range value {
				fieldPath := path
				if fieldPath != "" {
					fieldPath += "."
				}
				fieldPath += propName

				if propSchema, exists := propsMap[propName]; exists {
					propErrors := v.validateValue(fieldPath, propValue, propSchema)
					errors = append(errors, propErrors...)
				}
			}
		}
	}

	return errors
}

// validateArray validates array items
func (v *SchemaValidator) validateArray(path string, value []interface{}, schema map[string]interface{}) ValidationErrors {
	var errors ValidationErrors

	// Check items schema
	if items, exists := schema["items"]; exists {
		for i, item := range value {
			itemPath := fmt.Sprintf("%s[%d]", path, i)
			itemErrors := v.validateValue(itemPath, item, items)
			errors = append(errors, itemErrors...)
		}
	}

	return errors
}

// matchesPattern provides basic pattern matching
func (v *SchemaValidator) matchesPattern(value, pattern string) bool {
	switch pattern {
	case "^[1-9][0-9]*$":
		// Positive integer pattern
		if value == "" {
			return false
		}
		for i, char := range value {
			if i == 0 && char < '1' || char > '9' {
				return false
			}
			if i > 0 && (char < '0' || char > '9') {
				return false
			}
		}
		return true

	case "^[0-9]+$":
		// Non-negative integer pattern
		if value == "" {
			return false
		}
		for _, char := range value {
			if char < '0' || char > '9' {
				return false
			}
		}
		return true

	case "^[A-Z_][A-Z0-9_]*$":
		// Environment variable name pattern
		if value == "" {
			return false
		}
		for i, char := range value {
			if i == 0 {
				if !((char >= 'A' && char <= 'Z') || char == '_') {
					return false
				}
			} else {
				if !((char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9') || char == '_') {
					return false
				}
			}
		}
		return true

	case "^[^;&|]*$":
		// No shell metacharacters pattern
		for _, char := range value {
			if char == ';' || char == '&' || char == '|' {
				return false
			}
		}
		return true

	default:
		// For unknown patterns, assume they match
		return true
	}
}

// structToMap converts a struct to a map using JSON marshaling/unmarshaling
func structToMap(obj interface{}) map[string]interface{} {
	result := make(map[string]interface{})

	// Use reflection to handle struct conversion
	value := reflect.ValueOf(obj)
	if value.Kind() == reflect.Ptr {
		value = value.Elem()
	}

	if value.Kind() != reflect.Struct {
		return result
	}

	valueType := value.Type()
	for i := 0; i < value.NumField(); i++ {
		field := valueType.Field(i)
		fieldValue := value.Field(i)

		// Get JSON tag name or use field name
		jsonTag := field.Tag.Get("json")
		fieldName := field.Name
		if jsonTag != "" && jsonTag != "-" {
			if commaIndex := strings.Index(jsonTag, ","); commaIndex != -1 {
				fieldName = jsonTag[:commaIndex]
			} else {
				fieldName = jsonTag
			}
		}

		// Convert field value to interface{}
		if fieldValue.IsValid() && fieldValue.CanInterface() {
			result[fieldName] = fieldValue.Interface()
		}
	}

	return result
}

// ValidateJSON validates a JSON string against a schema
func ValidateJSON(jsonStr string, schema map[string]interface{}) ValidationErrors {
	var errors ValidationErrors
	var value interface{}

	// Parse JSON
	if err := json.Unmarshal([]byte(jsonStr), &value); err != nil {
		errors = append(errors, ValidationError{
			Field:   "json",
			Value:   jsonStr,
			Message: fmt.Sprintf("invalid JSON: %v", err),
		})
		return errors
	}

	// Validate against schema
	validator := NewSchemaValidator(schema)
	schemaErrors := validator.validateValue("", value, schema)
	errors = append(errors, schemaErrors...)

	return errors
}
