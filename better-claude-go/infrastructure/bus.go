package infrastructure

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"

	"github.com/ThreeDotsLabs/watermill"
	"github.com/ThreeDotsLabs/watermill/message"
	"github.com/ThreeDotsLabs/watermill/pubsub/gochannel"
	"github.com/google/uuid"

	"better-claude/application"
)

// WatermillCommandBus implements application.CommandBus using Watermill
type WatermillCommandBus struct {
	publisher message.Publisher
	subscriber message.Subscriber
	handlers  map[string]application.CommandHandler
	logger    watermill.LoggerAdapter
	mutex     sync.RWMutex
}

// NewWatermillCommandBus creates a new Watermill-based command bus
func NewWatermillCommandBus(logger watermill.LoggerAdapter) (*WatermillCommandBus, error) {
	if logger == nil {
		logger = watermill.NewStdLogger(false, false)
	}

	pubSub := gochannel.NewGoChannel(
		gochannel.Config{
			OutputChannelBuffer: 100,
			Persistent:          true,
		},
		logger,
	)

	bus := &WatermillCommandBus{
		publisher:  pubSub,
		subscriber: pubSub,
		handlers:   make(map[string]application.CommandHandler),
		logger:     logger,
	}

	return bus, nil
}

// RegisterHandler registers a command handler for a specific command type
func (b *WatermillCommandBus) RegisterHandler(commandType string, handler application.CommandHandler) error {
	b.mutex.Lock()
	defer b.mutex.Unlock()

	if _, exists := b.handlers[commandType]; exists {
		return fmt.Errorf("handler already registered for command type: %s", commandType)
	}

	b.handlers[commandType] = handler
	
	// Subscribe to command messages
	topicName := fmt.Sprintf("commands.%s", commandType)
	messages, err := b.subscriber.Subscribe(context.Background(), topicName)
	if err != nil {
		return fmt.Errorf("failed to subscribe to topic %s: %w", topicName, err)
	}

	// Start message processing in a goroutine
	go b.processMessages(commandType, handler, messages)

	b.logger.Info("Command handler registered", watermill.LogFields{
		"command_type": commandType,
		"topic":        topicName,
	})

	return nil
}

// Send sends a command through the message bus
func (b *WatermillCommandBus) Send(ctx context.Context, command application.Command) error {
	if err := command.Validate(); err != nil {
		return fmt.Errorf("command validation failed: %w", err)
	}

	// Serialize command
	commandData, err := json.Marshal(command)
	if err != nil {
		return fmt.Errorf("failed to serialize command: %w", err)
	}

	// Create message
	msg := message.NewMessage(command.CommandID(), commandData)
	msg.Metadata.Set("command_type", command.CommandType())
	msg.Metadata.Set("command_id", command.CommandID())

	// Publish to appropriate topic
	topicName := fmt.Sprintf("commands.%s", command.CommandType())
	
	b.logger.Info("Sending command", watermill.LogFields{
		"command_id":   command.CommandID(),
		"command_type": command.CommandType(),
		"topic":        topicName,
	})

	return b.publisher.Publish(topicName, msg)
}

// processMessages processes incoming command messages
func (b *WatermillCommandBus) processMessages(commandType string, handler application.CommandHandler, messages <-chan *message.Message) {
	for msg := range messages {
		b.logger.Info("Processing command message", watermill.LogFields{
			"command_type": commandType,
			"message_id":   msg.UUID,
		})

		ctx := context.Background()
		
		// Deserialize command
		command, err := b.deserializeCommand(msg.Payload, commandType)
		if err != nil {
			b.logger.Error("Failed to deserialize command", err, watermill.LogFields{
				"command_type": commandType,
				"message_id":   msg.UUID,
			})
			msg.Nack()
			continue
		}

		// Handle command
		if err := handler.Handle(ctx, command); err != nil {
			b.logger.Error("Command handling failed", err, watermill.LogFields{
				"command_type": commandType,
				"command_id":   command.CommandID(),
				"message_id":   msg.UUID,
			})
			msg.Nack()
			continue
		}

		// Acknowledge message
		msg.Ack()
		
		b.logger.Info("Command processed successfully", watermill.LogFields{
			"command_type": commandType,
			"command_id":   command.CommandID(),
			"message_id":   msg.UUID,
		})
	}
}

// deserializeCommand deserializes a command from JSON based on its type
func (b *WatermillCommandBus) deserializeCommand(data []byte, commandType string) (application.Command, error) {
	switch commandType {
	case "create_configuration":
		var cmd application.CreateConfigurationCommand
		err := json.Unmarshal(data, &cmd)
		return &cmd, err
	case "change_configuration":
		var cmd application.ChangeConfigurationCommand
		err := json.Unmarshal(data, &cmd)
		return &cmd, err
	case "switch_profile":
		var cmd application.SwitchProfileCommand
		err := json.Unmarshal(data, &cmd)
		return &cmd, err
	case "create_backup":
		var cmd application.CreateBackupCommand
		err := json.Unmarshal(data, &cmd)
		return &cmd, err
	case "validate_configuration":
		var cmd application.ValidateConfigurationCommand
		err := json.Unmarshal(data, &cmd)
		return &cmd, err
	default:
		return nil, fmt.Errorf("unknown command type: %s", commandType)
	}
}

// Close shuts down the command bus
func (b *WatermillCommandBus) Close() error {
	if closer, ok := b.publisher.(interface{ Close() error }); ok {
		if err := closer.Close(); err != nil {
			return fmt.Errorf("failed to close publisher: %w", err)
		}
	}

	if closer, ok := b.subscriber.(interface{ Close() error }); ok {
		if err := closer.Close(); err != nil {
			return fmt.Errorf("failed to close subscriber: %w", err)
		}
	}

	return nil
}

// WatermillQueryBus implements application.QueryBus using Watermill
type WatermillQueryBus struct {
	publisher message.Publisher
	subscriber message.Subscriber
	handlers  map[string]application.QueryHandler
	logger    watermill.LoggerAdapter
	mutex     sync.RWMutex
	responses map[string]chan *queryResponse
}

type queryResponse struct {
	Data  interface{}
	Error error
}

// NewWatermillQueryBus creates a new Watermill-based query bus
func NewWatermillQueryBus(logger watermill.LoggerAdapter) (*WatermillQueryBus, error) {
	if logger == nil {
		logger = watermill.NewStdLogger(false, false)
	}

	pubSub := gochannel.NewGoChannel(
		gochannel.Config{
			OutputChannelBuffer: 100,
			Persistent:          true,
		},
		logger,
	)

	bus := &WatermillQueryBus{
		publisher:  pubSub,
		subscriber: pubSub,
		handlers:   make(map[string]application.QueryHandler),
		logger:     logger,
		responses:  make(map[string]chan *queryResponse),
	}

	// Subscribe to query responses
	responseMessages, err := pubSub.Subscribe(context.Background(), "query.responses")
	if err != nil {
		return nil, fmt.Errorf("failed to subscribe to query responses: %w", err)
	}

	go bus.processResponseMessages(responseMessages)

	return bus, nil
}

// RegisterHandler registers a query handler for a specific query type
func (b *WatermillQueryBus) RegisterHandler(queryType string, handler application.QueryHandler) error {
	b.mutex.Lock()
	defer b.mutex.Unlock()

	if _, exists := b.handlers[queryType]; exists {
		return fmt.Errorf("handler already registered for query type: %s", queryType)
	}

	b.handlers[queryType] = handler
	
	// Subscribe to query messages
	topicName := fmt.Sprintf("queries.%s", queryType)
	messages, err := b.subscriber.Subscribe(context.Background(), topicName)
	if err != nil {
		return fmt.Errorf("failed to subscribe to topic %s: %w", topicName, err)
	}

	// Start message processing in a goroutine
	go b.processQueryMessages(queryType, handler, messages)

	b.logger.Info("Query handler registered", watermill.LogFields{
		"query_type": queryType,
		"topic":      topicName,
	})

	return nil
}

// Send sends a query and waits for response
func (b *WatermillQueryBus) Send(ctx context.Context, query application.Query) (interface{}, error) {
	if err := query.Validate(); err != nil {
		return nil, fmt.Errorf("query validation failed: %w", err)
	}

	// Create response channel
	responseID := uuid.New().String()
	responseChan := make(chan *queryResponse, 1)
	
	b.mutex.Lock()
	b.responses[responseID] = responseChan
	b.mutex.Unlock()

	// Clean up response channel when done
	defer func() {
		b.mutex.Lock()
		delete(b.responses, responseID)
		b.mutex.Unlock()
		close(responseChan)
	}()

	// Serialize query
	queryData, err := json.Marshal(query)
	if err != nil {
		return nil, fmt.Errorf("failed to serialize query: %w", err)
	}

	// Create message
	msg := message.NewMessage(query.QueryID(), queryData)
	msg.Metadata.Set("query_type", query.QueryType())
	msg.Metadata.Set("query_id", query.QueryID())
	msg.Metadata.Set("response_id", responseID)

	// Publish to appropriate topic
	topicName := fmt.Sprintf("queries.%s", query.QueryType())
	
	b.logger.Info("Sending query", watermill.LogFields{
		"query_id":    query.QueryID(),
		"query_type":  query.QueryType(),
		"response_id": responseID,
		"topic":       topicName,
	})

	if err := b.publisher.Publish(topicName, msg); err != nil {
		return nil, fmt.Errorf("failed to publish query: %w", err)
	}

	// Wait for response
	select {
	case response := <-responseChan:
		if response.Error != nil {
			return nil, response.Error
		}
		return response.Data, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

// processQueryMessages processes incoming query messages
func (b *WatermillQueryBus) processQueryMessages(queryType string, handler application.QueryHandler, messages <-chan *message.Message) {
	for msg := range messages {
		b.logger.Info("Processing query message", watermill.LogFields{
			"query_type": queryType,
			"message_id": msg.UUID,
		})

		ctx := context.Background()
		responseID := msg.Metadata.Get("response_id")
		
		// Deserialize query
		query, err := b.deserializeQuery(msg.Payload, queryType)
		if err != nil {
			b.logger.Error("Failed to deserialize query", err, watermill.LogFields{
				"query_type": queryType,
				"message_id": msg.UUID,
			})
			b.sendResponse(responseID, nil, err)
			msg.Nack()
			continue
		}

		// Handle query
		result, err := handler.Handle(ctx, query)
		if err != nil {
			b.logger.Error("Query handling failed", err, watermill.LogFields{
				"query_type": queryType,
				"query_id":   query.QueryID(),
				"message_id": msg.UUID,
			})
			b.sendResponse(responseID, nil, err)
			msg.Nack()
			continue
		}

		// Send response
		b.sendResponse(responseID, result, nil)
		msg.Ack()
		
		b.logger.Info("Query processed successfully", watermill.LogFields{
			"query_type": queryType,
			"query_id":   query.QueryID(),
			"message_id": msg.UUID,
		})
	}
}

// processResponseMessages processes query response messages
func (b *WatermillQueryBus) processResponseMessages(messages <-chan *message.Message) {
	for msg := range messages {
		responseID := msg.Metadata.Get("response_id")
		
		b.mutex.RLock()
		responseChan, exists := b.responses[responseID]
		b.mutex.RUnlock()

		if !exists {
			b.logger.Error("Response channel not found", nil, watermill.LogFields{
				"response_id": responseID,
				"message_id":  msg.UUID,
			})
			msg.Nack()
			continue
		}

		var response queryResponse
		if err := json.Unmarshal(msg.Payload, &response); err != nil {
			b.logger.Error("Failed to deserialize response", err, watermill.LogFields{
				"response_id": responseID,
				"message_id":  msg.UUID,
			})
			msg.Nack()
			continue
		}

		// Send response to waiting channel
		select {
		case responseChan <- &response:
			msg.Ack()
		default:
			b.logger.Error("Response channel full", nil, watermill.LogFields{
				"response_id": responseID,
				"message_id":  msg.UUID,
			})
			msg.Nack()
		}
	}
}

// sendResponse sends a query response
func (b *WatermillQueryBus) sendResponse(responseID string, data interface{}, err error) {
	response := queryResponse{
		Data:  data,
		Error: err,
	}

	responseData, marshalErr := json.Marshal(response)
	if marshalErr != nil {
		b.logger.Error("Failed to marshal response", marshalErr, watermill.LogFields{
			"response_id": responseID,
		})
		return
	}

	msg := message.NewMessage(uuid.New().String(), responseData)
	msg.Metadata.Set("response_id", responseID)

	if publishErr := b.publisher.Publish("query.responses", msg); publishErr != nil {
		b.logger.Error("Failed to publish response", publishErr, watermill.LogFields{
			"response_id": responseID,
		})
	}
}

// deserializeQuery deserializes a query from JSON based on its type
func (b *WatermillQueryBus) deserializeQuery(data []byte, queryType string) (application.Query, error) {
	switch queryType {
	case "get_configuration":
		var query application.GetConfigurationQuery
		err := json.Unmarshal(data, &query)
		return &query, err
	case "get_configuration_by_profile":
		var query application.GetConfigurationByProfileQuery
		err := json.Unmarshal(data, &query)
		return &query, err
	case "get_all_configurations":
		var query application.GetAllConfigurationsQuery
		err := json.Unmarshal(data, &query)
		return &query, err
	case "get_available_profiles":
		var query application.GetAvailableProfilesQuery
		err := json.Unmarshal(data, &query)
		return &query, err
	case "get_configuration_history":
		var query application.GetConfigurationHistoryQuery
		err := json.Unmarshal(data, &query)
		return &query, err
	default:
		return nil, fmt.Errorf("unknown query type: %s", queryType)
	}
}

// Close shuts down the query bus
func (b *WatermillQueryBus) Close() error {
	if closer, ok := b.publisher.(interface{ Close() error }); ok {
		if err := closer.Close(); err != nil {
			return fmt.Errorf("failed to close publisher: %w", err)
		}
	}

	if closer, ok := b.subscriber.(interface{ Close() error }); ok {
		if err := closer.Close(); err != nil {
			return fmt.Errorf("failed to close subscriber: %w", err)
		}
	}

	return nil
}