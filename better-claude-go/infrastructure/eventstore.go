package infrastructure

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/ThreeDotsLabs/watermill"
	"github.com/ThreeDotsLabs/watermill/message"
	"github.com/ThreeDotsLabs/watermill/pubsub/gochannel"

	"better-claude/domain"
)

// EventStoreConfig holds configuration for the event store
type EventStoreConfig struct {
	BufferSize int
	Logger     watermill.LoggerAdapter
}

// WatermillEventStore implements event sourcing using Watermill
type WatermillEventStore struct {
	publisher  message.Publisher
	subscriber message.Subscriber
	events     map[string][]StoredEvent
	versions   map[string]int
	mutex      sync.RWMutex
	logger     watermill.LoggerAdapter
}

// StoredEvent represents an event as stored in the event store
type StoredEvent struct {
	ID          string                 `json:"id"`
	AggregateID string                 `json:"aggregate_id"`
	EventType   string                 `json:"event_type"`
	EventData   map[string]interface{} `json:"event_data"`
	Version     int                    `json:"version"`
	Timestamp   time.Time              `json:"timestamp"`
}

// NewWatermillEventStore creates a new Watermill-based event store
func NewWatermillEventStore(config EventStoreConfig) (*WatermillEventStore, error) {
	if config.Logger == nil {
		config.Logger = watermill.NewStdLogger(false, false)
	}

	pubSub := gochannel.NewGoChannel(
		gochannel.Config{
			OutputChannelBuffer: int64(config.BufferSize),
			Persistent:          true,
		},
		config.Logger,
	)

	return &WatermillEventStore{
		publisher:  pubSub,
		subscriber: pubSub,
		events:     make(map[string][]StoredEvent),
		versions:   make(map[string]int),
		logger:     config.Logger,
	}, nil
}

// Save persists events for an aggregate
func (es *WatermillEventStore) Save(aggregateID string, events []domain.DomainEvent, expectedVersion int) error {
	es.mutex.Lock()
	defer es.mutex.Unlock()

	// Check concurrency
	currentVersion := es.versions[aggregateID]
	if expectedVersion != 0 && currentVersion != expectedVersion {
		return domain.NewConcurrencyError(aggregateID, expectedVersion, currentVersion)
	}

	// Convert and store events
	storedEvents := make([]StoredEvent, 0, len(events))
	for _, event := range events {
		storedEvent := StoredEvent{
			ID:          event.EventID(),
			AggregateID: event.AggregateID(),
			EventType:   event.EventType(),
			EventData:   event.Payload(),
			Version:     event.Version(),
			Timestamp:   event.OccurredOn(),
		}
		storedEvents = append(storedEvents, storedEvent)
	}

	// Append to in-memory store
	if es.events[aggregateID] == nil {
		es.events[aggregateID] = make([]StoredEvent, 0)
	}
	es.events[aggregateID] = append(es.events[aggregateID], storedEvents...)

	// Update version
	if len(events) > 0 {
		es.versions[aggregateID] = events[len(events)-1].Version()
	}

	// Publish events to message bus
	for _, event := range events {
		if err := es.publishEvent(event); err != nil {
			es.logger.Error("Failed to publish event", err, watermill.LogFields{
				"aggregate_id": aggregateID,
				"event_id":     event.EventID(),
				"event_type":   event.EventType(),
			})
			// Continue processing other events even if one fails
		}
	}

	es.logger.Info("Events saved", watermill.LogFields{
		"aggregate_id": aggregateID,
		"event_count":  len(events),
		"new_version":  es.versions[aggregateID],
	})

	return nil
}

// GetEvents retrieves all events for an aggregate
func (es *WatermillEventStore) GetEvents(aggregateID string) ([]domain.DomainEvent, error) {
	es.mutex.RLock()
	defer es.mutex.RUnlock()

	storedEvents, exists := es.events[aggregateID]
	if !exists {
		return []domain.DomainEvent{}, nil
	}

	events := make([]domain.DomainEvent, 0, len(storedEvents))
	for _, stored := range storedEvents {
		event, err := es.convertStoredEventToDomainEvent(stored)
		if err != nil {
			return nil, fmt.Errorf("failed to convert stored event %s: %w", stored.ID, err)
		}
		events = append(events, event)
	}

	return events, nil
}

// GetEventsFromVersion retrieves events for an aggregate starting from a specific version
func (es *WatermillEventStore) GetEventsFromVersion(aggregateID string, version int) ([]domain.DomainEvent, error) {
	es.mutex.RLock()
	defer es.mutex.RUnlock()

	storedEvents, exists := es.events[aggregateID]
	if !exists {
		return []domain.DomainEvent{}, nil
	}

	events := make([]domain.DomainEvent, 0)
	for _, stored := range storedEvents {
		if stored.Version >= version {
			event, err := es.convertStoredEventToDomainEvent(stored)
			if err != nil {
				return nil, fmt.Errorf("failed to convert stored event %s: %w", stored.ID, err)
			}
			events = append(events, event)
		}
	}

	return events, nil
}

// GetAllEvents retrieves all events from all aggregates
func (es *WatermillEventStore) GetAllEvents() ([]domain.DomainEvent, error) {
	es.mutex.RLock()
	defer es.mutex.RUnlock()

	allEvents := make([]domain.DomainEvent, 0)
	for _, storedEvents := range es.events {
		for _, stored := range storedEvents {
			event, err := es.convertStoredEventToDomainEvent(stored)
			if err != nil {
				return nil, fmt.Errorf("failed to convert stored event %s: %w", stored.ID, err)
			}
			allEvents = append(allEvents, event)
		}
	}

	return allEvents, nil
}

// GetCurrentVersion returns the current version of an aggregate
func (es *WatermillEventStore) GetCurrentVersion(aggregateID string) int {
	es.mutex.RLock()
	defer es.mutex.RUnlock()
	return es.versions[aggregateID]
}

// ReplayEvents replays all events for debugging or projection rebuilding
func (es *WatermillEventStore) ReplayEvents(ctx context.Context, handler domain.EventHandler) error {
	events, err := es.GetAllEvents()
	if err != nil {
		return fmt.Errorf("failed to get all events for replay: %w", err)
	}

	es.logger.Info("Starting event replay", watermill.LogFields{
		"total_events": len(events),
	})

	for _, event := range events {
		if handler.CanHandle(event.EventType()) {
			if err := handler.Handle(event); err != nil {
				es.logger.Error("Failed to handle event during replay", err, watermill.LogFields{
					"event_id":   event.EventID(),
					"event_type": event.EventType(),
				})
				return fmt.Errorf("failed to handle event %s during replay: %w", event.EventID(), err)
			}
		}

		// Check if context was cancelled
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			// Continue processing
		}
	}

	es.logger.Info("Event replay completed", watermill.LogFields{
		"events_processed": len(events),
	})

	return nil
}

// publishEvent publishes an event to the message bus
func (es *WatermillEventStore) publishEvent(event domain.DomainEvent) error {
	eventData, err := json.Marshal(map[string]interface{}{
		"id":           event.EventID(),
		"aggregate_id": event.AggregateID(),
		"event_type":   event.EventType(),
		"version":      event.Version(),
		"occurred_on":  event.OccurredOn(),
		"payload":      event.Payload(),
	})
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	msg := message.NewMessage(event.EventID(), eventData)
	msg.Metadata.Set("event_type", event.EventType())
	msg.Metadata.Set("aggregate_id", event.AggregateID())

	topicName := fmt.Sprintf("events.%s", event.EventType())
	return es.publisher.Publish(topicName, msg)
}

// convertStoredEventToDomainEvent converts a stored event back to a domain event
func (es *WatermillEventStore) convertStoredEventToDomainEvent(stored StoredEvent) (domain.DomainEvent, error) {
	eventData, err := json.Marshal(stored)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal stored event: %w", err)
	}

	return domain.DeserializeEvent(eventData, stored.EventType)
}

// Close shuts down the event store
func (es *WatermillEventStore) Close() error {
	if closer, ok := es.publisher.(interface{ Close() error }); ok {
		if err := closer.Close(); err != nil {
			return fmt.Errorf("failed to close publisher: %w", err)
		}
	}

	if closer, ok := es.subscriber.(interface{ Close() error }); ok {
		if err := closer.Close(); err != nil {
			return fmt.Errorf("failed to close subscriber: %w", err)
		}
	}

	return nil
}

// GetSubscriber returns the message subscriber for external use
func (es *WatermillEventStore) GetSubscriber() message.Subscriber {
	return es.subscriber
}

// GetPublisher returns the message publisher for external use
func (es *WatermillEventStore) GetPublisher() message.Publisher {
	return es.publisher
}

// EventStoreStats provides statistics about the event store
type EventStoreStats struct {
	TotalAggregates int
	TotalEvents     int
	EventsByType    map[string]int
	AverageEvents   float64
}

// GetStats returns statistics about the event store
func (es *WatermillEventStore) GetStats() EventStoreStats {
	es.mutex.RLock()
	defer es.mutex.RUnlock()

	stats := EventStoreStats{
		TotalAggregates: len(es.events),
		EventsByType:    make(map[string]int),
	}

	totalEvents := 0
	for _, events := range es.events {
		totalEvents += len(events)
		for _, event := range events {
			stats.EventsByType[event.EventType]++
		}
	}

	stats.TotalEvents = totalEvents
	if stats.TotalAggregates > 0 {
		stats.AverageEvents = float64(totalEvents) / float64(stats.TotalAggregates)
	}

	return stats
}
