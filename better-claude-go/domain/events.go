package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// DomainEvent is the base interface for all domain events
type DomainEvent interface {
	EventID() string
	EventType() string
	AggregateID() string
	OccurredOn() time.Time
	Version() int
	Payload() map[string]interface{}
}

// BaseEvent provides common event functionality
type BaseEvent struct {
	ID           string                 `json:"id"`
	Type         string                 `json:"type"`
	AggregateId  string                 `json:"aggregate_id"`
	OccurredAt   time.Time              `json:"occurred_at"`
	EventVersion int                    `json:"version"`
	Data         map[string]interface{} `json:"data"`
}

// EventID returns the unique identifier of the event
func (e BaseEvent) EventID() string {
	return e.ID
}

// EventType returns the type of the event
func (e BaseEvent) EventType() string {
	return e.Type
}

// AggregateID returns the ID of the aggregate that produced this event
func (e BaseEvent) AggregateID() string {
	return e.AggregateId
}

// OccurredOn returns when the event occurred
func (e BaseEvent) OccurredOn() time.Time {
	return e.OccurredAt
}

// Version returns the version of the event
func (e BaseEvent) Version() int {
	return e.EventVersion
}

// Payload returns the event data
func (e BaseEvent) Payload() map[string]interface{} {
	return e.Data
}

// ConfigurationChanged event occurs when a configuration value is changed
type ConfigurationChanged struct {
	BaseEvent
	Key           ConfigKey   `json:"key"`
	OldValue      ConfigValue `json:"old_value"`
	NewValue      ConfigValue `json:"new_value"`
	ChangedBy     string      `json:"changed_by"`
	ProfileActive Profile     `json:"profile_active"`
}

// NewConfigurationChanged creates a new ConfigurationChanged event
func NewConfigurationChanged(
	aggregateID string,
	key ConfigKey,
	oldValue ConfigValue,
	newValue ConfigValue,
	changedBy string,
	profileActive Profile,
	version int,
) *ConfigurationChanged {
	eventID := uuid.New().String()

	return &ConfigurationChanged{
		BaseEvent: BaseEvent{
			ID:           eventID,
			Type:         "ConfigurationChanged",
			AggregateId:  aggregateID,
			OccurredAt:   time.Now(),
			EventVersion: version,
			Data: map[string]interface{}{
				"key":            key.Value(),
				"old_value":      oldValue.Value(),
				"new_value":      newValue.Value(),
				"changed_by":     changedBy,
				"profile_active": profileActive.Value(),
			},
		},
		Key:           key,
		OldValue:      oldValue,
		NewValue:      newValue,
		ChangedBy:     changedBy,
		ProfileActive: profileActive,
	}
}

// ProfileSwitched event occurs when the active profile is changed
type ProfileSwitched struct {
	BaseEvent
	OldProfile    Profile `json:"old_profile"`
	NewProfile    Profile `json:"new_profile"`
	SwitchedBy    string  `json:"switched_by"`
	ConfigChanges int     `json:"config_changes"`
}

// NewProfileSwitched creates a new ProfileSwitched event
func NewProfileSwitched(
	aggregateID string,
	oldProfile Profile,
	newProfile Profile,
	switchedBy string,
	configChanges int,
	version int,
) *ProfileSwitched {
	eventID := uuid.New().String()

	return &ProfileSwitched{
		BaseEvent: BaseEvent{
			ID:           eventID,
			Type:         "ProfileSwitched",
			AggregateId:  aggregateID,
			OccurredAt:   time.Now(),
			EventVersion: version,
			Data: map[string]interface{}{
				"old_profile":    oldProfile.Value(),
				"new_profile":    newProfile.Value(),
				"switched_by":    switchedBy,
				"config_changes": configChanges,
			},
		},
		OldProfile:    oldProfile,
		NewProfile:    newProfile,
		SwitchedBy:    switchedBy,
		ConfigChanges: configChanges,
	}
}

// ConfigurationCreated event occurs when a new configuration aggregate is created
type ConfigurationCreated struct {
	BaseEvent
	Profile       Profile                   `json:"profile"`
	InitialConfig map[ConfigKey]ConfigValue `json:"initial_config"`
	CreatedBy     string                    `json:"created_by"`
}

// NewConfigurationCreated creates a new ConfigurationCreated event
func NewConfigurationCreated(
	aggregateID string,
	profile Profile,
	initialConfig map[ConfigKey]ConfigValue,
	createdBy string,
	version int,
) *ConfigurationCreated {
	eventID := uuid.New().String()

	// Convert config map to serializable format
	configData := make(map[string]interface{})
	for k, v := range initialConfig {
		configData[k.Value()] = v.Value()
	}

	return &ConfigurationCreated{
		BaseEvent: BaseEvent{
			ID:           eventID,
			Type:         "ConfigurationCreated",
			AggregateId:  aggregateID,
			OccurredAt:   time.Now(),
			EventVersion: version,
			Data: map[string]interface{}{
				"profile":        profile.Value(),
				"initial_config": configData,
				"created_by":     createdBy,
			},
		},
		Profile:       profile,
		InitialConfig: initialConfig,
		CreatedBy:     createdBy,
	}
}

// BackupCreated event occurs when a configuration backup is created
type BackupCreated struct {
	BaseEvent
	BackupPath  string  `json:"backup_path"`
	Profile     Profile `json:"profile"`
	CreatedBy   string  `json:"created_by"`
	ConfigCount int     `json:"config_count"`
}

// NewBackupCreated creates a new BackupCreated event
func NewBackupCreated(
	aggregateID string,
	backupPath string,
	profile Profile,
	createdBy string,
	configCount int,
	version int,
) *BackupCreated {
	eventID := uuid.New().String()

	return &BackupCreated{
		BaseEvent: BaseEvent{
			ID:           eventID,
			Type:         "BackupCreated",
			AggregateId:  aggregateID,
			OccurredAt:   time.Now(),
			EventVersion: version,
			Data: map[string]interface{}{
				"backup_path":  backupPath,
				"profile":      profile.Value(),
				"created_by":   createdBy,
				"config_count": configCount,
			},
		},
		BackupPath:  backupPath,
		Profile:     profile,
		CreatedBy:   createdBy,
		ConfigCount: configCount,
	}
}

// ConfigurationValidated event occurs when configuration validation is performed
type ConfigurationValidated struct {
	BaseEvent
	Profile          Profile `json:"profile"`
	ValidationPassed bool    `json:"validation_passed"`
	ErrorCount       int     `json:"error_count"`
	ValidatedBy      string  `json:"validated_by"`
}

// NewConfigurationValidated creates a new ConfigurationValidated event
func NewConfigurationValidated(
	aggregateID string,
	profile Profile,
	validationPassed bool,
	errorCount int,
	validatedBy string,
	version int,
) *ConfigurationValidated {
	eventID := uuid.New().String()

	return &ConfigurationValidated{
		BaseEvent: BaseEvent{
			ID:           eventID,
			Type:         "ConfigurationValidated",
			AggregateId:  aggregateID,
			OccurredAt:   time.Now(),
			EventVersion: version,
			Data: map[string]interface{}{
				"profile":           profile.Value(),
				"validation_passed": validationPassed,
				"error_count":       errorCount,
				"validated_by":      validatedBy,
			},
		},
		Profile:          profile,
		ValidationPassed: validationPassed,
		ErrorCount:       errorCount,
		ValidatedBy:      validatedBy,
	}
}

// EventStore interface for persisting and retrieving events
type EventStore interface {
	Save(aggregateID string, events []DomainEvent, expectedVersion int) error
	GetEvents(aggregateID string) ([]DomainEvent, error)
	GetEventsFromVersion(aggregateID string, version int) ([]DomainEvent, error)
	GetAllEvents() ([]DomainEvent, error)
}

// EventPublisher interface for publishing events to external systems
type EventPublisher interface {
	Publish(event DomainEvent) error
	PublishBatch(events []DomainEvent) error
}

// EventHandler interface for handling domain events
type EventHandler interface {
	Handle(event DomainEvent) error
	CanHandle(eventType string) bool
}

// EventBus interface for managing event subscriptions and publishing
type EventBus interface {
	Subscribe(eventType string, handler EventHandler) error
	Unsubscribe(eventType string, handler EventHandler) error
	Publish(event DomainEvent) error
	PublishBatch(events []DomainEvent) error
}

// SerializeEvent converts a domain event to JSON
func SerializeEvent(event DomainEvent) ([]byte, error) {
	return json.Marshal(event)
}

// DeserializeEvent converts JSON back to a domain event
func DeserializeEvent(data []byte, eventType string) (DomainEvent, error) {
	switch eventType {
	case "configuration.changed":
		var event ConfigurationChanged
		err := json.Unmarshal(data, &event)
		return &event, err
	case "profile.switched":
		var event ProfileSwitched
		err := json.Unmarshal(data, &event)
		return &event, err
	case "configuration.created":
		var event ConfigurationCreated
		err := json.Unmarshal(data, &event)
		return &event, err
	case "backup.created":
		var event BackupCreated
		err := json.Unmarshal(data, &event)
		return &event, err
	case "configuration.validated":
		var event ConfigurationValidated
		err := json.Unmarshal(data, &event)
		return &event, err
	default:
		var event BaseEvent
		err := json.Unmarshal(data, &event)
		return &event, err
	}
}
