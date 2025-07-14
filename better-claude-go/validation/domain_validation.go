package validation

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"

	"better-claude/domain"
)

// ValidationError represents a validation error with detailed information
type ValidationError struct {
	Field    string
	Value    string
	Message  string
	Code     string
	Severity ValidationSeverity
}

// ValidationSeverity represents the severity level of validation errors
type ValidationSeverity int

const (
	ValidationSeverityInfo ValidationSeverity = iota
	ValidationSeverityWarning
	ValidationSeverityError
	ValidationSeverityCritical
)

// String returns the string representation of validation severity
func (s ValidationSeverity) String() string {
	switch s {
	case ValidationSeverityInfo:
		return "info"
	case ValidationSeverityWarning:
		return "warning"
	case ValidationSeverityError:
		return "error"
	case ValidationSeverityCritical:
		return "critical"
	default:
		return "unknown"
	}
}

// DomainValidator provides comprehensive domain validation
type DomainValidator struct {
	securityValidator *SecurityValidator
	performanceRules  *PerformanceRuleValidator
	businessRules     *BusinessRuleValidator
}

// NewDomainValidator creates a new domain validator
func NewDomainValidator() *DomainValidator {
	return &DomainValidator{
		securityValidator: NewSecurityValidator(),
		performanceRules:  NewPerformanceRuleValidator(),
		businessRules:     NewBusinessRuleValidator(),
	}
}

// ValidateProfile validates a profile according to domain rules
func (v *DomainValidator) ValidateProfile(profile domain.Profile) []ValidationError {
	var errors []ValidationError

	// Profile value should not be empty
	if profile.Value() == "" {
		errors = append(errors, ValidationError{
			Field:    "profile",
			Value:    profile.Value(),
			Message:  "profile cannot be empty",
			Code:     "PROFILE_EMPTY",
			Severity: ValidationSeverityError,
		})
	}

	// Check if profile is in valid list
	validProfiles := []string{"dev", "development", "prod", "production", "personal", "default"}
	isValid := false
	for _, validProfile := range validProfiles {
		if profile.Value() == validProfile {
			isValid = true
			break
		}
	}

	if !isValid {
		errors = append(errors, ValidationError{
			Field:    "profile",
			Value:    profile.Value(),
			Message:  fmt.Sprintf("invalid profile '%s': must be one of %v", profile.Value(), validProfiles),
			Code:     "PROFILE_INVALID",
			Severity: ValidationSeverityError,
		})
	}

	return errors
}

// ValidateProfileTransition validates profile transitions
func (v *DomainValidator) ValidateProfileTransition(from, to domain.Profile) error {
	if from.IsEqual(to) {
		return fmt.Errorf("cannot transition to the same profile")
	}

	// Business rule: Direct production to development transitions might need confirmation
	if from.IsProduction() && to.IsDevelopment() {
		return fmt.Errorf("direct transition from production to development profile requires confirmation")
	}

	return nil
}

// ValidateConfigValue validates a configuration value according to its key
func (v *DomainValidator) ValidateConfigValue(key domain.ConfigKey, value domain.ConfigValue) []ValidationError {
	var errors []ValidationError

	// Security validation first
	securityErrors := v.securityValidator.ValidateConfigValue(key, value)
	errors = append(errors, securityErrors...)

	// Key-specific validation
	switch key {
	case domain.ConfigKeyTheme:
		errors = append(errors, v.validateTheme(value)...)
	case domain.ConfigKeyParallelTasksCount:
		errors = append(errors, v.validateParallelTasksCount(value)...)
	case domain.ConfigKeyMessageIdleNotifThresholdMs:
		errors = append(errors, v.validateMessageIdleThreshold(value)...)
	case domain.ConfigKeyAutoUpdates:
		errors = append(errors, v.validateAutoUpdates(value)...)
	case domain.ConfigKeyPreferredNotifChannel:
		errors = append(errors, v.validateNotificationChannel(value)...)
	case domain.ConfigKeyDiffTool:
		errors = append(errors, v.validateDiffTool(value)...)
	}

	return errors
}

// ValidateConfiguration validates a complete configuration
func (v *DomainValidator) ValidateConfiguration(config *domain.Configuration) []ValidationError {
	var errors []ValidationError

	// Validate profile
	profileErrors := v.ValidateProfile(config.Profile())
	errors = append(errors, profileErrors...)

	// Validate all settings
	for key, value := range config.Settings() {
		settingErrors := v.ValidateConfigValue(key, value)
		errors = append(errors, settingErrors...)
	}

	// Validate environment variables
	for name, value := range config.EnvVariables() {
		envErrors := v.ValidateEnvironmentVariable(name, value)
		errors = append(errors, envErrors...)
	}

	// Business rule validation
	businessErrors := v.businessRules.ValidateConfiguration(config)
	errors = append(errors, businessErrors...)

	return errors
}

// ValidateBusinessInvariants validates business invariants
func (v *DomainValidator) ValidateBusinessInvariants(config *domain.Configuration) []ValidationError {
	return v.businessRules.ValidateInvariants(config)
}

// ValidateProfileSpecificRules validates profile-specific rules
func (v *DomainValidator) ValidateProfileSpecificRules(config *domain.Configuration) []ValidationError {
	return v.businessRules.ValidateProfileSpecificRules(config)
}

// ValidateProfileConsistency validates profile consistency
func (v *DomainValidator) ValidateProfileConsistency(config *domain.Configuration) []ValidationError {
	return v.businessRules.ValidateProfileConsistency(config)
}

// ValidatePerformanceRules validates performance-related rules
func (v *DomainValidator) ValidatePerformanceRules(config *domain.Configuration) []ValidationError {
	return v.performanceRules.ValidateConfiguration(config)
}

// ValidateEnvironmentVariable validates environment variables
func (v *DomainValidator) ValidateEnvironmentVariable(name, value string) []ValidationError {
	var errors []ValidationError

	// Name cannot be empty
	if name == "" {
		errors = append(errors, ValidationError{
			Field:    "environment_variable_name",
			Value:    name,
			Message:  "environment variable name cannot be empty",
			Code:     "ENV_VAR_NAME_EMPTY",
			Severity: ValidationSeverityError,
		})
		return errors
	}

	// Check for system variables that should not be modified
	systemVars := []string{
		"PATH", "HOME", "USER", "SHELL", "PWD", "TERM", "LANG", "TZ",
		"PS1", "PS2", "IFS", "TMPDIR", "LOGNAME", "HOSTNAME",
	}
	for _, sysVar := range systemVars {
		if name == sysVar {
			errors = append(errors, ValidationError{
				Field:    "environment_variable_name",
				Value:    name,
				Message:  fmt.Sprintf("system environment variable '%s' is not allowed", name),
				Code:     "ENV_VAR_SYSTEM_PROTECTED",
				Severity: ValidationSeverityError,
			})
		}
	}

	// Validate variable name format (must be uppercase with underscores and numbers)
	validName := regexp.MustCompile(`^[A-Z][A-Z0-9_]*$`)
	if !validName.MatchString(name) {
		errors = append(errors, ValidationError{
			Field:    "environment_variable_name",
			Value:    name,
			Message:  fmt.Sprintf("invalid environment variable name '%s': must start with uppercase letter and contain only uppercase letters, numbers, and underscores", name),
			Code:     "ENV_VAR_NAME_INVALID",
			Severity: ValidationSeverityError,
		})
	}

	// Security validation for value
	securityErrors := v.securityValidator.ValidateEnvironmentVariableValue(name, value)
	errors = append(errors, securityErrors...)

	return errors
}

// ValidatePathInput validates path inputs for security
func (v *DomainValidator) ValidatePathInput(path string) []ValidationError {
	return v.securityValidator.ValidatePathInput(path)
}

// ValidateCommandInput validates command inputs for security
func (v *DomainValidator) ValidateCommandInput(input string) []ValidationError {
	return v.securityValidator.ValidateCommandInput(input)
}

// ValidateAll performs comprehensive validation
func (v *DomainValidator) ValidateAll(config *domain.Configuration) []ValidationError {
	var allErrors []ValidationError

	// Basic configuration validation
	configErrors := v.ValidateConfiguration(config)
	allErrors = append(allErrors, configErrors...)

	// Business invariants
	invariantErrors := v.ValidateBusinessInvariants(config)
	allErrors = append(allErrors, invariantErrors...)

	// Profile-specific rules
	profileErrors := v.ValidateProfileSpecificRules(config)
	allErrors = append(allErrors, profileErrors...)

	// Performance rules
	performanceErrors := v.ValidatePerformanceRules(config)
	allErrors = append(allErrors, performanceErrors...)

	// Profile consistency
	consistencyErrors := v.ValidateProfileConsistency(config)
	allErrors = append(allErrors, consistencyErrors...)

	return allErrors
}

// Private validation methods

func (v *DomainValidator) validateTheme(value domain.ConfigValue) []ValidationError {
	var errors []ValidationError

	if value.IsEmpty() {
		errors = append(errors, ValidationError{
			Field:    "theme",
			Value:    value.Value(),
			Message:  "theme cannot be empty",
			Code:     "THEME_EMPTY",
			Severity: ValidationSeverityError,
		})
		return errors
	}

	validThemes := []string{"dark", "light", "dark-daltonized", "auto"}
	for _, validTheme := range validThemes {
		if value.Value() == validTheme {
			return errors
		}
	}

	errors = append(errors, ValidationError{
		Field:    "theme",
		Value:    value.Value(),
		Message:  fmt.Sprintf("invalid theme '%s': must be one of %v", value.Value(), validThemes),
		Code:     "THEME_INVALID",
		Severity: ValidationSeverityError,
	})

	return errors
}

func (v *DomainValidator) validateParallelTasksCount(value domain.ConfigValue) []ValidationError {
	var errors []ValidationError

	if value.IsEmpty() {
		errors = append(errors, ValidationError{
			Field:    "parallelTasksCount",
			Value:    value.Value(),
			Message:  "parallel tasks count cannot be empty",
			Code:     "PARALLEL_TASKS_EMPTY",
			Severity: ValidationSeverityError,
		})
		return errors
	}

	count, err := strconv.Atoi(value.Value())
	if err != nil {
		errors = append(errors, ValidationError{
			Field:    "parallelTasksCount",
			Value:    value.Value(),
			Message:  "parallel tasks count must be a valid number",
			Code:     "PARALLEL_TASKS_NOT_NUMBER",
			Severity: ValidationSeverityError,
		})
		return errors
	}

	if count < 1 || count > 1000 {
		errors = append(errors, ValidationError{
			Field:    "parallelTasksCount",
			Value:    value.Value(),
			Message:  "parallel tasks count must be between 1 and 1000",
			Code:     "PARALLEL_TASKS_OUT_OF_RANGE",
			Severity: ValidationSeverityError,
		})
	}

	return errors
}

func (v *DomainValidator) validateMessageIdleThreshold(value domain.ConfigValue) []ValidationError {
	var errors []ValidationError

	if value.IsEmpty() {
		errors = append(errors, ValidationError{
			Field:    "messageIdleNotifThresholdMs",
			Value:    value.Value(),
			Message:  "message idle notification threshold cannot be empty",
			Code:     "MESSAGE_THRESHOLD_EMPTY",
			Severity: ValidationSeverityError,
		})
		return errors
	}

	threshold, err := strconv.Atoi(value.Value())
	if err != nil {
		errors = append(errors, ValidationError{
			Field:    "messageIdleNotifThresholdMs",
			Value:    value.Value(),
			Message:  "message idle threshold must be a valid number",
			Code:     "MESSAGE_THRESHOLD_NOT_NUMBER",
			Severity: ValidationSeverityError,
		})
		return errors
	}

	if threshold < 0 || threshold > 60000 {
		errors = append(errors, ValidationError{
			Field:    "messageIdleNotifThresholdMs",
			Value:    value.Value(),
			Message:  "message idle threshold must be between 0 and 60000 milliseconds",
			Code:     "MESSAGE_THRESHOLD_OUT_OF_RANGE",
			Severity: ValidationSeverityError,
		})
	}

	return errors
}

func (v *DomainValidator) validateAutoUpdates(value domain.ConfigValue) []ValidationError {
	var errors []ValidationError

	if value.Value() != "true" && value.Value() != "false" {
		errors = append(errors, ValidationError{
			Field:    "autoUpdates",
			Value:    value.Value(),
			Message:  "auto updates must be 'true' or 'false'",
			Code:     "AUTO_UPDATES_INVALID",
			Severity: ValidationSeverityError,
		})
	}

	return errors
}

func (v *DomainValidator) validateNotificationChannel(value domain.ConfigValue) []ValidationError {
	var errors []ValidationError

	if value.IsEmpty() {
		errors = append(errors, ValidationError{
			Field:    "preferredNotifChannel",
			Value:    value.Value(),
			Message:  "preferred notification channel cannot be empty",
			Code:     "NOTIF_CHANNEL_EMPTY",
			Severity: ValidationSeverityError,
		})
		return errors
	}

	validChannels := []string{"none", "iterm2", "iterm2_with_bell", "system"}
	for _, validChannel := range validChannels {
		if value.Value() == validChannel {
			return errors
		}
	}

	errors = append(errors, ValidationError{
		Field:    "preferredNotifChannel",
		Value:    value.Value(),
		Message:  fmt.Sprintf("invalid notification channel '%s': must be one of %v", value.Value(), validChannels),
		Code:     "NOTIF_CHANNEL_INVALID",
		Severity: ValidationSeverityError,
	})

	return errors
}

func (v *DomainValidator) validateDiffTool(value domain.ConfigValue) []ValidationError {
	var errors []ValidationError

	if value.IsEmpty() {
		errors = append(errors, ValidationError{
			Field:    "diffTool",
			Value:    value.Value(),
			Message:  "diff tool cannot be empty",
			Code:     "DIFF_TOOL_EMPTY",
			Severity: ValidationSeverityError,
		})
		return errors
	}

	validTools := []string{"bat", "diff", "code", "nano", "vim"}
	for _, validTool := range validTools {
		if value.Value() == validTool {
			return errors
		}
	}

	errors = append(errors, ValidationError{
		Field:    "diffTool",
		Value:    value.Value(),
		Message:  fmt.Sprintf("invalid diff tool '%s': must be one of %v", value.Value(), validTools),
		Code:     "DIFF_TOOL_INVALID",
		Severity: ValidationSeverityError,
	})

	return errors
}

// SecurityValidator handles security-related validation
type SecurityValidator struct {
	maliciousPatterns []*regexp.Regexp
}

// NewSecurityValidator creates a new security validator
func NewSecurityValidator() *SecurityValidator {
	// Compile malicious patterns
	patterns := []*regexp.Regexp{
		regexp.MustCompile(`<script[^>]*>.*?</script>`), // XSS
		regexp.MustCompile(`javascript:`),               // JavaScript protocol
		regexp.MustCompile(`data:.*script`),             // Data URLs with script
		regexp.MustCompile(`[;&|` + "`" + `]`),          // Command injection characters
		regexp.MustCompile(`\$\{.*?\}`),                 // Template injection
		regexp.MustCompile(`\{\{.*?\}\}`),               // Template injection
		regexp.MustCompile(`\.\./`),                     // Path traversal
		regexp.MustCompile(`\\\.\.\\`),                  // Windows path traversal
		regexp.MustCompile(`\x00`),                      // Null bytes
	}

	return &SecurityValidator{
		maliciousPatterns: patterns,
	}
}

// ValidateConfigValue validates config values for security threats
func (sv *SecurityValidator) ValidateConfigValue(key domain.ConfigKey, value domain.ConfigValue) []ValidationError {
	var errors []ValidationError

	// Check for malicious patterns
	for _, pattern := range sv.maliciousPatterns {
		if pattern.MatchString(value.Value()) {
			errors = append(errors, ValidationError{
				Field:    key.Value(),
				Value:    value.Value(),
				Message:  "potentially malicious content detected",
				Code:     "SECURITY_MALICIOUS_CONTENT",
				Severity: ValidationSeverityCritical,
			})
			break
		}
	}

	// Check for suspicious file paths
	if strings.Contains(value.Value(), "..") {
		errors = append(errors, ValidationError{
			Field:    key.Value(),
			Value:    value.Value(),
			Message:  "path traversal attempt detected",
			Code:     "SECURITY_PATH_TRAVERSAL",
			Severity: ValidationSeverityCritical,
		})
	}

	return errors
}

// ValidateEnvironmentVariableValue validates environment variable values for security
func (sv *SecurityValidator) ValidateEnvironmentVariableValue(name, value string) []ValidationError {
	var errors []ValidationError

	// Check for malicious patterns in environment variables
	for _, pattern := range sv.maliciousPatterns {
		if pattern.MatchString(value) {
			errors = append(errors, ValidationError{
				Field:    "environment_variable_value",
				Value:    name + "=" + value,
				Message:  "potentially malicious content detected in environment variable",
				Code:     "SECURITY_MALICIOUS_ENV_VAR",
				Severity: ValidationSeverityCritical,
			})
			break
		}
	}

	return errors
}

// ValidatePathInput validates path inputs for security
func (sv *SecurityValidator) ValidatePathInput(path string) []ValidationError {
	var errors []ValidationError

	// Check for path traversal
	if strings.Contains(path, "..") {
		errors = append(errors, ValidationError{
			Field:    "path",
			Value:    path,
			Message:  "path traversal attempt detected",
			Code:     "SECURITY_PATH_TRAVERSAL",
			Severity: ValidationSeverityCritical,
		})
	}

	// Check for UNC paths
	if strings.HasPrefix(path, "\\\\") {
		errors = append(errors, ValidationError{
			Field:    "path",
			Value:    path,
			Message:  "UNC paths are not allowed",
			Code:     "SECURITY_UNC_PATH",
			Severity: ValidationSeverityCritical,
		})
	}

	// Check for file:// URLs that access system paths
	if strings.HasPrefix(path, "file://") {
		// Extract the path part and check if it's a system path
		urlPath := strings.TrimPrefix(path, "file://")
		systemPaths := []string{"/etc/", "/proc/", "/sys/", "/dev/", "C:\\Windows\\", "C:\\Program Files\\"}
		for _, sysPath := range systemPaths {
			if strings.HasPrefix(urlPath, sysPath) {
				errors = append(errors, ValidationError{
					Field:    "path",
					Value:    path,
					Message:  "access to system directory not allowed",
					Code:     "SECURITY_SYSTEM_PATH_ACCESS",
					Severity: ValidationSeverityCritical,
				})
				break
			}
		}
	}

	// Check for absolute paths to system directories
	systemPaths := []string{"/etc/", "/proc/", "/sys/", "/dev/", "C:\\Windows\\", "C:\\Program Files\\"}
	for _, sysPath := range systemPaths {
		if strings.HasPrefix(path, sysPath) {
			errors = append(errors, ValidationError{
				Field:    "path",
				Value:    path,
				Message:  "access to system directory not allowed",
				Code:     "SECURITY_SYSTEM_PATH_ACCESS",
				Severity: ValidationSeverityCritical,
			})
		}
	}

	return errors
}

// ValidateCommandInput validates command inputs for security
func (sv *SecurityValidator) ValidateCommandInput(input string) []ValidationError {
	var errors []ValidationError

	// Check for command injection patterns
	injectionPatterns := []string{";", "|", "&", "`", "$", "\n", "\r"}
	for _, pattern := range injectionPatterns {
		if strings.Contains(input, pattern) {
			errors = append(errors, ValidationError{
				Field:    "command_input",
				Value:    input,
				Message:  "command injection attempt detected",
				Code:     "SECURITY_COMMAND_INJECTION",
				Severity: ValidationSeverityCritical,
			})
			break
		}
	}

	return errors
}

// PerformanceRuleValidator validates performance-related rules
type PerformanceRuleValidator struct{}

// NewPerformanceRuleValidator creates a new performance rule validator
func NewPerformanceRuleValidator() *PerformanceRuleValidator {
	return &PerformanceRuleValidator{}
}

// ValidateConfiguration validates performance aspects of configuration
func (prv *PerformanceRuleValidator) ValidateConfiguration(config *domain.Configuration) []ValidationError {
	var errors []ValidationError

	// Check parallel tasks count vs profile
	if parallelTasks, exists := config.GetSetting(domain.ConfigKeyParallelTasksCount); exists {
		if count, err := strconv.Atoi(parallelTasks.Value()); err == nil {
			if config.Profile().IsProduction() && count > 50 {
				errors = append(errors, ValidationError{
					Field:    "parallelTasksCount",
					Value:    parallelTasks.Value(),
					Message:  "high parallel tasks count may impact production performance",
					Code:     "PERFORMANCE_HIGH_PARALLEL_TASKS",
					Severity: ValidationSeverityWarning,
				})
			}
		}
	}

	return errors
}

// BusinessRuleValidator validates business rules and invariants
type BusinessRuleValidator struct{}

// NewBusinessRuleValidator creates a new business rule validator
func NewBusinessRuleValidator() *BusinessRuleValidator {
	return &BusinessRuleValidator{}
}

// ValidateConfiguration validates business rules for configuration
func (brv *BusinessRuleValidator) ValidateConfiguration(config *domain.Configuration) []ValidationError {
	var errors []ValidationError

	// Business rule: Auto-updates should be disabled in production
	if config.Profile().IsProduction() {
		if autoUpdates, exists := config.GetSetting(domain.ConfigKeyAutoUpdates); exists {
			if autoUpdates.Value() == "true" {
				errors = append(errors, ValidationError{
					Field:    "autoUpdates",
					Value:    autoUpdates.Value(),
					Message:  "auto-updates should be disabled in production for stability",
					Code:     "BUSINESS_RULE_PROD_AUTO_UPDATES",
					Severity: ValidationSeverityWarning,
				})
			}
		}
	}

	return errors
}

// ValidateInvariants validates business invariants
func (brv *BusinessRuleValidator) ValidateInvariants(config *domain.Configuration) []ValidationError {
	var errors []ValidationError

	// Invariant: Configuration must have a valid profile
	if config.Profile().Value() == "" {
		errors = append(errors, ValidationError{
			Field:    "profile",
			Value:    config.Profile().Value(),
			Message:  "configuration must have a valid profile",
			Code:     "INVARIANT_PROFILE_REQUIRED",
			Severity: ValidationSeverityError,
		})
	}

	return errors
}

// ValidateProfileSpecificRules validates profile-specific business rules
func (brv *BusinessRuleValidator) ValidateProfileSpecificRules(config *domain.Configuration) []ValidationError {
	var errors []ValidationError

	// Development profile specific rules
	if config.Profile().IsDevelopment() {
		// Dev profiles should have higher parallel task counts
		if parallelTasks, exists := config.GetSetting(domain.ConfigKeyParallelTasksCount); exists {
			if count, err := strconv.Atoi(parallelTasks.Value()); err == nil && count < 20 {
				errors = append(errors, ValidationError{
					Field:    "parallelTasksCount",
					Value:    parallelTasks.Value(),
					Message:  "development profile should have higher parallel task count for better performance",
					Code:     "PROFILE_RULE_DEV_PARALLEL_TASKS",
					Severity: ValidationSeverityInfo,
				})
			}
		}
	}

	return errors
}

// ValidateProfileConsistency validates that configuration is consistent with profile
func (brv *BusinessRuleValidator) ValidateProfileConsistency(config *domain.Configuration) []ValidationError {
	var errors []ValidationError

	// Check if settings match typical profile settings
	profile := config.Profile()
	settings := config.Settings()

	// This is a simplified check - in practice, you might have more sophisticated consistency rules
	if profile.IsProduction() {
		if theme, exists := settings[domain.ConfigKeyTheme]; exists {
			if theme.Value() == "auto" {
				errors = append(errors, ValidationError{
					Field:    "theme",
					Value:    theme.Value(),
					Message:  "auto theme may not be suitable for production environments",
					Code:     "CONSISTENCY_PROD_THEME",
					Severity: ValidationSeverityInfo,
				})
			}
		}
	}

	return errors
}
