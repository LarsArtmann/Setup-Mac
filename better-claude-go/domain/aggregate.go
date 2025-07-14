package domain

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// AggregateRoot is the base interface for all aggregate roots
type AggregateRoot interface {
	ID() string
	Version() int
	UncommittedEvents() []DomainEvent
	MarkEventsAsCommitted()
	LoadFromHistory(events []DomainEvent) error
}

// Configuration is the aggregate root for configuration management
type Configuration struct {
	id                string
	version           int
	profile           Profile
	settings          map[ConfigKey]ConfigValue
	envVariables      map[string]string
	createdAt         time.Time
	lastModifiedAt    time.Time
	lastBackupPath    string
	validationStatus  ValidationStatus
	uncommittedEvents []DomainEvent
}

// ValidationStatus represents the current validation state
type ValidationStatus struct {
	IsValid     bool
	LastChecked time.Time
	ErrorCount  int
	Errors      []string
}

// NewConfiguration creates a new Configuration aggregate
func NewConfiguration(profile Profile, createdBy string) (*Configuration, error) {
	// Validate profile
	if profile.Value() == "" {
		return nil, fmt.Errorf("profile cannot be empty")
	}

	aggregateID := uuid.New().String()
	now := time.Now()

	// Initialize with default settings based on profile
	initialSettings := getDefaultSettingsForProfile(profile)

	config := &Configuration{
		id:                aggregateID,
		version:           0,
		profile:           profile,
		settings:          initialSettings,
		envVariables:      make(map[string]string),
		createdAt:         now,
		lastModifiedAt:    now,
		validationStatus:  ValidationStatus{IsValid: true, LastChecked: now, ErrorCount: 0},
		uncommittedEvents: make([]DomainEvent, 0),
	}

	// Raise domain event
	event := NewConfigurationCreated(aggregateID, profile, initialSettings, createdBy, config.version+1)
	config.raiseEvent(event)

	return config, nil
}

// ID returns the aggregate ID
func (c *Configuration) ID() string {
	return c.id
}

// Version returns the current version
func (c *Configuration) Version() int {
	return c.version
}

// Profile returns the current active profile
func (c *Configuration) Profile() Profile {
	return c.profile
}

// Settings returns a copy of current settings
func (c *Configuration) Settings() map[ConfigKey]ConfigValue {
	result := make(map[ConfigKey]ConfigValue)
	for k, v := range c.settings {
		result[k] = v
	}
	return result
}

// GetSetting returns a specific setting value
func (c *Configuration) GetSetting(key ConfigKey) (ConfigValue, bool) {
	value, exists := c.settings[key]
	return value, exists
}

// EnvVariables returns a copy of environment variables
func (c *Configuration) EnvVariables() map[string]string {
	result := make(map[string]string)
	for k, v := range c.envVariables {
		result[k] = v
	}
	return result
}

// ChangeConfiguration updates a configuration setting
func (c *Configuration) ChangeConfiguration(key ConfigKey, newValue ConfigValue, changedBy string) error {
	// Business rule: Cannot change configuration if validation is failing
	if !c.validationStatus.IsValid {
		return fmt.Errorf("cannot change configuration while validation is failing")
	}

	// Business rule: Validate the new value based on the key
	if err := c.validateConfigurationValue(key, newValue); err != nil {
		return fmt.Errorf("invalid configuration value: %w", err)
	}

	oldValue, exists := c.settings[key]
	if !exists {
		oldValue = ConfigValue{value: ""}
	}

	// Business rule: Don't create events for non-changes
	if oldValue.IsEqual(newValue) {
		return nil
	}

	// Apply the change
	c.settings[key] = newValue
	c.lastModifiedAt = time.Now()

	// Raise domain event
	event := NewConfigurationChanged(c.id, key, oldValue, newValue, changedBy, c.profile, c.version+1)
	c.raiseEvent(event)

	return nil
}

// SwitchProfile changes the active profile and applies its settings
func (c *Configuration) SwitchProfile(newProfile Profile, switchedBy string) error {
	// Business rule: Cannot switch to the same profile
	if c.profile.IsEqual(newProfile) {
		return fmt.Errorf("already using profile '%s'", newProfile.Value())
	}

	oldProfile := c.profile

	// Get settings for new profile
	newSettings := getDefaultSettingsForProfile(newProfile)

	// Count how many settings will change
	configChanges := 0
	for key, newValue := range newSettings {
		if oldValue, exists := c.settings[key]; !exists || !oldValue.IsEqual(newValue) {
			configChanges++
		}
	}

	// Apply new profile settings
	c.profile = newProfile
	c.settings = newSettings
	c.lastModifiedAt = time.Now()

	// Raise domain event
	event := NewProfileSwitched(c.id, oldProfile, newProfile, switchedBy, configChanges, c.version+1)
	c.raiseEvent(event)

	return nil
}

// CreateBackup creates a backup of the current configuration
func (c *Configuration) CreateBackup(backupPath string, createdBy string) error {
	// Business rule: Backup path cannot be empty
	if backupPath == "" {
		return fmt.Errorf("backup path cannot be empty")
	}

	c.lastBackupPath = backupPath
	configCount := len(c.settings)

	// Raise domain event
	event := NewBackupCreated(c.id, backupPath, c.profile, createdBy, configCount, c.version+1)
	c.raiseEvent(event)

	return nil
}

// ValidateConfiguration performs validation and updates status
func (c *Configuration) ValidateConfiguration(validatedBy string) []string {
	errors := make([]string, 0)

	// Validate all settings
	for key, value := range c.settings {
		if err := c.validateConfigurationValue(key, value); err != nil {
			errors = append(errors, fmt.Sprintf("%s: %s", key.Value(), err.Error()))
		}
	}

	// Update validation status
	c.validationStatus = ValidationStatus{
		IsValid:     len(errors) == 0,
		LastChecked: time.Now(),
		ErrorCount:  len(errors),
		Errors:      errors,
	}

	// Raise domain event
	event := NewConfigurationValidated(c.id, c.profile, c.validationStatus.IsValid, len(errors), validatedBy, c.version+1)
	c.raiseEvent(event)

	return errors
}

// UncommittedEvents returns events that haven't been committed
func (c *Configuration) UncommittedEvents() []DomainEvent {
	return c.uncommittedEvents
}

// MarkEventsAsCommitted clears uncommitted events
func (c *Configuration) MarkEventsAsCommitted() {
	c.uncommittedEvents = make([]DomainEvent, 0)
}

// LoadFromHistory reconstructs the aggregate from events
func (c *Configuration) LoadFromHistory(events []DomainEvent) error {
	for _, event := range events {
		if err := c.applyEvent(event); err != nil {
			return fmt.Errorf("failed to apply event %s: %w", event.EventID(), err)
		}
	}
	return nil
}

// GetValidationStatus returns the current validation status
func (c *Configuration) GetValidationStatus() ValidationStatus {
	return c.validationStatus
}

// GetLastBackupPath returns the path of the last backup
func (c *Configuration) GetLastBackupPath() string {
	return c.lastBackupPath
}

// Private methods

func (c *Configuration) raiseEvent(event DomainEvent) {
	c.uncommittedEvents = append(c.uncommittedEvents, event)
	c.version = event.Version()
}

func (c *Configuration) applyEvent(event DomainEvent) error {
	switch e := event.(type) {
	case *ConfigurationCreated:
		c.id = e.AggregateID()
		c.profile = e.Profile
		c.settings = e.InitialConfig
		c.createdAt = e.OccurredOn()
		c.lastModifiedAt = e.OccurredOn()
		c.version = e.Version()

	case *ConfigurationChanged:
		c.settings[e.Key] = e.NewValue
		c.lastModifiedAt = e.OccurredOn()
		c.version = e.Version()

	case *ProfileSwitched:
		c.profile = e.NewProfile
		// Note: In event sourcing, we need to rebuild settings from all events
		c.lastModifiedAt = e.OccurredOn()
		c.version = e.Version()

	case *BackupCreated:
		c.lastBackupPath = e.BackupPath
		c.version = e.Version()

	case *ConfigurationValidated:
		c.validationStatus = ValidationStatus{
			IsValid:     e.ValidationPassed,
			LastChecked: e.OccurredOn(),
			ErrorCount:  e.ErrorCount,
		}
		c.version = e.Version()

	default:
		return fmt.Errorf("unknown event type: %s", event.EventType())
	}

	return nil
}

func (c *Configuration) validateConfigurationValue(key ConfigKey, value ConfigValue) error {
	switch key {
	case ConfigKeyParallelTasksCount:
		// Must be a positive integer
		if value.IsEmpty() {
			return fmt.Errorf("parallel tasks count cannot be empty")
		}
		// Additional validation could be added here

	case ConfigKeyMessageIdleNotifThresholdMs:
		// Must be a positive integer
		if value.IsEmpty() {
			return fmt.Errorf("message idle notification threshold cannot be empty")
		}
		// Additional validation could be added here

	case ConfigKeyTheme:
		// Must be a valid theme
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
		// Must be "true" or "false"
		if value.Value() != "true" && value.Value() != "false" {
			return fmt.Errorf("auto updates must be 'true' or 'false'")
		}

	case ConfigKeyPreferredNotifChannel:
		// Validate notification channels
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
		// Validate diff tools
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

func getDefaultSettingsForProfile(profile Profile) map[ConfigKey]ConfigValue {
	settings := make(map[ConfigKey]ConfigValue)

	if profile.IsDevelopment() {
		settings[ConfigKeyTheme] = ConfigValue{value: "dark-daltonized"}
		settings[ConfigKeyParallelTasksCount] = ConfigValue{value: "50"}
		settings[ConfigKeyPreferredNotifChannel] = ConfigValue{value: "iterm2_with_bell"}
		settings[ConfigKeyMessageIdleNotifThresholdMs] = ConfigValue{value: "500"}
		settings[ConfigKeyAutoUpdates] = ConfigValue{value: "false"}
		settings[ConfigKeyDiffTool] = ConfigValue{value: "bat"}
	} else if profile.IsProduction() {
		settings[ConfigKeyTheme] = ConfigValue{value: "dark-daltonized"}
		settings[ConfigKeyParallelTasksCount] = ConfigValue{value: "10"}
		settings[ConfigKeyPreferredNotifChannel] = ConfigValue{value: "iterm2_with_bell"}
		settings[ConfigKeyMessageIdleNotifThresholdMs] = ConfigValue{value: "2000"}
		settings[ConfigKeyAutoUpdates] = ConfigValue{value: "false"}
		settings[ConfigKeyDiffTool] = ConfigValue{value: "bat"}
	} else { // Personal/Default
		settings[ConfigKeyTheme] = ConfigValue{value: "dark-daltonized"}
		settings[ConfigKeyParallelTasksCount] = ConfigValue{value: "20"}
		settings[ConfigKeyPreferredNotifChannel] = ConfigValue{value: "iterm2_with_bell"}
		settings[ConfigKeyMessageIdleNotifThresholdMs] = ConfigValue{value: "1000"}
		settings[ConfigKeyAutoUpdates] = ConfigValue{value: "false"}
		settings[ConfigKeyDiffTool] = ConfigValue{value: "bat"}
	}

	return settings
}
