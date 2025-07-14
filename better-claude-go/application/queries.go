package application

import (
	"context"
	"fmt"
	"time"

	"better-claude/domain"
)

// Query represents the base interface for all queries
type Query interface {
	QueryID() string
	QueryType() string
	Validate() error
}

// QueryHandler handles queries
type QueryHandler interface {
	Handle(ctx context.Context, query Query) (interface{}, error)
	CanHandle(queryType string) bool
}

// QueryBus manages query routing and execution
type QueryBus interface {
	RegisterHandler(queryType string, handler QueryHandler) error
	Send(ctx context.Context, query Query) (interface{}, error)
}

// GetConfigurationQuery retrieves a configuration by ID
type GetConfigurationQuery struct {
	ID          string `json:"id"`
	AggregateID string `json:"aggregate_id"`
}

func (q GetConfigurationQuery) QueryID() string {
	return q.ID
}

func (q GetConfigurationQuery) QueryType() string {
	return "get_configuration"
}

func (q GetConfigurationQuery) Validate() error {
	if q.AggregateID == "" {
		return fmt.Errorf("aggregate_id is required")
	}
	return nil
}

// GetConfigurationByProfileQuery retrieves a configuration by profile
type GetConfigurationByProfileQuery struct {
	ID      string         `json:"id"`
	Profile domain.Profile `json:"profile"`
}

func (q GetConfigurationByProfileQuery) QueryID() string {
	return q.ID
}

func (q GetConfigurationByProfileQuery) QueryType() string {
	return "get_configuration_by_profile"
}

func (q GetConfigurationByProfileQuery) Validate() error {
	if q.Profile.Value() == "" {
		return fmt.Errorf("profile is required")
	}
	return nil
}

// GetAllConfigurationsQuery retrieves all configurations
type GetAllConfigurationsQuery struct {
	ID string `json:"id"`
}

func (q GetAllConfigurationsQuery) QueryID() string {
	return q.ID
}

func (q GetAllConfigurationsQuery) QueryType() string {
	return "get_all_configurations"
}

func (q GetAllConfigurationsQuery) Validate() error {
	return nil
}

// GetAvailableProfilesQuery retrieves available profiles
type GetAvailableProfilesQuery struct {
	ID string `json:"id"`
}

func (q GetAvailableProfilesQuery) QueryID() string {
	return q.ID
}

func (q GetAvailableProfilesQuery) QueryType() string {
	return "get_available_profiles"
}

func (q GetAvailableProfilesQuery) Validate() error {
	return nil
}

// GetConfigurationHistoryQuery retrieves configuration history (events)
type GetConfigurationHistoryQuery struct {
	ID          string `json:"id"`
	AggregateID string `json:"aggregate_id"`
	FromVersion int    `json:"from_version,omitempty"`
}

func (q GetConfigurationHistoryQuery) QueryID() string {
	return q.ID
}

func (q GetConfigurationHistoryQuery) QueryType() string {
	return "get_configuration_history"
}

func (q GetConfigurationHistoryQuery) Validate() error {
	if q.AggregateID == "" {
		return fmt.Errorf("aggregate_id is required")
	}
	return nil
}

// ConfigurationProjection represents the read model for a configuration
type ConfigurationProjection struct {
	ID               string                     `json:"id"`
	Profile          string                     `json:"profile"`
	Settings         map[string]string          `json:"settings"`
	EnvVariables     map[string]string          `json:"env_variables"`
	Version          int                        `json:"version"`
	CreatedAt        time.Time                  `json:"created_at"`
	LastModifiedAt   time.Time                  `json:"last_modified_at"`
	LastBackupPath   string                     `json:"last_backup_path,omitempty"`
	ValidationStatus ValidationStatusProjection `json:"validation_status"`
}

// ValidationStatusProjection represents the validation status in the read model
type ValidationStatusProjection struct {
	IsValid     bool      `json:"is_valid"`
	LastChecked time.Time `json:"last_checked"`
	ErrorCount  int       `json:"error_count"`
	Errors      []string  `json:"errors,omitempty"`
}

// ProfileProjection represents the read model for a profile
type ProfileProjection struct {
	Name        string            `json:"name"`
	DisplayName string            `json:"display_name"`
	Description string            `json:"description"`
	Settings    map[string]string `json:"settings"`
	IsDefault   bool              `json:"is_default"`
}

// EventProjection represents a domain event in the read model
type EventProjection struct {
	ID          string                 `json:"id"`
	AggregateID string                 `json:"aggregate_id"`
	EventType   string                 `json:"event_type"`
	Version     int                    `json:"version"`
	OccurredAt  time.Time              `json:"occurred_at"`
	Data        map[string]interface{} `json:"data"`
}

// GetConfigurationQueryHandler handles GetConfigurationQuery
type GetConfigurationQueryHandler struct {
	repo domain.ConfigurationRepository
}

func NewGetConfigurationQueryHandler(repo domain.ConfigurationRepository) *GetConfigurationQueryHandler {
	return &GetConfigurationQueryHandler{repo: repo}
}

func (h *GetConfigurationQueryHandler) Handle(ctx context.Context, query Query) (interface{}, error) {
	q, ok := query.(*GetConfigurationQuery)
	if !ok {
		return nil, fmt.Errorf("invalid query type for GetConfigurationQueryHandler")
	}

	if err := q.Validate(); err != nil {
		return nil, fmt.Errorf("query validation failed: %w", err)
	}

	config, err := h.repo.GetByID(ctx, q.AggregateID)
	if err != nil {
		return nil, fmt.Errorf("failed to get configuration: %w", err)
	}

	return h.toProjection(config), nil
}

func (h *GetConfigurationQueryHandler) CanHandle(queryType string) bool {
	return queryType == "get_configuration"
}

func (h *GetConfigurationQueryHandler) toProjection(config *domain.Configuration) *ConfigurationProjection {
	settings := make(map[string]string)
	for k, v := range config.Settings() {
		settings[k.Value()] = v.Value()
	}

	validation := config.GetValidationStatus()

	return &ConfigurationProjection{
		ID:             config.ID(),
		Profile:        config.Profile().Value(),
		Settings:       settings,
		EnvVariables:   config.EnvVariables(),
		Version:        config.Version(),
		LastBackupPath: config.GetLastBackupPath(),
		ValidationStatus: ValidationStatusProjection{
			IsValid:     validation.IsValid,
			LastChecked: validation.LastChecked,
			ErrorCount:  validation.ErrorCount,
			Errors:      validation.Errors,
		},
	}
}

// GetConfigurationByProfileQueryHandler handles GetConfigurationByProfileQuery
type GetConfigurationByProfileQueryHandler struct {
	repo domain.ConfigurationRepository
}

func NewGetConfigurationByProfileQueryHandler(repo domain.ConfigurationRepository) *GetConfigurationByProfileQueryHandler {
	return &GetConfigurationByProfileQueryHandler{repo: repo}
}

func (h *GetConfigurationByProfileQueryHandler) Handle(ctx context.Context, query Query) (interface{}, error) {
	q, ok := query.(*GetConfigurationByProfileQuery)
	if !ok {
		return nil, fmt.Errorf("invalid query type for GetConfigurationByProfileQueryHandler")
	}

	if err := q.Validate(); err != nil {
		return nil, fmt.Errorf("query validation failed: %w", err)
	}

	config, err := h.repo.GetByProfile(ctx, q.Profile)
	if err != nil {
		return nil, fmt.Errorf("failed to get configuration by profile: %w", err)
	}

	getHandler := &GetConfigurationQueryHandler{repo: h.repo}
	return getHandler.toProjection(config), nil
}

func (h *GetConfigurationByProfileQueryHandler) CanHandle(queryType string) bool {
	return queryType == "get_configuration_by_profile"
}

// GetAllConfigurationsQueryHandler handles GetAllConfigurationsQuery
type GetAllConfigurationsQueryHandler struct {
	repo domain.ConfigurationRepository
}

func NewGetAllConfigurationsQueryHandler(repo domain.ConfigurationRepository) *GetAllConfigurationsQueryHandler {
	return &GetAllConfigurationsQueryHandler{repo: repo}
}

func (h *GetAllConfigurationsQueryHandler) Handle(ctx context.Context, query Query) (interface{}, error) {
	q, ok := query.(*GetAllConfigurationsQuery)
	if !ok {
		return nil, fmt.Errorf("invalid query type for GetAllConfigurationsQueryHandler")
	}

	if err := q.Validate(); err != nil {
		return nil, fmt.Errorf("query validation failed: %w", err)
	}

	configs, err := h.repo.GetAll(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get all configurations: %w", err)
	}

	projections := make([]*ConfigurationProjection, len(configs))
	getHandler := &GetConfigurationQueryHandler{repo: h.repo}

	for i, config := range configs {
		projections[i] = getHandler.toProjection(config)
	}

	return projections, nil
}

func (h *GetAllConfigurationsQueryHandler) CanHandle(queryType string) bool {
	return queryType == "get_all_configurations"
}

// GetAvailableProfilesQueryHandler handles GetAvailableProfilesQuery
type GetAvailableProfilesQueryHandler struct {
	profileRepo domain.ProfileRepository
}

func NewGetAvailableProfilesQueryHandler(profileRepo domain.ProfileRepository) *GetAvailableProfilesQueryHandler {
	return &GetAvailableProfilesQueryHandler{profileRepo: profileRepo}
}

func (h *GetAvailableProfilesQueryHandler) Handle(ctx context.Context, query Query) (interface{}, error) {
	q, ok := query.(*GetAvailableProfilesQuery)
	if !ok {
		return nil, fmt.Errorf("invalid query type for GetAvailableProfilesQueryHandler")
	}

	if err := q.Validate(); err != nil {
		return nil, fmt.Errorf("query validation failed: %w", err)
	}

	profiles, err := h.profileRepo.GetAvailableProfiles(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get available profiles: %w", err)
	}

	projections := make([]*ProfileProjection, len(profiles))
	for i, profile := range profiles {
		settings, _ := h.profileRepo.GetProfileSettings(ctx, profile)
		settingsMap := make(map[string]string)
		for k, v := range settings {
			settingsMap[k.Value()] = v.Value()
		}

		projections[i] = &ProfileProjection{
			Name:        profile.Value(),
			DisplayName: h.getDisplayName(profile),
			Description: h.getDescription(profile),
			Settings:    settingsMap,
			IsDefault:   profile.IsEqual(domain.ProfilePersonal),
		}
	}

	return projections, nil
}

func (h *GetAvailableProfilesQueryHandler) CanHandle(queryType string) bool {
	return queryType == "get_available_profiles"
}

func (h *GetAvailableProfilesQueryHandler) getDisplayName(profile domain.Profile) string {
	switch {
	case profile.IsDevelopment():
		return "Development"
	case profile.IsProduction():
		return "Production"
	case profile.IsPersonal():
		return "Personal"
	default:
		return profile.Value()
	}
}

func (h *GetAvailableProfilesQueryHandler) getDescription(profile domain.Profile) string {
	switch {
	case profile.IsDevelopment():
		return "High performance settings optimized for development work"
	case profile.IsProduction():
		return "Conservative settings for production environments"
	case profile.IsPersonal():
		return "Balanced settings for personal use"
	default:
		return "Custom profile configuration"
	}
}

// GetConfigurationHistoryQueryHandler handles GetConfigurationHistoryQuery
type GetConfigurationHistoryQueryHandler struct {
	eventStore domain.EventStore
}

func NewGetConfigurationHistoryQueryHandler(eventStore domain.EventStore) *GetConfigurationHistoryQueryHandler {
	return &GetConfigurationHistoryQueryHandler{eventStore: eventStore}
}

func (h *GetConfigurationHistoryQueryHandler) Handle(ctx context.Context, query Query) (interface{}, error) {
	q, ok := query.(*GetConfigurationHistoryQuery)
	if !ok {
		return nil, fmt.Errorf("invalid query type for GetConfigurationHistoryQueryHandler")
	}

	if err := q.Validate(); err != nil {
		return nil, fmt.Errorf("query validation failed: %w", err)
	}

	var events []domain.DomainEvent
	var err error

	if q.FromVersion > 0 {
		events, err = h.eventStore.GetEventsFromVersion(q.AggregateID, q.FromVersion)
	} else {
		events, err = h.eventStore.GetEvents(q.AggregateID)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get configuration history: %w", err)
	}

	projections := make([]*EventProjection, len(events))
	for i, event := range events {
		projections[i] = &EventProjection{
			ID:          event.EventID(),
			AggregateID: event.AggregateID(),
			EventType:   event.EventType(),
			Version:     event.Version(),
			OccurredAt:  event.OccurredOn(),
			Data:        event.Payload(),
		}
	}

	return projections, nil
}

func (h *GetConfigurationHistoryQueryHandler) CanHandle(queryType string) bool {
	return queryType == "get_configuration_history"
}

// QueryResult represents the result of query execution
type QueryResult struct {
	Success   bool        `json:"success"`
	QueryID   string      `json:"query_id"`
	QueryType string      `json:"query_type"`
	Data      interface{} `json:"data,omitempty"`
	Error     string      `json:"error,omitempty"`
	Metadata  interface{} `json:"metadata,omitempty"`
}

// NewQueryResult creates a new query result
func NewQueryResult(query Query, data interface{}) *QueryResult {
	return &QueryResult{
		QueryID:   query.QueryID(),
		QueryType: query.QueryType(),
		Success:   true,
		Data:      data,
	}
}

// SetError marks the result as failed with an error
func (r *QueryResult) SetError(err error) {
	r.Success = false
	r.Error = err.Error()
	r.Data = nil
}

// SetMetadata sets additional metadata
func (r *QueryResult) SetMetadata(metadata interface{}) {
	r.Metadata = metadata
}
