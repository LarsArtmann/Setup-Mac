package application

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/suite"

	"better-claude/domain"
)

// MockReadRepository for testing query handlers
type MockReadRepository struct {
	mock.Mock
}

func (m *MockReadRepository) GetByID(ctx context.Context, id string) (*domain.Configuration, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Configuration), args.Error(1)
}

func (m *MockReadRepository) GetByProfile(ctx context.Context, profile domain.Profile) (*domain.Configuration, error) {
	args := m.Called(ctx, profile)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*domain.Configuration), args.Error(1)
}

func (m *MockReadRepository) GetAll(ctx context.Context) ([]*domain.Configuration, error) {
	args := m.Called(ctx)
	return args.Get(0).([]*domain.Configuration), args.Error(1)
}

func (m *MockReadRepository) GetByValidationStatus(ctx context.Context, isValid bool) ([]*domain.Configuration, error) {
	args := m.Called(ctx, isValid)
	return args.Get(0).([]*domain.Configuration), args.Error(1)
}

func (m *MockReadRepository) GetRecentlyModified(ctx context.Context, limit int) ([]*domain.Configuration, error) {
	args := m.Called(ctx, limit)
	return args.Get(0).([]*domain.Configuration), args.Error(1)
}

// QueryHandlersTestSuite contains tests for query handlers
type QueryHandlersTestSuite struct {
	suite.Suite
	readRepository *MockReadRepository
	queryHandler   *QueryHandlers
	ctx            context.Context
}

func (suite *QueryHandlersTestSuite) SetupTest() {
	suite.readRepository = &MockReadRepository{}
	suite.queryHandler = NewQueryHandlers(suite.readRepository)
	suite.ctx = context.Background()
}

func (suite *QueryHandlersTestSuite) TearDownTest() {
	suite.readRepository.AssertExpectations(suite.T())
}

// Test GetConfiguration Query
func (suite *QueryHandlersTestSuite) TestGetConfiguration_Success() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	expectedConfig, _ := domain.NewConfiguration(*profile, "creator")

	query := GetConfigurationQuery{
		ConfigurationID: configID,
	}

	suite.readRepository.On("GetByID", suite.ctx, configID).Return(expectedConfig, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	getResult, ok := result.(GetConfigurationResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, getResult.ConfigurationID)
	assert.True(suite.T(), getResult.Profile.IsEqual(*profile))
	assert.NotEmpty(suite.T(), getResult.Settings)
	assert.NotNil(suite.T(), getResult.EnvVariables)
	assert.NotEmpty(suite.T(), getResult.CreatedAt)
	assert.NotEmpty(suite.T(), getResult.LastModifiedAt)
}

func (suite *QueryHandlersTestSuite) TestGetConfiguration_NotFound() {
	// Arrange
	configID := "non-existent-config"
	query := GetConfigurationQuery{
		ConfigurationID: configID,
	}

	suite.readRepository.On("GetByID", suite.ctx, configID).Return(nil, assert.AnError)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
}

// Test GetConfigurationByProfile Query
func (suite *QueryHandlersTestSuite) TestGetConfigurationByProfile_Success() {
	// Arrange
	profile, _ := domain.NewProfile("dev")
	expectedConfig, _ := domain.NewConfiguration(*profile, "creator")

	query := GetConfigurationByProfileQuery{
		Profile: *profile,
	}

	suite.readRepository.On("GetByProfile", suite.ctx, *profile).Return(expectedConfig, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	getResult, ok := result.(GetConfigurationByProfileResult)
	assert.True(suite.T(), ok)
	assert.True(suite.T(), getResult.Profile.IsEqual(*profile))
	assert.NotEmpty(suite.T(), getResult.Settings)
}

func (suite *QueryHandlersTestSuite) TestGetConfigurationByProfile_NotFound() {
	// Arrange
	profile, _ := domain.NewProfile("nonexistent")
	query := GetConfigurationByProfileQuery{
		Profile: *profile,
	}

	suite.readRepository.On("GetByProfile", suite.ctx, *profile).Return(nil, assert.AnError)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
}

// Test ListConfigurations Query
func (suite *QueryHandlersTestSuite) TestListConfigurations_Success() {
	// Arrange
	profile1, _ := domain.NewProfile("dev")
	profile2, _ := domain.NewProfile("prod")
	config1, _ := domain.NewConfiguration(*profile1, "creator1")
	config2, _ := domain.NewConfiguration(*profile2, "creator2")

	expectedConfigs := []*domain.Configuration{config1, config2}

	query := ListConfigurationsQuery{}

	suite.readRepository.On("GetAll", suite.ctx).Return(expectedConfigs, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	listResult, ok := result.(ListConfigurationsResult)
	assert.True(suite.T(), ok)
	assert.Len(suite.T(), listResult.Configurations, 2)
	assert.Equal(suite.T(), 2, listResult.TotalCount)
}

func (suite *QueryHandlersTestSuite) TestListConfigurations_Empty() {
	// Arrange
	query := ListConfigurationsQuery{}

	suite.readRepository.On("GetAll", suite.ctx).Return([]*domain.Configuration{}, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	listResult, ok := result.(ListConfigurationsResult)
	assert.True(suite.T(), ok)
	assert.Empty(suite.T(), listResult.Configurations)
	assert.Equal(suite.T(), 0, listResult.TotalCount)
}

// Test GetConfigurationValidationStatus Query
func (suite *QueryHandlersTestSuite) TestGetConfigurationValidationStatus_Success() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	config, _ := domain.NewConfiguration(*profile, "creator")

	// Run validation to set status
	config.ValidateConfiguration("validator")

	query := GetConfigurationValidationStatusQuery{
		ConfigurationID: configID,
	}

	suite.readRepository.On("GetByID", suite.ctx, configID).Return(config, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	validationResult, ok := result.(GetConfigurationValidationStatusResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, validationResult.ConfigurationID)
	assert.True(suite.T(), validationResult.IsValid)
	assert.Empty(suite.T(), validationResult.Errors)
	assert.Equal(suite.T(), 0, validationResult.ErrorCount)
	assert.NotEmpty(suite.T(), validationResult.LastChecked)
}

func (suite *QueryHandlersTestSuite) TestGetConfigurationValidationStatus_WithErrors() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	config, _ := domain.NewConfiguration(*profile, "creator")

	// Set invalid theme to force validation error
	invalidTheme, _ := domain.NewConfigValue("")
	config.ChangeConfiguration(domain.ConfigKeyTheme, *invalidTheme, "testUser")
	config.ValidateConfiguration("validator")

	query := GetConfigurationValidationStatusQuery{
		ConfigurationID: configID,
	}

	suite.readRepository.On("GetByID", suite.ctx, configID).Return(config, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	validationResult, ok := result.(GetConfigurationValidationStatusResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, validationResult.ConfigurationID)
	assert.False(suite.T(), validationResult.IsValid)
	assert.NotEmpty(suite.T(), validationResult.Errors)
	assert.Greater(suite.T(), validationResult.ErrorCount, 0)
}

// Test GetConfigurationHistory Query
func (suite *QueryHandlersTestSuite) TestGetConfigurationHistory_Success() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	config, _ := domain.NewConfiguration(*profile, "creator")

	// Generate some events
	newValue, _ := domain.NewConfigValue("dark")
	config.ChangeConfiguration(domain.ConfigKeyTheme, *newValue, "changer")
	config.CreateBackup("/backup/path", "backupper")

	query := GetConfigurationHistoryQuery{
		ConfigurationID: configID,
		Limit:           10,
	}

	suite.readRepository.On("GetByID", suite.ctx, configID).Return(config, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	historyResult, ok := result.(GetConfigurationHistoryResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), configID, historyResult.ConfigurationID)
	assert.NotEmpty(suite.T(), historyResult.Events)
	assert.Equal(suite.T(), 3, historyResult.EventCount) // Created, Changed, BackupCreated
}

func (suite *QueryHandlersTestSuite) TestGetConfigurationHistory_WithLimit() {
	// Arrange
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	config, _ := domain.NewConfiguration(*profile, "creator")

	// Generate multiple events
	for i := 0; i < 5; i++ {
		newValue, _ := domain.NewConfigValue("value-" + string(rune(i)))
		config.ChangeConfiguration(domain.ConfigKeyTheme, *newValue, "changer")
	}

	query := GetConfigurationHistoryQuery{
		ConfigurationID: configID,
		Limit:           3,
	}

	suite.readRepository.On("GetByID", suite.ctx, configID).Return(config, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	historyResult, ok := result.(GetConfigurationHistoryResult)
	assert.True(suite.T(), ok)
	assert.LessOrEqual(suite.T(), len(historyResult.Events), 3)
	assert.Equal(suite.T(), 6, historyResult.EventCount) // All events count
}

// Test ListConfigurationsByValidationStatus Query
func (suite *QueryHandlersTestSuite) TestListConfigurationsByValidationStatus_Valid() {
	// Arrange
	profile, _ := domain.NewProfile("dev")
	validConfig, _ := domain.NewConfiguration(*profile, "creator")
	validConfig.ValidateConfiguration("validator")

	expectedConfigs := []*domain.Configuration{validConfig}

	query := ListConfigurationsByValidationStatusQuery{
		IsValid: true,
	}

	suite.readRepository.On("GetByValidationStatus", suite.ctx, true).Return(expectedConfigs, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	listResult, ok := result.(ListConfigurationsByValidationStatusResult)
	assert.True(suite.T(), ok)
	assert.Len(suite.T(), listResult.Configurations, 1)
	assert.True(suite.T(), listResult.IsValid)
	assert.Equal(suite.T(), 1, listResult.TotalCount)
}

func (suite *QueryHandlersTestSuite) TestListConfigurationsByValidationStatus_Invalid() {
	// Arrange
	profile, _ := domain.NewProfile("dev")
	invalidConfig, _ := domain.NewConfiguration(*profile, "creator")

	// Set invalid theme
	invalidTheme, _ := domain.NewConfigValue("")
	invalidConfig.ChangeConfiguration(domain.ConfigKeyTheme, *invalidTheme, "testUser")
	invalidConfig.ValidateConfiguration("validator")

	expectedConfigs := []*domain.Configuration{invalidConfig}

	query := ListConfigurationsByValidationStatusQuery{
		IsValid: false,
	}

	suite.readRepository.On("GetByValidationStatus", suite.ctx, false).Return(expectedConfigs, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	listResult, ok := result.(ListConfigurationsByValidationStatusResult)
	assert.True(suite.T(), ok)
	assert.Len(suite.T(), listResult.Configurations, 1)
	assert.False(suite.T(), listResult.IsValid)
}

// Test GetRecentConfigurations Query
func (suite *QueryHandlersTestSuite) TestGetRecentConfigurations_Success() {
	// Arrange
	profile, _ := domain.NewProfile("dev")
	config1, _ := domain.NewConfiguration(*profile, "creator1")
	config2, _ := domain.NewConfiguration(*profile, "creator2")

	expectedConfigs := []*domain.Configuration{config1, config2}

	query := GetRecentConfigurationsQuery{
		Limit: 5,
	}

	suite.readRepository.On("GetRecentlyModified", suite.ctx, 5).Return(expectedConfigs, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	recentResult, ok := result.(GetRecentConfigurationsResult)
	assert.True(suite.T(), ok)
	assert.Len(suite.T(), recentResult.Configurations, 2)
	assert.Equal(suite.T(), 5, recentResult.Limit)
}

func (suite *QueryHandlersTestSuite) TestGetRecentConfigurations_DefaultLimit() {
	// Arrange
	query := GetRecentConfigurationsQuery{
		// No limit specified
	}

	suite.readRepository.On("GetRecentlyModified", suite.ctx, 10).Return([]*domain.Configuration{}, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	recentResult, ok := result.(GetRecentConfigurationsResult)
	assert.True(suite.T(), ok)
	assert.Equal(suite.T(), 10, recentResult.Limit) // Default limit
}

// Test Query Handler Interface Compliance
func (suite *QueryHandlersTestSuite) TestQueryHandler_InterfaceCompliance() {
	// Test that QueryHandlers implements QueryHandler interface
	var handler QueryHandler = suite.queryHandler
	assert.NotNil(suite.T(), handler)
}

// Test Error Handling
func (suite *QueryHandlersTestSuite) TestErrorHandling_InvalidQueries() {
	// Test handling of invalid queries
	invalidQueries := []Query{
		nil,
		"invalid query type",
		123,
	}

	for _, query := range invalidQueries {
		result, err := suite.queryHandler.Handle(suite.ctx, query)
		assert.Error(suite.T(), err)
		assert.Nil(suite.T(), result)
	}
}

// Test Context Cancellation
func (suite *QueryHandlersTestSuite) TestContextCancellation() {
	// Create a cancelled context
	ctx, cancel := context.WithCancel(context.Background())
	cancel()

	query := GetConfigurationQuery{
		ConfigurationID: "test-config",
	}

	// Handle query with cancelled context
	result, err := suite.queryHandler.Handle(ctx, query)

	// Should handle context cancellation gracefully
	assert.Error(suite.T(), err)
	assert.Nil(suite.T(), result)
	assert.Contains(suite.T(), err.Error(), "context")
}

// Test Performance and Pagination
func (suite *QueryHandlersTestSuite) TestQueryPerformance_LargeResultSets() {
	// Test handling of large result sets
	largeConfigSet := make([]*domain.Configuration, 1000)
	profile, _ := domain.NewProfile("dev")

	for i := 0; i < 1000; i++ {
		config, _ := domain.NewConfiguration(*profile, "creator")
		largeConfigSet[i] = config
	}

	query := ListConfigurationsQuery{}
	suite.readRepository.On("GetAll", suite.ctx).Return(largeConfigSet, nil)

	// Act
	result, err := suite.queryHandler.Handle(suite.ctx, query)

	// Assert
	assert.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result)

	listResult, ok := result.(ListConfigurationsResult)
	assert.True(suite.T(), ok)
	assert.Len(suite.T(), listResult.Configurations, 1000)
	assert.Equal(suite.T(), 1000, listResult.TotalCount)
}

// Test Query Result Immutability
func (suite *QueryHandlersTestSuite) TestQueryResult_Immutability() {
	// Test that query results are immutable
	configID := "test-config-id"
	profile, _ := domain.NewProfile("dev")
	config, _ := domain.NewConfiguration(*profile, "creator")

	query := GetConfigurationQuery{
		ConfigurationID: configID,
	}

	suite.readRepository.On("GetByID", suite.ctx, configID).Return(config, nil)

	result, err := suite.queryHandler.Handle(suite.ctx, query)
	assert.NoError(suite.T(), err)

	getResult, ok := result.(GetConfigurationResult)
	assert.True(suite.T(), ok)

	// Try to modify the returned settings map
	originalSize := len(getResult.Settings)
	getResult.Settings["new_key"] = "new_value"

	// Query again and verify original wasn't modified
	result2, err2 := suite.queryHandler.Handle(suite.ctx, query)
	assert.NoError(suite.T(), err2)

	getResult2, ok2 := result2.(GetConfigurationResult)
	assert.True(suite.T(), ok2)
	assert.Equal(suite.T(), originalSize, len(getResult2.Settings))
}

// Run the query handlers test suite
func TestQueryHandlersTestSuite(t *testing.T) {
	suite.Run(t, new(QueryHandlersTestSuite))
}
