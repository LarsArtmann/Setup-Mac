package domain

import (
	"fmt"
	"strings"
)

// Profile represents a configuration profile value object
type Profile struct {
	value string
}

// NewProfile creates a new Profile value object with validation
func NewProfile(value string) (*Profile, error) {
	// Normalize input
	normalized := strings.ToLower(strings.TrimSpace(value))
	
	// Validate profile value
	validProfiles := map[string]bool{
		"dev":         true,
		"development": true,
		"prod":        true,
		"production":  true,
		"personal":    true,
		"default":     true,
	}
	
	if !validProfiles[normalized] {
		return nil, fmt.Errorf("invalid profile '%s': must be one of dev, development, prod, production, personal, default", value)
	}
	
	return &Profile{value: normalized}, nil
}

// String returns the string representation of the profile
func (p Profile) String() string {
	return p.value
}

// Value returns the underlying value
func (p Profile) Value() string {
	return p.value
}

// IsEqual checks if two profiles are equal
func (p Profile) IsEqual(other Profile) bool {
	return p.value == other.value
}

// IsDevelopment checks if this is a development profile
func (p Profile) IsDevelopment() bool {
	return p.value == "dev" || p.value == "development"
}

// IsProduction checks if this is a production profile
func (p Profile) IsProduction() bool {
	return p.value == "prod" || p.value == "production"
}

// IsPersonal checks if this is a personal profile
func (p Profile) IsPersonal() bool {
	return p.value == "personal" || p.value == "default"
}

// ConfigKey represents a configuration key value object
type ConfigKey struct {
	value string
}

// NewConfigKey creates a new ConfigKey value object with validation
func NewConfigKey(value string) (*ConfigKey, error) {
	// Validate key is not empty
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil, fmt.Errorf("config key cannot be empty")
	}
	
	// Validate key format (alphanumeric + underscores only)
	for _, char := range trimmed {
		if !((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9') || char == '_') {
			return nil, fmt.Errorf("invalid config key '%s': only alphanumeric characters and underscores allowed", value)
		}
	}
	
	return &ConfigKey{value: trimmed}, nil
}

// String returns the string representation of the config key
func (k ConfigKey) String() string {
	return k.value
}

// Value returns the underlying value
func (k ConfigKey) Value() string {
	return k.value
}

// IsEqual checks if two config keys are equal
func (k ConfigKey) IsEqual(other ConfigKey) bool {
	return k.value == other.value
}

// ConfigValue represents a configuration value object
type ConfigValue struct {
	value string
}

// NewConfigValue creates a new ConfigValue value object with validation
func NewConfigValue(value string) (*ConfigValue, error) {
	// Config values can be empty strings, but not nil
	// We just need to ensure the value is properly handled
	return &ConfigValue{value: value}, nil
}

// String returns the string representation of the config value
func (v ConfigValue) String() string {
	return v.value
}

// Value returns the underlying value
func (v ConfigValue) Value() string {
	return v.value
}

// IsEqual checks if two config values are equal
func (v ConfigValue) IsEqual(other ConfigValue) bool {
	return v.value == other.value
}

// IsEmpty checks if the config value is empty
func (v ConfigValue) IsEmpty() bool {
	return strings.TrimSpace(v.value) == ""
}

// Predefined configuration keys as constants
var (
	ConfigKeyTheme                        = mustCreateConfigKey("theme")
	ConfigKeyParallelTasksCount          = mustCreateConfigKey("parallelTasksCount")
	ConfigKeyPreferredNotifChannel       = mustCreateConfigKey("preferredNotifChannel")
	ConfigKeyMessageIdleNotifThresholdMs = mustCreateConfigKey("messageIdleNotifThresholdMs")
	ConfigKeyAutoUpdates                 = mustCreateConfigKey("autoUpdates")
	ConfigKeyDiffTool                    = mustCreateConfigKey("diffTool")
)

// mustCreateConfigKey creates a config key or panics (for constants)
func mustCreateConfigKey(value string) ConfigKey {
	key, err := NewConfigKey(value)
	if err != nil {
		panic(fmt.Sprintf("invalid predefined config key: %v", err))
	}
	return *key
}

// Predefined profiles as constants
var (
	ProfileDev         = mustCreateProfile("dev")
	ProfileDevelopment = mustCreateProfile("development")
	ProfileProd        = mustCreateProfile("prod")
	ProfileProduction  = mustCreateProfile("production")
	ProfilePersonal    = mustCreateProfile("personal")
	ProfileDefault     = mustCreateProfile("default")
)

// mustCreateProfile creates a profile or panics (for constants)
func mustCreateProfile(value string) Profile {
	profile, err := NewProfile(value)
	if err != nil {
		panic(fmt.Sprintf("invalid predefined profile: %v", err))
	}
	return *profile
}