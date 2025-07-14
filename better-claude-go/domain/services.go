package domain

import (
	"context"
	"fmt"
	"regexp"
	"strconv"
)

// ConfigurationService defines domain services for configuration management
type ConfigurationService interface {
	ValidateConfigurationSettings(ctx context.Context, settings map[ConfigKey]ConfigValue) []ValidationError
	MergeConfigurations(base, override map[ConfigKey]ConfigValue) map[ConfigKey]ConfigValue
	GetRecommendedSettings(profile Profile) map[ConfigKey]ConfigValue
	CompareConfigurations(config1, config2 map[ConfigKey]ConfigValue) ConfigurationComparison
}

// BackupService defines domain services for backup management
type BackupService interface {
	GenerateBackupName(profile Profile) string
	ValidateBackupPath(path string) error
	CalculateBackupSize(config *Configuration) int64
	IsBackupValid(path string) (bool, error)
}

// ProfileService defines domain services for profile management
type ProfileService interface {
	GetOptimalProfile(requirements ProfileRequirements) (Profile, error)
	ValidateProfileTransition(from, to Profile) error
	GetProfileDifferences(profile1, profile2 Profile) []ProfileDifference
	RecommendProfile(currentUsage ProfileUsage) Profile
}

// ValidationService defines domain services for configuration validation
type ValidationService interface {
	ValidateConfiguration(config *Configuration) []ValidationError
	ValidateAgainstSchema(settings map[ConfigKey]ConfigValue) []ValidationError
	ValidateBusinessRules(config *Configuration) []ValidationError
	GetValidationSuggestions(errors []ValidationError) []ValidationSuggestion
}

// ValidationError represents a configuration validation error
type ValidationError struct {
	Field   string
	Value   string
	Message string
	Code    string
	Severity ValidationSeverity
}

// ValidationSeverity represents the severity of a validation error
type ValidationSeverity int

const (
	ValidationSeverityInfo ValidationSeverity = iota
	ValidationSeverityWarning
	ValidationSeverityError
	ValidationSeverityCritical
)

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

// ValidationSuggestion represents a suggestion to fix validation errors
type ValidationSuggestion struct {
	Field       string
	CurrentValue string
	SuggestedValue string
	Reason      string
	Impact      string
}

// ConfigurationComparison represents the differences between two configurations
type ConfigurationComparison struct {
	Added    map[ConfigKey]ConfigValue
	Removed  map[ConfigKey]ConfigValue
	Changed  map[ConfigKey]ConfigValueChange
	Unchanged map[ConfigKey]ConfigValue
}

// ConfigValueChange represents a change in configuration value
type ConfigValueChange struct {
	From ConfigValue
	To   ConfigValue
}

// ProfileRequirements represents requirements for profile selection
type ProfileRequirements struct {
	Performance      PerformanceLevel
	ResourceUsage    ResourceUsage
	NotificationLevel NotificationLevel
	Environment      Environment
}

// PerformanceLevel represents desired performance characteristics
type PerformanceLevel int

const (
	PerformanceLevelLow PerformanceLevel = iota
	PerformanceLevelMedium
	PerformanceLevelHigh
	PerformanceLevelUltra
)

// ResourceUsage represents resource usage preferences
type ResourceUsage int

const (
	ResourceUsageLow ResourceUsage = iota
	ResourceUsageMedium
	ResourceUsageHigh
)

// NotificationLevel represents notification preferences
type NotificationLevel int

const (
	NotificationLevelNone NotificationLevel = iota
	NotificationLevelLow
	NotificationLevelMedium
	NotificationLevelHigh
)

// Environment represents the operating environment
type Environment int

const (
	EnvironmentDevelopment Environment = iota
	EnvironmentTesting
	EnvironmentStaging
	EnvironmentProduction
)

// ProfileDifference represents a difference between profiles
type ProfileDifference struct {
	Setting     ConfigKey
	Profile1Value ConfigValue
	Profile2Value ConfigValue
	Impact      string
}

// ProfileUsage represents current usage patterns
type ProfileUsage struct {
	DailySessionHours    float64
	ParallelTasksUsed    int
	NotificationClicks   int
	ErrorFrequency       float64
	PerformanceIssues    int
}

// DefaultConfigurationService provides default implementations
type DefaultConfigurationService struct{}

// NewDefaultConfigurationService creates a new default configuration service
func NewDefaultConfigurationService() ConfigurationService {
	return &DefaultConfigurationService{}
}

// ValidateConfigurationSettings validates a set of configuration settings
func (s *DefaultConfigurationService) ValidateConfigurationSettings(ctx context.Context, settings map[ConfigKey]ConfigValue) []ValidationError {
	var errors []ValidationError

	for key, value := range settings {
		if err := s.validateSingleSetting(key, value); err != nil {
			errors = append(errors, ValidationError{
				Field:    key.Value(),
				Value:    value.Value(),
				Message:  err.Error(),
				Code:     "INVALID_VALUE",
				Severity: ValidationSeverityError,
			})
		}
	}

	return errors
}

// MergeConfigurations merges two configuration maps, with override taking precedence
func (s *DefaultConfigurationService) MergeConfigurations(base, override map[ConfigKey]ConfigValue) map[ConfigKey]ConfigValue {
	result := make(map[ConfigKey]ConfigValue)

	// Copy base configuration
	for k, v := range base {
		result[k] = v
	}

	// Apply overrides
	for k, v := range override {
		result[k] = v
	}

	return result
}

// GetRecommendedSettings returns recommended settings for a profile
func (s *DefaultConfigurationService) GetRecommendedSettings(profile Profile) map[ConfigKey]ConfigValue {
	return getDefaultSettingsForProfile(profile)
}

// CompareConfigurations compares two configuration maps
func (s *DefaultConfigurationService) CompareConfigurations(config1, config2 map[ConfigKey]ConfigValue) ConfigurationComparison {
	comparison := ConfigurationComparison{
		Added:     make(map[ConfigKey]ConfigValue),
		Removed:   make(map[ConfigKey]ConfigValue),
		Changed:   make(map[ConfigKey]ConfigValueChange),
		Unchanged: make(map[ConfigKey]ConfigValue),
	}

	// Find added and unchanged
	for k, v2 := range config2 {
		if v1, exists := config1[k]; exists {
			if v1.IsEqual(v2) {
				comparison.Unchanged[k] = v2
			} else {
				comparison.Changed[k] = ConfigValueChange{From: v1, To: v2}
			}
		} else {
			comparison.Added[k] = v2
		}
	}

	// Find removed
	for k, v1 := range config1 {
		if _, exists := config2[k]; !exists {
			comparison.Removed[k] = v1
		}
	}

	return comparison
}

// validateSingleSetting validates a single configuration setting
func (s *DefaultConfigurationService) validateSingleSetting(key ConfigKey, value ConfigValue) error {
	switch key {
	case ConfigKeyParallelTasksCount:
		if value.IsEmpty() {
			return fmt.Errorf("parallel tasks count cannot be empty")
		}
		// Could add numeric validation here

	case ConfigKeyMessageIdleNotifThresholdMs:
		if value.IsEmpty() {
			return fmt.Errorf("message idle notification threshold cannot be empty")
		}
		// Could add numeric validation here

	case ConfigKeyTheme:
		validThemes := []string{"dark", "light", "dark-daltonized", "auto"}
		if value.IsEmpty() {
			return fmt.Errorf("theme cannot be empty")
		}
		isValid := false
		for _, validTheme := range validThemes {
			if value.Value() == validTheme {
				isValid = true
				break
			}
		}
		if !isValid {
			return fmt.Errorf("invalid theme '%s'", value.Value())
		}

	case ConfigKeyAutoUpdates:
		if value.Value() != "true" && value.Value() != "false" {
			return fmt.Errorf("auto updates must be 'true' or 'false'")
		}

	case ConfigKeyPreferredNotifChannel:
		validChannels := []string{"none", "iterm2", "iterm2_with_bell", "system"}
		if value.IsEmpty() {
			return fmt.Errorf("preferred notification channel cannot be empty")
		}
		isValid := false
		for _, validChannel := range validChannels {
			if value.Value() == validChannel {
				isValid = true
				break
			}
		}
		if !isValid {
			return fmt.Errorf("invalid notification channel '%s'", value.Value())
		}

	case ConfigKeyDiffTool:
		validTools := []string{"bat", "diff", "code", "nano", "vim"}
		if value.IsEmpty() {
			return fmt.Errorf("diff tool cannot be empty")
		}
		isValid := false
		for _, validTool := range validTools {
			if value.Value() == validTool {
				isValid = true
				break
			}
		}
		if !isValid {
			return fmt.Errorf("invalid diff tool '%s'", value.Value())
		}
	}

	return nil
}

// DefaultProfileService provides default profile service implementation
type DefaultProfileService struct{}

// NewDefaultProfileService creates a new default profile service
func NewDefaultProfileService() ProfileService {
	return &DefaultProfileService{}
}

// ConfigurationValidationService provides domain validation services
type ConfigurationValidationService struct{}

// NewConfigurationValidationService creates a new configuration validation service
func NewConfigurationValidationService() *ConfigurationValidationService {
	return &ConfigurationValidationService{}
}

// ProfileMigrationService provides profile migration services
type ProfileMigrationService struct{}

// NewProfileMigrationService creates a new profile migration service
func NewProfileMigrationService() *ProfileMigrationService {
	return &ProfileMigrationService{}
}

// MigrationChange represents a change during profile migration
type MigrationChange struct {
	Key      ConfigKey
	OldValue ConfigValue
	NewValue ConfigValue
}

// MigrationRisk represents a risk during profile migration
type MigrationRisk struct {
	Category    string
	Level       string
	Description string
	Mitigation  string
}

// GetOptimalProfile returns the optimal profile based on requirements
func (s *DefaultProfileService) GetOptimalProfile(requirements ProfileRequirements) (Profile, error) {
	switch requirements.Environment {
	case EnvironmentDevelopment:
		if requirements.Performance == PerformanceLevelHigh || requirements.Performance == PerformanceLevelUltra {
			return ProfileDev, nil
		}
		return ProfilePersonal, nil

	case EnvironmentProduction:
		return ProfileProd, nil

	default:
		return ProfilePersonal, nil
	}
}

// ValidateProfileTransition validates a profile transition
func (s *DefaultProfileService) ValidateProfileTransition(from, to Profile) error {
	// Business rule: Can't transition from production to development in some cases
	if from.IsProduction() && to.IsDevelopment() {
		return fmt.Errorf("direct transition from production to development profile requires confirmation")
	}
	return nil
}

// GetProfileDifferences returns differences between two profiles
func (s *DefaultProfileService) GetProfileDifferences(profile1, profile2 Profile) []ProfileDifference {
	settings1 := getDefaultSettingsForProfile(profile1)
	settings2 := getDefaultSettingsForProfile(profile2)

	var differences []ProfileDifference

	for key, value1 := range settings1 {
		if value2, exists := settings2[key]; exists && !value1.IsEqual(value2) {
			differences = append(differences, ProfileDifference{
				Setting:       key,
				Profile1Value: value1,
				Profile2Value: value2,
				Impact:        s.getSettingImpact(key),
			})
		}
	}

	return differences
}

// RecommendProfile recommends a profile based on usage patterns
func (s *DefaultProfileService) RecommendProfile(currentUsage ProfileUsage) Profile {
	if currentUsage.DailySessionHours > 8 && currentUsage.ParallelTasksUsed > 30 {
		return ProfileDev
	}
	if currentUsage.PerformanceIssues > 5 || currentUsage.ErrorFrequency > 0.1 {
		return ProfileProd
	}
	return ProfilePersonal
}

// getSettingImpact returns the impact description for a setting
func (s *DefaultProfileService) getSettingImpact(key ConfigKey) string {
	switch key {
	case ConfigKeyParallelTasksCount:
		return "Affects concurrent task execution performance"
	case ConfigKeyMessageIdleNotifThresholdMs:
		return "Changes notification timing and user experience"
	case ConfigKeyTheme:
		return "Visual appearance and accessibility"
	case ConfigKeyAutoUpdates:
		return "Automatic update behavior and system stability"
	case ConfigKeyPreferredNotifChannel:
		return "Notification delivery method and visibility"
	case ConfigKeyDiffTool:
		return "Code comparison and review experience"
	default:
		return "General configuration impact"
	}
}

// ConfigurationValidationService methods

// ValidateTheme validates a theme configuration value
func (s *ConfigurationValidationService) ValidateTheme(value ConfigValue) error {
	validThemes := []string{"dark", "light", "dark-daltonized", "auto"}
	if value.IsEmpty() {
		return fmt.Errorf("theme cannot be empty")
	}
	for _, validTheme := range validThemes {
		if value.Value() == validTheme {
			return nil
		}
	}
	return fmt.Errorf("invalid theme '%s'", value.Value())
}

// ValidateParallelTasksCount validates parallel tasks count
func (s *ConfigurationValidationService) ValidateParallelTasksCount(value ConfigValue) error {
	if value.IsEmpty() {
		return fmt.Errorf("parallel tasks count cannot be empty")
	}
	count, err := strconv.Atoi(value.Value())
	if err != nil {
		return fmt.Errorf("parallel tasks count must be a number")
	}
	if count < 1 || count > 1000 {
		return fmt.Errorf("parallel tasks count must be between 1 and 1000")
	}
	return nil
}

// ValidateMessageIdleThreshold validates message idle threshold
func (s *ConfigurationValidationService) ValidateMessageIdleThreshold(value ConfigValue) error {
	if value.IsEmpty() {
		return fmt.Errorf("message idle notification threshold cannot be empty")
	}
	threshold, err := strconv.Atoi(value.Value())
	if err != nil {
		return fmt.Errorf("message idle threshold must be a number")
	}
	if threshold < 0 || threshold > 60000 {
		return fmt.Errorf("message idle threshold must be between 0 and 60000")
	}
	return nil
}

// ValidateAutoUpdates validates auto updates setting
func (s *ConfigurationValidationService) ValidateAutoUpdates(value ConfigValue) error {
	if value.Value() != "true" && value.Value() != "false" {
		return fmt.Errorf("auto updates must be 'true' or 'false'")
	}
	return nil
}

// ValidateNotificationChannel validates notification channel
func (s *ConfigurationValidationService) ValidateNotificationChannel(value ConfigValue) error {
	validChannels := []string{"none", "iterm2", "iterm2_with_bell", "system"}
	if value.IsEmpty() {
		return fmt.Errorf("preferred notification channel cannot be empty")
	}
	for _, validChannel := range validChannels {
		if value.Value() == validChannel {
			return nil
		}
	}
	return fmt.Errorf("invalid notification channel '%s'", value.Value())
}

// ValidateDiffTool validates diff tool setting
func (s *ConfigurationValidationService) ValidateDiffTool(value ConfigValue) error {
	validTools := []string{"bat", "diff", "code", "nano", "vim"}
	if value.IsEmpty() {
		return fmt.Errorf("diff tool cannot be empty")
	}
	for _, validTool := range validTools {
		if value.Value() == validTool {
			return nil
		}
	}
	return fmt.Errorf("invalid diff tool '%s'", value.Value())
}

// ValidateEnvironmentVariable validates environment variable
func (s *ConfigurationValidationService) ValidateEnvironmentVariable(name, value string) error {
	if name == "" {
		return fmt.Errorf("environment variable name cannot be empty")
	}
	
	// Check for system variables that should not be modified
	systemVars := []string{"PATH", "HOME", "USER", "SHELL", "PWD", "TERM"}
	for _, sysVar := range systemVars {
		if name == sysVar {
			return fmt.Errorf("system environment variable '%s' is not allowed", name)
		}
	}
	
	// Validate variable name format
	validName := regexp.MustCompile(`^[A-Z][A-Z0-9_]*$`)
	if !validName.MatchString(name) {
		return fmt.Errorf("invalid environment variable name '%s'", name)
	}
	
	return nil
}

// ValidateCompleteConfiguration validates a complete configuration
func (s *ConfigurationValidationService) ValidateCompleteConfiguration(config *Configuration) []string {
	var errors []string
	
	// Validate all settings
	for key, value := range config.Settings() {
		switch key {
		case ConfigKeyTheme:
			if err := s.ValidateTheme(value); err != nil {
				errors = append(errors, fmt.Sprintf("theme: %s", err.Error()))
			}
		case ConfigKeyParallelTasksCount:
			if err := s.ValidateParallelTasksCount(value); err != nil {
				errors = append(errors, fmt.Sprintf("parallelTasksCount: %s", err.Error()))
			}
		case ConfigKeyMessageIdleNotifThresholdMs:
			if err := s.ValidateMessageIdleThreshold(value); err != nil {
				errors = append(errors, fmt.Sprintf("messageIdleNotifThresholdMs: %s", err.Error()))
			}
		case ConfigKeyAutoUpdates:
			if err := s.ValidateAutoUpdates(value); err != nil {
				errors = append(errors, fmt.Sprintf("autoUpdates: %s", err.Error()))
			}
		case ConfigKeyPreferredNotifChannel:
			if err := s.ValidateNotificationChannel(value); err != nil {
				errors = append(errors, fmt.Sprintf("preferredNotifChannel: %s", err.Error()))
			}
		case ConfigKeyDiffTool:
			if err := s.ValidateDiffTool(value); err != nil {
				errors = append(errors, fmt.Sprintf("diffTool: %s", err.Error()))
			}
		}
	}
	
	return errors
}

// ProfileMigrationService methods

// CalculateMigrationChanges calculates changes needed for profile migration
func (s *ProfileMigrationService) CalculateMigrationChanges(from, to Profile) []MigrationChange {
	fromSettings := getDefaultSettingsForProfile(from)
	toSettings := getDefaultSettingsForProfile(to)
	
	var changes []MigrationChange
	
	for key, toValue := range toSettings {
		if fromValue, exists := fromSettings[key]; exists && !fromValue.IsEqual(toValue) {
			changes = append(changes, MigrationChange{
				Key:      key,
				OldValue: fromValue,
				NewValue: toValue,
			})
		}
	}
	
	return changes
}

// ValidateMigration validates a profile migration
func (s *ProfileMigrationService) ValidateMigration(from, to Profile) error {
	if from.IsEqual(to) {
		return fmt.Errorf("cannot migrate to the same profile")
	}
	return nil
}

// GetMigrationRisks returns risks associated with profile migration
func (s *ProfileMigrationService) GetMigrationRisks(from, to Profile) []MigrationRisk {
	var risks []MigrationRisk
	
	changes := s.CalculateMigrationChanges(from, to)
	
	for _, change := range changes {
		switch change.Key {
		case ConfigKeyParallelTasksCount:
			risks = append(risks, MigrationRisk{
				Category:    "performance",
				Level:       "medium",
				Description: "Parallel tasks count will change",
				Mitigation:  "Monitor performance after migration",
			})
		case ConfigKeyMessageIdleNotifThresholdMs:
			risks = append(risks, MigrationRisk{
				Category:    "user_experience",
				Level:       "low",
				Description: "Notification timing will change",
				Mitigation:  "Users may need to adjust to new timing",
			})
		}
	}
	
	return risks
}