package testing

import (
	"better-claude/domain"
)

// TestFixtures provides reusable test data and builders
type TestFixtures struct{}

// NewTestFixtures creates a new test fixtures instance
func NewTestFixtures() *TestFixtures {
	return &TestFixtures{}
}

// ProfileBuilder provides a builder pattern for creating test profiles
type ProfileBuilder struct {
	value string
}

// NewProfileBuilder creates a new profile builder
func NewProfileBuilder() *ProfileBuilder {
	return &ProfileBuilder{value: "dev"}
}

// WithValue sets the profile value
func (b *ProfileBuilder) WithValue(value string) *ProfileBuilder {
	b.value = value
	return b
}

// WithDev sets the profile to development
func (b *ProfileBuilder) WithDev() *ProfileBuilder {
	b.value = "dev"
	return b
}

// WithProd sets the profile to production
func (b *ProfileBuilder) WithProd() *ProfileBuilder {
	b.value = "prod"
	return b
}

// WithPersonal sets the profile to personal
func (b *ProfileBuilder) WithPersonal() *ProfileBuilder {
	b.value = "personal"
	return b
}

// Build creates the profile
func (b *ProfileBuilder) Build() domain.Profile {
	profile, err := domain.NewProfile(b.value)
	if err != nil {
		panic("Invalid profile in test: " + err.Error())
	}
	return *profile
}

// BuildPtr creates a pointer to the profile
func (b *ProfileBuilder) BuildPtr() *domain.Profile {
	profile := b.Build()
	return &profile
}

// ConfigValueBuilder provides a builder pattern for creating test config values
type ConfigValueBuilder struct {
	value string
}

// NewConfigValueBuilder creates a new config value builder
func NewConfigValueBuilder() *ConfigValueBuilder {
	return &ConfigValueBuilder{value: "test-value"}
}

// WithValue sets the config value
func (b *ConfigValueBuilder) WithValue(value string) *ConfigValueBuilder {
	b.value = value
	return b
}

// WithEmpty sets an empty value
func (b *ConfigValueBuilder) WithEmpty() *ConfigValueBuilder {
	b.value = ""
	return b
}

// WithTheme sets a theme value
func (b *ConfigValueBuilder) WithTheme(theme string) *ConfigValueBuilder {
	b.value = theme
	return b
}

// WithDarkTheme sets the dark theme
func (b *ConfigValueBuilder) WithDarkTheme() *ConfigValueBuilder {
	b.value = "dark"
	return b
}

// WithLightTheme sets the light theme
func (b *ConfigValueBuilder) WithLightTheme() *ConfigValueBuilder {
	b.value = "light"
	return b
}

// WithParallelTasksCount sets a parallel tasks count
func (b *ConfigValueBuilder) WithParallelTasksCount(count string) *ConfigValueBuilder {
	b.value = count
	return b
}

// WithAutoUpdates sets auto updates value
func (b *ConfigValueBuilder) WithAutoUpdates(enabled bool) *ConfigValueBuilder {
	if enabled {
		b.value = "true"
	} else {
		b.value = "false"
	}
	return b
}

// Build creates the config value
func (b *ConfigValueBuilder) Build() domain.ConfigValue {
	value, err := domain.NewConfigValue(b.value)
	if err != nil {
		panic("Invalid config value in test: " + err.Error())
	}
	return *value
}

// BuildPtr creates a pointer to the config value
func (b *ConfigValueBuilder) BuildPtr() *domain.ConfigValue {
	value := b.Build()
	return &value
}

// ConfigKeyBuilder provides a builder pattern for creating test config keys
type ConfigKeyBuilder struct {
	value string
}

// NewConfigKeyBuilder creates a new config key builder
func NewConfigKeyBuilder() *ConfigKeyBuilder {
	return &ConfigKeyBuilder{value: "testKey"}
}

// WithValue sets the config key value
func (b *ConfigKeyBuilder) WithValue(value string) *ConfigKeyBuilder {
	b.value = value
	return b
}

// WithTheme sets the theme key
func (b *ConfigKeyBuilder) WithTheme() *ConfigKeyBuilder {
	return &ConfigKeyBuilder{value: "theme"}
}

// WithParallelTasksCount sets the parallel tasks count key
func (b *ConfigKeyBuilder) WithParallelTasksCount() *ConfigKeyBuilder {
	return &ConfigKeyBuilder{value: "parallelTasksCount"}
}

// WithAutoUpdates sets the auto updates key
func (b *ConfigKeyBuilder) WithAutoUpdates() *ConfigKeyBuilder {
	return &ConfigKeyBuilder{value: "autoUpdates"}
}

// Build creates the config key
func (b *ConfigKeyBuilder) Build() domain.ConfigKey {
	key, err := domain.NewConfigKey(b.value)
	if err != nil {
		panic("Invalid config key in test: " + err.Error())
	}
	return *key
}

// BuildPtr creates a pointer to the config key
func (b *ConfigKeyBuilder) BuildPtr() *domain.ConfigKey {
	key := b.Build()
	return &key
}

// ConfigurationBuilder provides a builder pattern for creating test configurations
type ConfigurationBuilder struct {
	profile   domain.Profile
	createdBy string
	settings  map[domain.ConfigKey]domain.ConfigValue
	envVars   map[string]string
}

// NewConfigurationBuilder creates a new configuration builder
func NewConfigurationBuilder() *ConfigurationBuilder {
	profile := NewProfileBuilder().WithDev().Build()
	return &ConfigurationBuilder{
		profile:   profile,
		createdBy: "testUser",
		settings:  make(map[domain.ConfigKey]domain.ConfigValue),
		envVars:   make(map[string]string),
	}
}

// WithProfile sets the profile
func (b *ConfigurationBuilder) WithProfile(profile domain.Profile) *ConfigurationBuilder {
	b.profile = profile
	return b
}

// WithDevProfile sets a development profile
func (b *ConfigurationBuilder) WithDevProfile() *ConfigurationBuilder {
	b.profile = NewProfileBuilder().WithDev().Build()
	return b
}

// WithProdProfile sets a production profile
func (b *ConfigurationBuilder) WithProdProfile() *ConfigurationBuilder {
	b.profile = NewProfileBuilder().WithProd().Build()
	return b
}

// WithPersonalProfile sets a personal profile
func (b *ConfigurationBuilder) WithPersonalProfile() *ConfigurationBuilder {
	b.profile = NewProfileBuilder().WithPersonal().Build()
	return b
}

// WithCreatedBy sets the creator
func (b *ConfigurationBuilder) WithCreatedBy(createdBy string) *ConfigurationBuilder {
	b.createdBy = createdBy
	return b
}

// WithSetting adds a configuration setting
func (b *ConfigurationBuilder) WithSetting(key domain.ConfigKey, value domain.ConfigValue) *ConfigurationBuilder {
	b.settings[key] = value
	return b
}

// WithTheme adds a theme setting
func (b *ConfigurationBuilder) WithTheme(theme string) *ConfigurationBuilder {
	key := NewConfigKeyBuilder().WithTheme().Build()
	value := NewConfigValueBuilder().WithTheme(theme).Build()
	b.settings[key] = value
	return b
}

// WithDarkTheme adds a dark theme setting
func (b *ConfigurationBuilder) WithDarkTheme() *ConfigurationBuilder {
	return b.WithTheme("dark")
}

// WithLightTheme adds a light theme setting
func (b *ConfigurationBuilder) WithLightTheme() *ConfigurationBuilder {
	return b.WithTheme("light")
}

// WithParallelTasksCount adds a parallel tasks count setting
func (b *ConfigurationBuilder) WithParallelTasksCount(count string) *ConfigurationBuilder {
	key := NewConfigKeyBuilder().WithParallelTasksCount().Build()
	value := NewConfigValueBuilder().WithParallelTasksCount(count).Build()
	b.settings[key] = value
	return b
}

// WithAutoUpdates adds an auto updates setting
func (b *ConfigurationBuilder) WithAutoUpdates(enabled bool) *ConfigurationBuilder {
	key := NewConfigKeyBuilder().WithAutoUpdates().Build()
	value := NewConfigValueBuilder().WithAutoUpdates(enabled).Build()
	b.settings[key] = value
	return b
}

// WithEnvVar adds an environment variable
func (b *ConfigurationBuilder) WithEnvVar(name, value string) *ConfigurationBuilder {
	b.envVars[name] = value
	return b
}

// WithEditorEnv adds an EDITOR environment variable
func (b *ConfigurationBuilder) WithEditorEnv(editor string) *ConfigurationBuilder {
	b.envVars["EDITOR"] = editor
	return b
}

// WithTelemetryEnabled adds telemetry environment variable
func (b *ConfigurationBuilder) WithTelemetryEnabled() *ConfigurationBuilder {
	b.envVars["CLAUDE_CODE_ENABLE_TELEMETRY"] = "1"
	return b
}

// WithTelemetryDisabled adds telemetry environment variable
func (b *ConfigurationBuilder) WithTelemetryDisabled() *ConfigurationBuilder {
	b.envVars["CLAUDE_CODE_ENABLE_TELEMETRY"] = "0"
	return b
}

// Build creates the configuration
func (b *ConfigurationBuilder) Build() *domain.Configuration {
	config, err := domain.NewConfiguration(b.profile, b.createdBy)
	if err != nil {
		panic("Invalid configuration in test: " + err.Error())
	}

	// Apply custom settings
	for key, value := range b.settings {
		err := config.ChangeConfiguration(key, value, b.createdBy)
		if err != nil {
			panic("Failed to set configuration in test: " + err.Error())
		}
	}

	// Mark events as committed to clean up for testing
	config.MarkEventsAsCommitted()

	return config
}

// BuildWithEvents creates the configuration and returns it with uncommitted events
func (b *ConfigurationBuilder) BuildWithEvents() *domain.Configuration {
	config, err := domain.NewConfiguration(b.profile, b.createdBy)
	if err != nil {
		panic("Invalid configuration in test: " + err.Error())
	}

	// Apply custom settings (events will remain uncommitted)
	for key, value := range b.settings {
		err := config.ChangeConfiguration(key, value, b.createdBy)
		if err != nil {
			panic("Failed to set configuration in test: " + err.Error())
		}
	}

	return config
}

// DomainEventBuilder provides a builder pattern for creating test domain events
type DomainEventBuilder struct {
	eventType   string
	aggregateID string
	version     int
	profile     domain.Profile
}

// NewDomainEventBuilder creates a new domain event builder
func NewDomainEventBuilder() *DomainEventBuilder {
	return &DomainEventBuilder{
		eventType:   "ConfigurationCreated",
		aggregateID: "test-aggregate-id",
		version:     1,
		profile:     NewProfileBuilder().WithDev().Build(),
	}
}

// WithEventType sets the event type
func (b *DomainEventBuilder) WithEventType(eventType string) *DomainEventBuilder {
	b.eventType = eventType
	return b
}

// WithAggregateID sets the aggregate ID
func (b *DomainEventBuilder) WithAggregateID(aggregateID string) *DomainEventBuilder {
	b.aggregateID = aggregateID
	return b
}

// WithVersion sets the version
func (b *DomainEventBuilder) WithVersion(version int) *DomainEventBuilder {
	b.version = version
	return b
}

// WithProfile sets the profile
func (b *DomainEventBuilder) WithProfile(profile domain.Profile) *DomainEventBuilder {
	b.profile = profile
	return b
}

// BuildConfigurationCreated creates a ConfigurationCreated event
func (b *DomainEventBuilder) BuildConfigurationCreated() *domain.ConfigurationCreated {
	settings := make(map[domain.ConfigKey]domain.ConfigValue)
	themeKey := NewConfigKeyBuilder().WithTheme().Build()
	themeValue := NewConfigValueBuilder().WithDarkTheme().Build()
	settings[themeKey] = themeValue

	return domain.NewConfigurationCreated(
		b.aggregateID,
		b.profile,
		settings,
		"testUser",
		b.version,
	)
}

// BuildConfigurationChanged creates a ConfigurationChanged event
func (b *DomainEventBuilder) BuildConfigurationChanged() *domain.ConfigurationChanged {
	key := NewConfigKeyBuilder().WithTheme().Build()
	oldValue := NewConfigValueBuilder().WithLightTheme().Build()
	newValue := NewConfigValueBuilder().WithDarkTheme().Build()

	return domain.NewConfigurationChanged(
		b.aggregateID,
		key,
		oldValue,
		newValue,
		"testUser",
		b.profile,
		b.version,
	)
}

// BuildProfileSwitched creates a ProfileSwitched event
func (b *DomainEventBuilder) BuildProfileSwitched() *domain.ProfileSwitched {
	oldProfile := NewProfileBuilder().WithDev().Build()
	newProfile := NewProfileBuilder().WithProd().Build()

	return domain.NewProfileSwitched(
		b.aggregateID,
		oldProfile,
		newProfile,
		"testUser",
		3,
		b.version,
	)
}

// TestScenarios provides common test scenarios
type TestScenarios struct {
	fixtures *TestFixtures
}

// NewTestScenarios creates a new test scenarios instance
func NewTestScenarios() *TestScenarios {
	return &TestScenarios{
		fixtures: NewTestFixtures(),
	}
}

// ValidDevConfiguration creates a valid development configuration
func (s *TestScenarios) ValidDevConfiguration() *domain.Configuration {
	return NewConfigurationBuilder().
		WithDevProfile().
		WithDarkTheme().
		WithParallelTasksCount("50").
		WithAutoUpdates(false).
		WithTelemetryEnabled().
		WithEditorEnv("nano").
		Build()
}

// ValidProdConfiguration creates a valid production configuration
func (s *TestScenarios) ValidProdConfiguration() *domain.Configuration {
	return NewConfigurationBuilder().
		WithProdProfile().
		WithDarkTheme().
		WithParallelTasksCount("10").
		WithAutoUpdates(false).
		WithTelemetryDisabled().
		WithEditorEnv("nano").
		Build()
}

// ValidPersonalConfiguration creates a valid personal configuration
func (s *TestScenarios) ValidPersonalConfiguration() *domain.Configuration {
	return NewConfigurationBuilder().
		WithPersonalProfile().
		WithLightTheme().
		WithParallelTasksCount("20").
		WithAutoUpdates(true).
		WithTelemetryEnabled().
		WithEditorEnv("nano").
		Build()
}

// InvalidConfiguration creates an invalid configuration for testing error cases
func (s *TestScenarios) InvalidConfiguration() *domain.Configuration {
	config := NewConfigurationBuilder().
		WithDevProfile().
		WithCreatedBy("testUser").
		Build()

	// Add invalid settings
	invalidTheme := NewConfigValueBuilder().WithEmpty().Build()
	config.ChangeConfiguration(domain.ConfigKeyTheme, invalidTheme, "testUser")

	return config
}

// ConfigurationWithValidationErrors creates a configuration with validation errors
func (s *TestScenarios) ConfigurationWithValidationErrors() *domain.Configuration {
	config := NewConfigurationBuilder().
		WithDevProfile().
		Build()

	// Add multiple invalid settings
	emptyTheme := NewConfigValueBuilder().WithEmpty().Build()
	config.ChangeConfiguration(domain.ConfigKeyTheme, emptyTheme, "testUser")

	invalidCount := NewConfigValueBuilder().WithValue("invalid").Build()
	config.ChangeConfiguration(domain.ConfigKeyParallelTasksCount, invalidCount, "testUser")

	// Run validation to set error status
	config.ValidateConfiguration("testValidator")

	return config
}

// ConfigurationWithEvents creates a configuration with uncommitted events
func (s *TestScenarios) ConfigurationWithEvents() *domain.Configuration {
	return NewConfigurationBuilder().
		WithDevProfile().
		WithDarkTheme().
		WithParallelTasksCount("50").
		BuildWithEvents()
}

// MultipleConfigurations creates multiple configurations for testing
func (s *TestScenarios) MultipleConfigurations() []*domain.Configuration {
	return []*domain.Configuration{
		s.ValidDevConfiguration(),
		s.ValidProdConfiguration(),
		s.ValidPersonalConfiguration(),
	}
}

// EventSequence creates a sequence of domain events
func (s *TestScenarios) EventSequence() []domain.DomainEvent {
	builder := NewDomainEventBuilder().WithAggregateID("test-config")

	return []domain.DomainEvent{
		builder.WithVersion(1).BuildConfigurationCreated(),
		builder.WithVersion(2).BuildConfigurationChanged(),
		builder.WithVersion(3).BuildProfileSwitched(),
	}
}

// CommonProfiles returns commonly used profiles for testing
func (s *TestScenarios) CommonProfiles() []domain.Profile {
	return []domain.Profile{
		NewProfileBuilder().WithDev().Build(),
		NewProfileBuilder().WithProd().Build(),
		NewProfileBuilder().WithPersonal().Build(),
	}
}

// CommonConfigKeys returns commonly used config keys for testing
func (s *TestScenarios) CommonConfigKeys() []domain.ConfigKey {
	return []domain.ConfigKey{
		domain.ConfigKeyTheme,
		domain.ConfigKeyParallelTasksCount,
		domain.ConfigKeyAutoUpdates,
		domain.ConfigKeyPreferredNotifChannel,
		domain.ConfigKeyDiffTool,
	}
}

// CommonConfigValues returns commonly used config values for testing
func (s *TestScenarios) CommonConfigValues() []domain.ConfigValue {
	return []domain.ConfigValue{
		NewConfigValueBuilder().WithDarkTheme().Build(),
		NewConfigValueBuilder().WithLightTheme().Build(),
		NewConfigValueBuilder().WithParallelTasksCount("20").Build(),
		NewConfigValueBuilder().WithAutoUpdates(true).Build(),
		NewConfigValueBuilder().WithAutoUpdates(false).Build(),
	}
}

// ValidationTestCases returns test cases for validation testing
func (s *TestScenarios) ValidationTestCases() []ValidationTestCase {
	return []ValidationTestCase{
		{
			Name:        "Valid dark theme",
			Key:         domain.ConfigKeyTheme,
			Value:       NewConfigValueBuilder().WithDarkTheme().Build(),
			ShouldError: false,
		},
		{
			Name:        "Invalid theme",
			Key:         domain.ConfigKeyTheme,
			Value:       NewConfigValueBuilder().WithValue("invalid-theme").Build(),
			ShouldError: true,
		},
		{
			Name:        "Empty theme",
			Key:         domain.ConfigKeyTheme,
			Value:       NewConfigValueBuilder().WithEmpty().Build(),
			ShouldError: true,
		},
		{
			Name:        "Valid parallel tasks count",
			Key:         domain.ConfigKeyParallelTasksCount,
			Value:       NewConfigValueBuilder().WithParallelTasksCount("50").Build(),
			ShouldError: false,
		},
		{
			Name:        "Invalid parallel tasks count",
			Key:         domain.ConfigKeyParallelTasksCount,
			Value:       NewConfigValueBuilder().WithValue("invalid").Build(),
			ShouldError: true,
		},
		{
			Name:        "Valid auto updates true",
			Key:         domain.ConfigKeyAutoUpdates,
			Value:       NewConfigValueBuilder().WithAutoUpdates(true).Build(),
			ShouldError: false,
		},
		{
			Name:        "Valid auto updates false",
			Key:         domain.ConfigKeyAutoUpdates,
			Value:       NewConfigValueBuilder().WithAutoUpdates(false).Build(),
			ShouldError: false,
		},
		{
			Name:        "Invalid auto updates",
			Key:         domain.ConfigKeyAutoUpdates,
			Value:       NewConfigValueBuilder().WithValue("maybe").Build(),
			ShouldError: true,
		},
	}
}

// ValidationTestCase represents a test case for validation
type ValidationTestCase struct {
	Name        string
	Key         domain.ConfigKey
	Value       domain.ConfigValue
	ShouldError bool
}

// PerformanceTestData creates large datasets for performance testing
type PerformanceTestData struct{}

// LargeConfigurationSet creates a large set of configurations
func (p *PerformanceTestData) LargeConfigurationSet(size int) []*domain.Configuration {
	configs := make([]*domain.Configuration, size)
	profiles := []domain.Profile{
		NewProfileBuilder().WithDev().Build(),
		NewProfileBuilder().WithProd().Build(),
		NewProfileBuilder().WithPersonal().Build(),
	}

	for i := 0; i < size; i++ {
		profile := profiles[i%len(profiles)]
		config := NewConfigurationBuilder().
			WithProfile(profile).
			WithCreatedBy("perfTestUser").
			WithDarkTheme().
			WithParallelTasksCount("20").
			Build()
		configs[i] = config
	}

	return configs
}

// LargeEventSequence creates a large sequence of events
func (p *PerformanceTestData) LargeEventSequence(size int) []domain.DomainEvent {
	events := make([]domain.DomainEvent, size)
	builder := NewDomainEventBuilder()

	for i := 0; i < size; i++ {
		switch i % 3 {
		case 0:
			events[i] = builder.WithVersion(i + 1).BuildConfigurationCreated()
		case 1:
			events[i] = builder.WithVersion(i + 1).BuildConfigurationChanged()
		case 2:
			events[i] = builder.WithVersion(i + 1).BuildProfileSwitched()
		}
	}

	return events
}

// Helper functions for common test assertions
func AssertConfigurationValid(config *domain.Configuration) bool {
	errors := config.ValidateConfiguration("testValidator")
	return len(errors) == 0
}

func AssertEventsPublished(events []domain.DomainEvent, expectedCount int) bool {
	return len(events) == expectedCount
}

func AssertProfileEquals(actual, expected domain.Profile) bool {
	return actual.IsEqual(expected)
}

func AssertConfigValueEquals(actual, expected domain.ConfigValue) bool {
	return actual.IsEqual(expected)
}

func MustCreateProfile(value string) domain.Profile {
	profile, err := domain.NewProfile(value)
	if err != nil {
		panic("Invalid profile in test: " + err.Error())
	}
	return *profile
}

func MustCreateConfigKey(value string) domain.ConfigKey {
	key, err := domain.NewConfigKey(value)
	if err != nil {
		panic("Invalid config key in test: " + err.Error())
	}
	return *key
}

func MustCreateConfigValue(value string) domain.ConfigValue {
	configValue, err := domain.NewConfigValue(value)
	if err != nil {
		panic("Invalid config value in test: " + err.Error())
	}
	return *configValue
}
