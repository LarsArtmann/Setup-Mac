package application

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"

	"better-claude/domain"
)

// MockRepository for testing command handlers
type MockRepository struct {
	mock.Mock
}

func (m *MockRepository) Save(ctx context.Context, config *domain.Configuration) error {
	args := m.Called(ctx, config)
	return args.Error(0)
}

func (m *MockRepository) GetByID(ctx context.Context, id string) (*domain.Configuration, error) {
	args := m.Called(ctx, id)
	return args.Get(0).(*domain.Configuration), args.Error(1)
}

func (m *MockRepository) GetByProfile(ctx context.Context, profile domain.Profile) (*domain.Configuration, error) {
	args := m.Called(ctx, profile)
	return args.Get(0).(*domain.Configuration), args.Error(1)
}

func (m *MockRepository) LoadFromEvents(ctx context.Context, aggregateID string) (*domain.Configuration, error) {
	args := m.Called(ctx, aggregateID)
	return args.Get(0).(*domain.Configuration), args.Error(1)
}

// MockEventBus for testing command handlers
type MockEventBus struct {
	mock.Mock
	publishedEvents []domain.DomainEvent
}

func (m *MockEventBus) Publish(ctx context.Context, events []domain.DomainEvent) error {
	args := m.Called(ctx, events)
	m.publishedEvents = append(m.publishedEvents, events...)
	return args.Error(0)
}

func (m *MockEventBus) GetPublishedEvents() []domain.DomainEvent {
	return m.publishedEvents
}

func (m *MockEventBus) ClearEvents() {
	m.publishedEvents = []domain.DomainEvent{}
}

// CommandHandlersTestSuite contains tests for command handlers
type CommandHandlersTestSuite struct {
	suite.Suite
	repository     *MockRepository
	eventBus       *MockEventBus
	commandHandler *CommandHandlers
	ctx            context.Context
}

func (suite *CommandHandlersTestSuite) SetupTest() {
	suite.repository = &MockRepository{}
	suite.eventBus = &MockEventBus{}
	suite.commandHandler = NewCommandHandlers(suite.repository, suite.eventBus)
	suite.ctx = context.Background()
}

func (suite *CommandHandlersTestSuite) TearDownTest() {
	suite.repository.AssertExpectations(suite.T())
	suite.eventBus.AssertExpectations(suite.T())
}

// Test CreateConfiguration Command
func (suite *CommandHandlersTestSuite) TestCreateConfiguration_Success() {
	// Arrange
	profile, _ := domain.NewProfile("dev")
	command := CreateConfigurationCommand{
		Profile:   *profile,
		CreatedBy: "testUser",
	}

	suite.repository.On("Save", suite.ctx, mock.MatchedBy(func(config *domain.Configuration) bool {
		return config.Profile().IsEqual(*profile)
	})).Return(nil)

	suite.eventBus.On("Publish", suite.ctx, mock.MatchedBy(func(events []domain.DomainEvent) bool {
		return len(events) == 1 && events[0].EventType() == "ConfigurationCreated"
	})).Return(nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	
	createResult, ok := result.(CreateConfigurationResult)
	assert.True(suite.T(), ok)
	assert.NotEmpty(suite.T(), createResult.ConfigurationID)
	assert.True(suite.T(), createResult.Profile.IsEqual(*profile))
}

func (suite *CommandHandlersTestSuite) TestCreateConfiguration_InvalidProfile() {
	// Arrange
	command := CreateConfigurationCommand{
		Profile:   domain.Profile{}, // Empty profile
		CreatedBy: "testUser",
	}

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Contains(suite.T(), err.Error(), "profile")
}

func (suite *CommandHandlersTestSuite) TestCreateConfiguration_RepositoryError() {
	// Arrange
	profile, _ := domain.NewProfile("dev")
	command := CreateConfigurationCommand{
		Profile:   *profile,
		CreatedBy: "testUser",
	}

	suite.repository.On("Save", suite.ctx, mock.AnythingOfType("*domain.Configuration")).Return(assert.AnError)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Equal(suite.T(), assert.AnError, err)
}

// Test ChangeConfiguration Command
func (suite *CommandHandlersTestSuite) TestChangeConfiguration_Success() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	existingConfig, _ := domain.NewConfiguration(*profile, "creator")
	existingConfig.MarkEventsAsCommitted() // Clear creation event

	key, _ := domain.NewConfigKey("theme")
	newValue, _ := domain.NewConfigValue("dark")

	command := ChangeConfigurationCommand{
		ConfigurationID: configID,
		Key:             *key,
		Value:           *newValue,
		ChangedBy:       "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return(existingConfig, nil)
	suite.repository.On("Save", suite.ctx, existingConfig).Return(nil)
	suite.eventBus.On("Publish", suite.ctx, mock.MatchedBy(func(events []domain.DomainEvent) bool {
		return len(events) == 1 && events[0].EventType() == "ConfigurationChanged"
	})).Return(nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	
	changeResult, ok := result.(ChangeConfigurationResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, changeResult.ConfigurationID)
	assert.True(suite.T(), changeResult.Key.IsEqual(*key))
	assert.True(suite.T(), changeResult.NewValue.IsEqual(*newValue))
}

func (suite *CommandHandlersTestSuite) TestChangeConfiguration_ConfigNotFound() {
	// Arrange
	configID := "non-existent-config"
	key, _ := domain.NewConfigKey("theme")
	value, _ := domain.NewConfigValue("dark")

	command := ChangeConfigurationCommand{
		ConfigurationID: configID,
		Key:             *key,
		Value:           *value,
		ChangedBy:       "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return((*domain.Configuration)(nil), assert.AnError)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
}

func (suite *CommandHandlersTestSuite) TestChangeConfiguration_InvalidValue() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	existingConfig, _ := domain.NewConfiguration(*profile, "creator")

	key, _ := domain.NewConfigKey("theme")
	invalidValue, _ := domain.NewConfigValue("invalid-theme")

	command := ChangeConfigurationCommand{
		ConfigurationID: configID,
		Key:             *key,
		Value:           *invalidValue,
		ChangedBy:       "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return(existingConfig, nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Contains(suite.T(), err.Error(), "invalid")
}

// Test SwitchProfile Command
func (suite *CommandHandlersTestSuite) TestSwitchProfile_Success() {
	// Arrange
	configID := "test-config-id"
	oldProfile, _ := domain.NewProfile("dev")
	newProfile, _ := domain.NewProfile("prod")
	existingConfig, _ := domain.NewConfiguration(*oldProfile, "creator")
	existingConfig.MarkEventsAsCommitted()

	command := SwitchProfileCommand{
		ConfigurationID: configID,
		NewProfile:      *newProfile,
		SwitchedBy:      "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return(existingConfig, nil)
	suite.repository.On("Save", suite.ctx, existingConfig).Return(nil)
	suite.eventBus.On("Publish", suite.ctx, mock.MatchedBy(func(events []domain.DomainEvent) bool {
		return len(events) == 1 && events[0].EventType() == "ProfileSwitched"
	})).Return(nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	
	switchResult, ok := result.(SwitchProfileResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, switchResult.ConfigurationID)
	assert.True(suite.T(), switchResult.OldProfile.IsEqual(*oldProfile))
	assert.True(suite.T(), switchResult.NewProfile.IsEqual(*newProfile))
	assert.Greater(suite.T(), switchResult.ConfigChanges, 0)
}

func (suite *CommandHandlersTestSuite) TestSwitchProfile_SameProfile() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	existingConfig, _ := domain.NewConfiguration(*profile, "creator")

	command := SwitchProfileCommand{
		ConfigurationID: configID,
		NewProfile:      *profile, // Same profile
		SwitchedBy:      "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return(existingConfig, nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Contains(suite.T(), err.Error(), "already using profile")
}

// Test CreateBackup Command
func (suite *CommandHandlersTestSuite) TestCreateBackup_Success() {
	// Arrange
	configID := "test-config-id"
	backupPath := "/backup/path.tar.gz"
	profile, _ := domain.NewProfile("dev")
	existingConfig, _ := domain.NewConfiguration(*profile, "creator")
	existingConfig.MarkEventsAsCommitted()

	command := CreateBackupCommand{
		ConfigurationID: configID,
		BackupPath:      backupPath,
		CreatedBy:       "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return(existingConfig, nil)
	suite.repository.On("Save", suite.ctx, existingConfig).Return(nil)
	suite.eventBus.On("Publish", suite.ctx, mock.MatchedBy(func(events []domain.DomainEvent) bool {
		return len(events) == 1 && events[0].EventType() == "BackupCreated"
	})).Return(nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	
	backupResult, ok := result.(CreateBackupResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, backupResult.ConfigurationID)
	assert.Equal(suite.T(), backupPath, backupResult.BackupPath)
	assert.Greater(suite.T(), backupResult.ConfigCount, 0)
}

func (suite *CommandHandlersTestSuite) TestCreateBackup_EmptyPath() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	existingConfig, _ := domain.NewConfiguration(*profile, "creator")

	command := CreateBackupCommand{
		ConfigurationID: configID,
		BackupPath:      "", // Empty path
		CreatedBy:       "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return(existingConfig, nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Contains(suite.T(), err.Error(), "backup path cannot be empty")
}

// Test ValidateConfiguration Command
func (suite *CommandHandlersTestSuite) TestValidateConfiguration_Success() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	existingConfig, _ := domain.NewConfiguration(*profile, "creator")
	existingConfig.MarkEventsAsCommitted()

	command := ValidateConfigurationCommand{
		ConfigurationID: configID,
		ValidatedBy:     "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return(existingConfig, nil)
	suite.repository.On("Save", suite.ctx, existingConfig).Return(nil)
	suite.eventBus.On("Publish", suite.ctx, mock.MatchedBy(func(events []domain.DomainEvent) bool {
		return len(events) == 1 && events[0].EventType() == "ConfigurationValidated"
	})).Return(nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	
	validateResult, ok := result.(ValidateConfigurationResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, validateResult.ConfigurationID)
	assert.True(suite.T(), validateResult.ValidationPassed)
	assert.Empty(suite.T(), validateResult.Errors)
}

func (suite *CommandHandlersTestSuite) TestValidateConfiguration_WithErrors() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	existingConfig, _ := domain.NewConfiguration(*profile, "creator")
	existingConfig.MarkEventsAsCommitted()

	// Set invalid theme to force validation error
	invalidTheme, _ := domain.NewConfigValue("")
	existingConfig.ChangeConfiguration(domain.ConfigKeyTheme, *invalidTheme, "testUser")
	existingConfig.MarkEventsAsCommitted() // Clear change event

	command := ValidateConfigurationCommand{
		ConfigurationID: configID,
		ValidatedBy:     "testUser",
	}

	suite.repository.On("GetByID", suite.ctx, configID).Return(existingConfig, nil)
	suite.repository.On("Save", suite.ctx, existingConfig).Return(nil)
	suite.eventBus.On("Publish", suite.ctx, mock.MatchedBy(func(events []domain.DomainEvent) bool {
		return len(events) == 1 && events[0].EventType() == "ConfigurationValidated"
	})).Return(nil)

	// Act
	result, err := suite.commandHandler.Handle(suite.ctx, command)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)
	
	validateResult, ok := result.(ValidateConfigurationResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, validateResult.ConfigurationID)
	assert.False(suite.T(), validateResult.ValidationPassed)
	assert.NotEmpty(suite.T(), validateResult.Errors)
}

// Test Command Handler Interface Compliance
func (suite *CommandHandlersTestSuite) TestCommandHandler_InterfaceCompliance() {
	// Test that CommandHandlers implements CommandHandler interface
	var handler CommandHandler = suite.commandHandler
	assert.NotNil(suite.T(), handler)
}

// Test Event Publishing
func (suite *CommandHandlersTestSuite) TestEventPublishing_AllCommands() {
	// Test that all commands properly publish events
	profile, _ := domain.NewProfile("dev")
	
	// Create configuration
	createCommand := CreateConfigurationCommand{
		Profile:   *profile,
		CreatedBy: "testUser",
	}

	suite.repository.On("Save", suite.ctx, mock.AnythingOfType("*domain.Configuration")).Return(nil)
	suite.eventBus.On("Publish", suite.ctx, mock.AnythingOfType("[]domain.DomainEvent")).Return(nil)

	result, err := suite.commandHandler.Handle(suite.ctx, createCommand)
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	// Verify events were published
	publishedEvents := suite.eventBus.GetPublishedEvents()
	assert.NotEmpty(suite.T(), publishedEvents)
	assert.Equal(suite.T(), "ConfigurationCreated", publishedEvents[0].EventType())
}

// Test Error Handling
func (suite *CommandHandlersTestSuite) TestErrorHandling_InvalidCommands() {
	// Test handling of invalid commands
	invalidCommands := []Command{
		nil,
		"invalid command type",
		123,
	}

	for _, cmd := range invalidCommands {
		result, err := suite.commandHandler.Handle(suite.ctx, cmd)
		assert.Error(suite.T(), err)
		assert.Nil(suite.T(), result)
	}
}

// Test Context Cancellation
func (suite *CommandHandlersTestSuite) TestContextCancellation() {
	// Create a cancelled context
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	profile, _ := domain.NewProfile("dev")
	command := CreateConfigurationCommand{
		Profile:   *profile,
		CreatedBy: "testUser",
	}

	// Handle command with cancelled context
	result, err := suite.commandHandler.Handle(ctx, command)

	// Should handle context cancellation gracefully
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Contains(suite.T(), err.Error(), "context")
}

// Test Concurrency Safety
func (suite *CommandHandlersTestSuite) TestConcurrencySafety() {
	// Test that command handlers can be called concurrently
	profile, _ := domain.NewProfile("dev")
	command := CreateConfigurationCommand{
		Profile:   *profile,
		CreatedBy: "testUser",
	}

	// Set up expectations for multiple calls
	suite.repository.On("Save", suite.ctx, mock.AnythingOfType("*domain.Configuration")).Return(nil).Times(5)
	suite.eventBus.On("Publish", suite.ctx, mock.AnythingOfType("[]domain.DomainEvent")).Return(nil).Times(5)

	// Execute commands concurrently
	results := make(chan interface{}, 5)
	errors := make(chan error, 5)

	for i := 0; i < 5; i++ {
		go func() {
			result, err := suite.commandHandler.Handle(suite.ctx, command)
			results <- result
			errors <- err
		}()
	}

	// Collect results
	for i := 0; i < 5; i++ {
		result := <-results
		err := <-errors
		assert.NoError(suite.T(), err)
		assert.NotNil(suite.T(), result)
	}
}

// Run the command handlers test suite
func TestCommandHandlersTestSuite(t *testing.T) {
	suite.Run(t, new(CommandHandlersTestSuite))
}