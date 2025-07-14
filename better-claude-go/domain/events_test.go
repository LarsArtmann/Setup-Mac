package domain

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// DomainEventsTestSuite contains tests for domain events
type DomainEventsTestSuite struct {
	suite.Suite
	testProfile    Profile
	testKey        ConfigKey
	testOldValue   ConfigValue
	testNewValue   ConfigValue
	testAggregateID string
	testSettings   map[ConfigKey]ConfigValue
}

func (suite *DomainEventsTestSuite) SetupTest() {
	profile, _ := NewProfile("dev")
	suite.testProfile = *profile

	key, _ := NewConfigKey("theme")
	suite.testKey = *key

	oldValue, _ := NewConfigValue("light")
	suite.testOldValue = *oldValue

	newValue, _ := NewConfigValue("dark")
	suite.testNewValue = *newValue

	suite.testAggregateID = "test-aggregate-id"
	
	// Create test settings
	suite.testSettings = make(map[ConfigKey]ConfigValue)
	suite.testSettings[suite.testKey] = suite.testNewValue
}

// Test ConfigurationCreated Event
func (suite *DomainEventsTestSuite) TestConfigurationCreated_NewEvent() {
	event := NewConfigurationCreated(
		suite.testAggregateID,
		suite.testProfile,
		suite.testSettings,
		"testUser",
		1,
	)

	assert.NotNil(suite.T(), event)
	assert.Equal(suite.T(), "ConfigurationCreated", event.EventType())
	assert.Equal(suite.T(), suite.testAggregateID, event.AggregateID())
	assert.Equal(suite.T(), 1, event.Version())
	assert.Equal(suite.T(), "testUser", event.CreatedBy)
	assert.True(suite.T(), event.Profile.IsEqual(suite.testProfile))
	assert.NotEmpty(suite.T(), event.EventID())
	assert.WithinDuration(suite.T(), time.Now(), event.OccurredOn(), time.Second)
}

func (suite *DomainEventsTestSuite) TestConfigurationCreated_EventID() {
	event1 := NewConfigurationCreated(suite.testAggregateID, suite.testProfile, suite.testSettings, "user1", 1)
	event2 := NewConfigurationCreated(suite.testAggregateID, suite.testProfile, suite.testSettings, "user2", 1)

	// Each event should have a unique ID
	assert.NotEqual(suite.T(), event1.EventID(), event2.EventID())
	assert.NotEmpty(suite.T(), event1.EventID())
	assert.NotEmpty(suite.T(), event2.EventID())
}

func (suite *DomainEventsTestSuite) TestConfigurationCreated_InitialConfig() {
	event := NewConfigurationCreated(
		suite.testAggregateID,
		suite.testProfile,
		suite.testSettings,
		"testUser",
		1,
	)

	assert.NotNil(suite.T(), event.InitialConfig)
	assert.Equal(suite.T(), len(suite.testSettings), len(event.InitialConfig))
	
	for key, value := range suite.testSettings {
		eventValue, exists := event.InitialConfig[key]
		assert.True(suite.T(), exists)
		assert.True(suite.T(), value.IsEqual(eventValue))
	}
}

// Test ConfigurationChanged Event
func (suite *DomainEventsTestSuite) TestConfigurationChanged_NewEvent() {
	event := NewConfigurationChanged(
		suite.testAggregateID,
		suite.testKey,
		suite.testOldValue,
		suite.testNewValue,
		"testUser",
		suite.testProfile,
		2,
	)

	assert.NotNil(suite.T(), event)
	assert.Equal(suite.T(), "ConfigurationChanged", event.EventType())
	assert.Equal(suite.T(), suite.testAggregateID, event.AggregateID())
	assert.Equal(suite.T(), 2, event.Version())
	assert.Equal(suite.T(), "testUser", event.ChangedBy)
	assert.True(suite.T(), event.Key.IsEqual(suite.testKey))
	assert.True(suite.T(), event.OldValue.IsEqual(suite.testOldValue))
	assert.True(suite.T(), event.NewValue.IsEqual(suite.testNewValue))
	assert.True(suite.T(), event.ProfileActive.IsEqual(suite.testProfile))
}

func (suite *DomainEventsTestSuite) TestConfigurationChanged_ValueChange() {
	event := NewConfigurationChanged(
		suite.testAggregateID,
		suite.testKey,
		suite.testOldValue,
		suite.testNewValue,
		"testUser",
		suite.testProfile,
		2,
	)

	// Verify that old and new values are properly captured
	assert.False(suite.T(), event.OldValue.IsEqual(event.NewValue))
	assert.Equal(suite.T(), "light", event.OldValue.Value())
	assert.Equal(suite.T(), "dark", event.NewValue.Value())
}

// Test ProfileSwitched Event
func (suite *DomainEventsTestSuite) TestProfileSwitched_NewEvent() {
	oldProfile, _ := NewProfile("dev")
	newProfile, _ := NewProfile("prod")
	
	event := NewProfileSwitched(
		suite.testAggregateID,
		*oldProfile,
		*newProfile,
		"testUser",
		5,
		3,
	)

	assert.NotNil(suite.T(), event)
	assert.Equal(suite.T(), "ProfileSwitched", event.EventType())
	assert.Equal(suite.T(), suite.testAggregateID, event.AggregateID())
	assert.Equal(suite.T(), 3, event.Version())
	assert.Equal(suite.T(), "testUser", event.SwitchedBy)
	assert.True(suite.T(), event.OldProfile.IsEqual(*oldProfile))
	assert.True(suite.T(), event.NewProfile.IsEqual(*newProfile))
	assert.Equal(suite.T(), 5, event.ConfigChanges)
}

func (suite *DomainEventsTestSuite) TestProfileSwitched_ProfileChange() {
	oldProfile, _ := NewProfile("personal")
	newProfile, _ := NewProfile("production")
	
	event := NewProfileSwitched(
		suite.testAggregateID,
		*oldProfile,
		*newProfile,
		"testUser",
		3,
		1,
	)

	assert.False(suite.T(), event.OldProfile.IsEqual(event.NewProfile))
	assert.Equal(suite.T(), "personal", event.OldProfile.Value())
	assert.Equal(suite.T(), "production", event.NewProfile.Value())
	assert.Equal(suite.T(), 3, event.ConfigChanges)
}

// Test BackupCreated Event
func (suite *DomainEventsTestSuite) TestBackupCreated_NewEvent() {
	backupPath := "/test/backup/path.tar.gz"
	configCount := 6
	
	event := NewBackupCreated(
		suite.testAggregateID,
		backupPath,
		suite.testProfile,
		"testUser",
		configCount,
		4,
	)

	assert.NotNil(suite.T(), event)
	assert.Equal(suite.T(), "BackupCreated", event.EventType())
	assert.Equal(suite.T(), suite.testAggregateID, event.AggregateID())
	assert.Equal(suite.T(), 4, event.Version())
	assert.Equal(suite.T(), "testUser", event.CreatedBy)
	assert.Equal(suite.T(), backupPath, event.BackupPath)
	assert.True(suite.T(), event.Profile.IsEqual(suite.testProfile))
	assert.Equal(suite.T(), configCount, event.ConfigCount)
}

func (suite *DomainEventsTestSuite) TestBackupCreated_BackupPath() {
	testPaths := []string{
		"/backup/config.tar.gz",
		"./local/backup.zip",
		"../backups/config-backup-20240101.tar",
		"config.backup",
	}

	for _, path := range testPaths {
		event := NewBackupCreated(
			suite.testAggregateID,
			path,
			suite.testProfile,
			"testUser",
			5,
			1,
		)

		assert.Equal(suite.T(), path, event.BackupPath)
	}
}

// Test ConfigurationValidated Event
func (suite *DomainEventsTestSuite) TestConfigurationValidated_NewEvent() {
	event := NewConfigurationValidated(
		suite.testAggregateID,
		suite.testProfile,
		true,
		0,
		"testUser",
		5,
	)

	assert.NotNil(suite.T(), event)
	assert.Equal(suite.T(), "ConfigurationValidated", event.EventType())
	assert.Equal(suite.T(), suite.testAggregateID, event.AggregateID())
	assert.Equal(suite.T(), 5, event.Version())
	assert.Equal(suite.T(), "testUser", event.ValidatedBy)
	assert.True(suite.T(), event.ValidationPassed)
	assert.Equal(suite.T(), 0, event.ErrorCount)
	assert.True(suite.T(), event.Profile.IsEqual(suite.testProfile))
}

func (suite *DomainEventsTestSuite) TestConfigurationValidated_ValidationFailed() {
	event := NewConfigurationValidated(
		suite.testAggregateID,
		suite.testProfile,
		false,
		3,
		"testUser",
		5,
	)

	assert.False(suite.T(), event.ValidationPassed)
	assert.Equal(suite.T(), 3, event.ErrorCount)
}

// Test DomainEvent interface compliance
func (suite *DomainEventsTestSuite) TestDomainEvent_InterfaceCompliance() {
	events := []DomainEvent{
		NewConfigurationCreated(suite.testAggregateID, suite.testProfile, suite.testSettings, "user", 1),
		NewConfigurationChanged(suite.testAggregateID, suite.testKey, suite.testOldValue, suite.testNewValue, "user", suite.testProfile, 2),
		NewProfileSwitched(suite.testAggregateID, suite.testProfile, suite.testProfile, "user", 1, 3),
		NewBackupCreated(suite.testAggregateID, "/path", suite.testProfile, "user", 5, 4),
		NewConfigurationValidated(suite.testAggregateID, suite.testProfile, true, 0, "user", 5),
	}

	for _, event := range events {
		// Test that all events implement the DomainEvent interface correctly
		assert.NotEmpty(suite.T(), event.EventID())
		assert.NotEmpty(suite.T(), event.EventType())
		assert.Equal(suite.T(), suite.testAggregateID, event.AggregateID())
		assert.Greater(suite.T(), event.Version(), 0)
		assert.WithinDuration(suite.T(), time.Now(), event.OccurredOn(), time.Second)
	}
}

// Test Event Timing
func (suite *DomainEventsTestSuite) TestDomainEvent_Timing() {
	before := time.Now()
	event := NewConfigurationCreated(suite.testAggregateID, suite.testProfile, suite.testSettings, "user", 1)
	after := time.Now()

	assert.True(suite.T(), event.OccurredOn().After(before) || event.OccurredOn().Equal(before))
	assert.True(suite.T(), event.OccurredOn().Before(after) || event.OccurredOn().Equal(after))
}

// Test Event Ordering
func (suite *DomainEventsTestSuite) TestDomainEvent_Ordering() {
	event1 := NewConfigurationCreated(suite.testAggregateID, suite.testProfile, suite.testSettings, "user", 1)
	time.Sleep(time.Millisecond) // Ensure different timestamps
	event2 := NewConfigurationChanged(suite.testAggregateID, suite.testKey, suite.testOldValue, suite.testNewValue, "user", suite.testProfile, 2)

	assert.True(suite.T(), event2.OccurredOn().After(event1.OccurredOn()))
	assert.Greater(suite.T(), event2.Version(), event1.Version())
}

// Test Event Data Integrity
func (suite *DomainEventsTestSuite) TestDomainEvent_DataIntegrity() {
	// Test that events capture data correctly and immutably
	originalSettings := make(map[ConfigKey]ConfigValue)
	originalSettings[suite.testKey] = suite.testOldValue

	event := NewConfigurationCreated(suite.testAggregateID, suite.testProfile, originalSettings, "user", 1)

	// Modify original data
	originalSettings[suite.testKey] = suite.testNewValue

	// Event should still have original data
	eventValue, exists := event.InitialConfig[suite.testKey]
	assert.True(suite.T(), exists)
	assert.True(suite.T(), eventValue.IsEqual(suite.testOldValue))
	assert.False(suite.T(), eventValue.IsEqual(suite.testNewValue))
}

// Test Event Serialization Properties
func (suite *DomainEventsTestSuite) TestDomainEvent_SerializationProperties() {
	event := NewConfigurationChanged(
		suite.testAggregateID,
		suite.testKey,
		suite.testOldValue,
		suite.testNewValue,
		"testUser",
		suite.testProfile,
		2,
	)

	// Test that all required fields are present for serialization
	assert.NotEmpty(suite.T(), event.EventID())
	assert.NotEmpty(suite.T(), event.EventType())
	assert.NotEmpty(suite.T(), event.AggregateID())
	assert.NotEmpty(suite.T(), event.ChangedBy)
	assert.NotEmpty(suite.T(), event.Key.Value())
	assert.NotEmpty(suite.T(), event.NewValue.Value())
	// OldValue can be empty in some cases
	assert.NotEmpty(suite.T(), event.ProfileActive.Value())
}

// Test Edge Cases
func (suite *DomainEventsTestSuite) TestDomainEvent_EdgeCases() {
	// Test with empty values where allowed
	emptyValue, _ := NewConfigValue("")
	
	event := NewConfigurationChanged(
		suite.testAggregateID,
		suite.testKey,
		*emptyValue,
		suite.testNewValue,
		"testUser",
		suite.testProfile,
		1,
	)

	assert.True(suite.T(), event.OldValue.IsEmpty())
	assert.False(suite.T(), event.NewValue.IsEmpty())
}

func (suite *DomainEventsTestSuite) TestDomainEvent_LargeConfigChanges() {
	// Test with large number of config changes
	largeChangeCount := 100
	
	event := NewProfileSwitched(
		suite.testAggregateID,
		suite.testProfile,
		ProfileProd,
		"testUser",
		largeChangeCount,
		1,
	)

	assert.Equal(suite.T(), largeChangeCount, event.ConfigChanges)
}

func (suite *DomainEventsTestSuite) TestDomainEvent_ZeroConfigCount() {
	// Test backup with zero configs
	event := NewBackupCreated(
		suite.testAggregateID,
		"/empty/backup/path",
		suite.testProfile,
		"testUser",
		0,
		1,
	)

	assert.Equal(suite.T(), 0, event.ConfigCount)
}

// Test Event Type Constants
func (suite *DomainEventsTestSuite) TestDomainEvent_EventTypes() {
	expectedEventTypes := map[DomainEvent]string{
		NewConfigurationCreated(suite.testAggregateID, suite.testProfile, suite.testSettings, "user", 1):                                                    "ConfigurationCreated",
		NewConfigurationChanged(suite.testAggregateID, suite.testKey, suite.testOldValue, suite.testNewValue, "user", suite.testProfile, 2):                "ConfigurationChanged",
		NewProfileSwitched(suite.testAggregateID, suite.testProfile, ProfileProd, "user", 1, 3):                                                           "ProfileSwitched",
		NewBackupCreated(suite.testAggregateID, "/path", suite.testProfile, "user", 5, 4):                                                                 "BackupCreated",
		NewConfigurationValidated(suite.testAggregateID, suite.testProfile, true, 0, "user", 5):                                                          "ConfigurationValidated",
	}

	for event, expectedType := range expectedEventTypes {
		assert.Equal(suite.T(), expectedType, event.EventType())
	}
}

// Run the domain events test suite
func TestDomainEventsTestSuite(t *testing.T) {
	suite.Run(t, new(DomainEventsTestSuite))
}