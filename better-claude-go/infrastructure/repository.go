package infrastructure

import (
	"context"
	"fmt"

	"better-claude/domain"
)

// EventSourcedConfigurationRepository implements domain.ConfigurationRepository using event sourcing
type EventSourcedConfigurationRepository struct {
	eventStore domain.EventStore
}

// NewEventSourcedConfigurationRepository creates a new event-sourced repository
func NewEventSourcedConfigurationRepository(eventStore domain.EventStore) *EventSourcedConfigurationRepository {
	return &EventSourcedConfigurationRepository{
		eventStore: eventStore,
	}
}

// Save persists a Configuration aggregate using event sourcing
func (r *EventSourcedConfigurationRepository) Save(ctx context.Context, aggregate *domain.Configuration) error {
	uncommittedEvents := aggregate.UncommittedEvents()
	if len(uncommittedEvents) == 0 {
		return nil // No changes to persist
	}

	// Determine expected version (version before new events)
	expectedVersion := aggregate.Version() - len(uncommittedEvents)

	// Save events to event store
	err := r.eventStore.Save(aggregate.ID(), uncommittedEvents, expectedVersion)
	if err != nil {
		return domain.NewRepositoryError("save", aggregate.ID(), err)
	}

	// Mark events as committed
	aggregate.MarkEventsAsCommitted()

	return nil
}

// GetByID retrieves a Configuration aggregate by ID using event sourcing
func (r *EventSourcedConfigurationRepository) GetByID(ctx context.Context, id string) (*domain.Configuration, error) {
	events, err := r.eventStore.GetEvents(id)
	if err != nil {
		return nil, domain.NewRepositoryError("get_by_id", id, err)
	}

	if len(events) == 0 {
		return nil, domain.NewAggregateNotFoundError(id)
	}

	// Reconstruct aggregate from events
	aggregate := &Configuration{}
	if err := aggregate.LoadFromHistory(events); err != nil {
		return nil, domain.NewRepositoryError("load_from_history", id, err)
	}

	return aggregate.Configuration, nil
}

// GetByProfile retrieves a Configuration aggregate by profile
func (r *EventSourcedConfigurationRepository) GetByProfile(ctx context.Context, profile domain.Profile) (*domain.Configuration, error) {
	// In a real implementation, we'd need an index or search mechanism
	// For this example, we'll get all events and filter
	allEvents, err := r.eventStore.GetAllEvents()
	if err != nil {
		return nil, domain.NewRepositoryError("get_by_profile", profile.Value(), err)
	}

	// Group events by aggregate ID and find the one with matching profile
	eventsByAggregate := make(map[string][]domain.DomainEvent)
	for _, event := range allEvents {
		aggregateID := event.AggregateID()
		eventsByAggregate[aggregateID] = append(eventsByAggregate[aggregateID], event)
	}

	// Check each aggregate to see if it matches the profile
	for _, events := range eventsByAggregate {
		aggregate := &Configuration{}
		if err := aggregate.LoadFromHistory(events); err != nil {
			continue // Skip this aggregate if it can't be loaded
		}

		if aggregate.Configuration.Profile().IsEqual(profile) {
			return aggregate.Configuration, nil
		}
	}

	return nil, domain.NewAggregateNotFoundError(fmt.Sprintf("profile:%s", profile.Value()))
}

// Exists checks if a Configuration aggregate exists
func (r *EventSourcedConfigurationRepository) Exists(ctx context.Context, id string) (bool, error) {
	events, err := r.eventStore.GetEvents(id)
	if err != nil {
		return false, domain.NewRepositoryError("exists", id, err)
	}

	return len(events) > 0, nil
}

// Delete marks a Configuration aggregate as deleted (using event sourcing patterns)
func (r *EventSourcedConfigurationRepository) Delete(ctx context.Context, id string) error {
	// In event sourcing, we typically don't delete events
	// Instead, we could create a "Deleted" event or maintain a separate index
	// For this implementation, we'll return an error indicating deletion is not supported
	return fmt.Errorf("deletion not supported in event sourcing - consider using a 'deleted' event instead")
}

// GetAll retrieves all Configuration aggregates
func (r *EventSourcedConfigurationRepository) GetAll(ctx context.Context) ([]*domain.Configuration, error) {
	allEvents, err := r.eventStore.GetAllEvents()
	if err != nil {
		return nil, domain.NewRepositoryError("get_all", "", err)
	}

	// Group events by aggregate ID
	eventsByAggregate := make(map[string][]domain.DomainEvent)
	for _, event := range allEvents {
		aggregateID := event.AggregateID()
		eventsByAggregate[aggregateID] = append(eventsByAggregate[aggregateID], event)
	}

	// Reconstruct each aggregate
	var aggregates []*domain.Configuration
	for aggregateID, events := range eventsByAggregate {
		aggregate := &Configuration{}
		if err := aggregate.LoadFromHistory(events); err != nil {
			return nil, domain.NewRepositoryError("load_from_history", aggregateID, err)
		}
		aggregates = append(aggregates, aggregate.Configuration)
	}

	return aggregates, nil
}

// Configuration represents the aggregate in the infrastructure layer
// This is a wrapper around the domain Configuration that implements event sourcing
type Configuration struct {
	*domain.Configuration
}

// LoadFromHistory reconstructs the aggregate from domain events
func (c *Configuration) LoadFromHistory(events []domain.DomainEvent) error {
	if len(events) == 0 {
		return fmt.Errorf("cannot load aggregate from empty event stream")
	}

	// Find the creation event first
	var creationEvent *domain.ConfigurationCreated
	for _, event := range events {
		if created, ok := event.(*domain.ConfigurationCreated); ok {
			creationEvent = created
			break
		}
	}

	if creationEvent == nil {
		return fmt.Errorf("no configuration created event found in event stream")
	}

	// Recreate the aggregate using the creation event
	profile := creationEvent.Profile
	createdBy := creationEvent.CreatedBy
	
	newConfig, err := domain.NewConfiguration(profile, createdBy)
	if err != nil {
		return fmt.Errorf("failed to create configuration during replay: %w", err)
	}

	// Clear uncommitted events from creation
	newConfig.MarkEventsAsCommitted()

	// Apply all events in order
	for _, event := range events {
		if err := c.applyEventToAggregate(newConfig, event); err != nil {
			return fmt.Errorf("failed to apply event %s: %w", event.EventID(), err)
		}
	}

	c.Configuration = newConfig
	return nil
}

// applyEventToAggregate applies a single event to the aggregate
func (c *Configuration) applyEventToAggregate(aggregate *domain.Configuration, event domain.DomainEvent) error {
	switch e := event.(type) {
	case *domain.ConfigurationCreated:
		// Creation event is already handled in LoadFromHistory
		return nil

	case *domain.ConfigurationChanged:
		// Apply the configuration change
		return aggregate.ChangeConfiguration(e.Key, e.NewValue, e.ChangedBy)

	case *domain.ProfileSwitched:
		// Apply the profile switch
		return aggregate.SwitchProfile(e.NewProfile, e.SwitchedBy)

	case *domain.BackupCreated:
		// Apply the backup creation
		return aggregate.CreateBackup(e.BackupPath, e.CreatedBy)

	case *domain.ConfigurationValidated:
		// Apply validation (this updates internal state)
		aggregate.ValidateConfiguration(e.ValidatedBy)
		return nil

	default:
		// Unknown event type - log but don't fail
		// This allows for forward compatibility
		return nil
	}
}

// EventSourcedProfileRepository implements domain.ProfileRepository
type EventSourcedProfileRepository struct {
	configRepo domain.ConfigurationRepository
}

// NewEventSourcedProfileRepository creates a new event-sourced profile repository
func NewEventSourcedProfileRepository(configRepo domain.ConfigurationRepository) *EventSourcedProfileRepository {
	return &EventSourcedProfileRepository{
		configRepo: configRepo,
	}
}

// GetAvailableProfiles returns available profiles
func (r *EventSourcedProfileRepository) GetAvailableProfiles(ctx context.Context) ([]domain.Profile, error) {
	return []domain.Profile{
		domain.ProfileDev,
		domain.ProfileProduction,
		domain.ProfilePersonal,
	}, nil
}

// GetDefaultProfile returns the default profile
func (r *EventSourcedProfileRepository) GetDefaultProfile(ctx context.Context) (domain.Profile, error) {
	return domain.ProfilePersonal, nil
}

// ValidateProfile validates a profile
func (r *EventSourcedProfileRepository) ValidateProfile(ctx context.Context, profile domain.Profile) error {
	availableProfiles, err := r.GetAvailableProfiles(ctx)
	if err != nil {
		return err
	}

	for _, available := range availableProfiles {
		if profile.IsEqual(available) {
			return nil
		}
	}

	return fmt.Errorf("invalid profile: %s", profile.Value())
}

// GetProfileSettings returns settings for a profile
func (r *EventSourcedProfileRepository) GetProfileSettings(ctx context.Context, profile domain.Profile) (map[domain.ConfigKey]domain.ConfigValue, error) {
	// Try to find an existing configuration with this profile
	config, err := r.configRepo.GetByProfile(ctx, profile)
	if err != nil {
		// If not found, return default settings for this profile
		service := domain.NewDefaultConfigurationService()
		return service.GetRecommendedSettings(profile), nil
	}

	return config.Settings(), nil
}