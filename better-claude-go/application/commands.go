package application

import (
	"context"
	"fmt"

	"better-claude/domain"
)

// Command represents the base interface for all commands
type Command interface {
	CommandID() string
	CommandType() string
	Validate() error
}

// CommandHandler handles commands
type CommandHandler interface {
	Handle(ctx context.Context, command Command) error
	CanHandle(commandType string) bool
}

// CommandBus manages command routing and execution
type CommandBus interface {
	RegisterHandler(commandType string, handler CommandHandler) error
	Send(ctx context.Context, command Command) error
}

// CreateConfigurationCommand creates a new configuration
type CreateConfigurationCommand struct {
	ID        string         `json:"id"`
	Profile   domain.Profile `json:"profile"`
	CreatedBy string         `json:"created_by"`
}

func (c CreateConfigurationCommand) CommandID() string {
	return c.ID
}

func (c CreateConfigurationCommand) CommandType() string {
	return "create_configuration"
}

func (c CreateConfigurationCommand) Validate() error {
	if c.Profile.Value() == "" {
		return fmt.Errorf("profile is required")
	}
	if c.CreatedBy == "" {
		return fmt.Errorf("created_by is required")
	}
	return nil
}

// ChangeConfigurationCommand updates a configuration setting
type ChangeConfigurationCommand struct {
	ID          string             `json:"id"`
	AggregateID string             `json:"aggregate_id"`
	Key         domain.ConfigKey   `json:"key"`
	Value       domain.ConfigValue `json:"value"`
	ChangedBy   string             `json:"changed_by"`
}

func (c ChangeConfigurationCommand) CommandID() string {
	return c.ID
}

func (c ChangeConfigurationCommand) CommandType() string {
	return "change_configuration"
}

func (c ChangeConfigurationCommand) Validate() error {
	if c.AggregateID == "" {
		return fmt.Errorf("aggregate_id is required")
	}
	if c.Key.Value() == "" {
		return fmt.Errorf("key is required")
	}
	if c.ChangedBy == "" {
		return fmt.Errorf("changed_by is required")
	}
	return nil
}

// SwitchProfileCommand switches the active profile
type SwitchProfileCommand struct {
	ID          string         `json:"id"`
	AggregateID string         `json:"aggregate_id"`
	NewProfile  domain.Profile `json:"new_profile"`
	SwitchedBy  string         `json:"switched_by"`
}

func (c SwitchProfileCommand) CommandID() string {
	return c.ID
}

func (c SwitchProfileCommand) CommandType() string {
	return "switch_profile"
}

func (c SwitchProfileCommand) Validate() error {
	if c.AggregateID == "" {
		return fmt.Errorf("aggregate_id is required")
	}
	if c.NewProfile.Value() == "" {
		return fmt.Errorf("new_profile is required")
	}
	if c.SwitchedBy == "" {
		return fmt.Errorf("switched_by is required")
	}
	return nil
}

// CreateBackupCommand creates a backup of the configuration
type CreateBackupCommand struct {
	ID          string `json:"id"`
	AggregateID string `json:"aggregate_id"`
	BackupPath  string `json:"backup_path"`
	CreatedBy   string `json:"created_by"`
}

func (c CreateBackupCommand) CommandID() string {
	return c.ID
}

func (c CreateBackupCommand) CommandType() string {
	return "create_backup"
}

func (c CreateBackupCommand) Validate() error {
	if c.AggregateID == "" {
		return fmt.Errorf("aggregate_id is required")
	}
	if c.BackupPath == "" {
		return fmt.Errorf("backup_path is required")
	}
	if c.CreatedBy == "" {
		return fmt.Errorf("created_by is required")
	}
	return nil
}

// ValidateConfigurationCommand validates a configuration
type ValidateConfigurationCommand struct {
	ID          string `json:"id"`
	AggregateID string `json:"aggregate_id"`
	ValidatedBy string `json:"validated_by"`
}

func (c ValidateConfigurationCommand) CommandID() string {
	return c.ID
}

func (c ValidateConfigurationCommand) CommandType() string {
	return "validate_configuration"
}

func (c ValidateConfigurationCommand) Validate() error {
	if c.AggregateID == "" {
		return fmt.Errorf("aggregate_id is required")
	}
	if c.ValidatedBy == "" {
		return fmt.Errorf("validated_by is required")
	}
	return nil
}

// CreateConfigurationCommandHandler handles CreateConfigurationCommand
type CreateConfigurationCommandHandler struct {
	repo domain.ConfigurationRepository
}

func NewCreateConfigurationCommandHandler(repo domain.ConfigurationRepository) *CreateConfigurationCommandHandler {
	return &CreateConfigurationCommandHandler{repo: repo}
}

func (h *CreateConfigurationCommandHandler) Handle(ctx context.Context, command Command) error {
	cmd, ok := command.(*CreateConfigurationCommand)
	if !ok {
		return fmt.Errorf("invalid command type for CreateConfigurationCommandHandler")
	}

	if err := cmd.Validate(); err != nil {
		return fmt.Errorf("command validation failed: %w", err)
	}

	// Create new configuration aggregate
	config, err := domain.NewConfiguration(cmd.Profile, cmd.CreatedBy)
	if err != nil {
		return fmt.Errorf("failed to create configuration: %w", err)
	}

	// Save the aggregate
	if err := h.repo.Save(ctx, config); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	return nil
}

func (h *CreateConfigurationCommandHandler) CanHandle(commandType string) bool {
	return commandType == "create_configuration"
}

// ChangeConfigurationCommandHandler handles ChangeConfigurationCommand
type ChangeConfigurationCommandHandler struct {
	repo domain.ConfigurationRepository
}

func NewChangeConfigurationCommandHandler(repo domain.ConfigurationRepository) *ChangeConfigurationCommandHandler {
	return &ChangeConfigurationCommandHandler{repo: repo}
}

func (h *ChangeConfigurationCommandHandler) Handle(ctx context.Context, command Command) error {
	cmd, ok := command.(*ChangeConfigurationCommand)
	if !ok {
		return fmt.Errorf("invalid command type for ChangeConfigurationCommandHandler")
	}

	if err := cmd.Validate(); err != nil {
		return fmt.Errorf("command validation failed: %w", err)
	}

	// Get the configuration aggregate
	config, err := h.repo.GetByID(ctx, cmd.AggregateID)
	if err != nil {
		return fmt.Errorf("failed to get configuration: %w", err)
	}

	// Change the configuration
	if err := config.ChangeConfiguration(cmd.Key, cmd.Value, cmd.ChangedBy); err != nil {
		return fmt.Errorf("failed to change configuration: %w", err)
	}

	// Save the aggregate
	if err := h.repo.Save(ctx, config); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	return nil
}

func (h *ChangeConfigurationCommandHandler) CanHandle(commandType string) bool {
	return commandType == "change_configuration"
}

// SwitchProfileCommandHandler handles SwitchProfileCommand
type SwitchProfileCommandHandler struct {
	repo domain.ConfigurationRepository
}

func NewSwitchProfileCommandHandler(repo domain.ConfigurationRepository) *SwitchProfileCommandHandler {
	return &SwitchProfileCommandHandler{repo: repo}
}

func (h *SwitchProfileCommandHandler) Handle(ctx context.Context, command Command) error {
	cmd, ok := command.(*SwitchProfileCommand)
	if !ok {
		return fmt.Errorf("invalid command type for SwitchProfileCommandHandler")
	}

	if err := cmd.Validate(); err != nil {
		return fmt.Errorf("command validation failed: %w", err)
	}

	// Get the configuration aggregate
	config, err := h.repo.GetByID(ctx, cmd.AggregateID)
	if err != nil {
		return fmt.Errorf("failed to get configuration: %w", err)
	}

	// Switch the profile
	if err := config.SwitchProfile(cmd.NewProfile, cmd.SwitchedBy); err != nil {
		return fmt.Errorf("failed to switch profile: %w", err)
	}

	// Save the aggregate
	if err := h.repo.Save(ctx, config); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	return nil
}

func (h *SwitchProfileCommandHandler) CanHandle(commandType string) bool {
	return commandType == "switch_profile"
}

// CreateBackupCommandHandler handles CreateBackupCommand
type CreateBackupCommandHandler struct {
	repo domain.ConfigurationRepository
}

func NewCreateBackupCommandHandler(repo domain.ConfigurationRepository) *CreateBackupCommandHandler {
	return &CreateBackupCommandHandler{repo: repo}
}

func (h *CreateBackupCommandHandler) Handle(ctx context.Context, command Command) error {
	cmd, ok := command.(*CreateBackupCommand)
	if !ok {
		return fmt.Errorf("invalid command type for CreateBackupCommandHandler")
	}

	if err := cmd.Validate(); err != nil {
		return fmt.Errorf("command validation failed: %w", err)
	}

	// Get the configuration aggregate
	config, err := h.repo.GetByID(ctx, cmd.AggregateID)
	if err != nil {
		return fmt.Errorf("failed to get configuration: %w", err)
	}

	// Create the backup
	if err := config.CreateBackup(cmd.BackupPath, cmd.CreatedBy); err != nil {
		return fmt.Errorf("failed to create backup: %w", err)
	}

	// Save the aggregate
	if err := h.repo.Save(ctx, config); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	return nil
}

func (h *CreateBackupCommandHandler) CanHandle(commandType string) bool {
	return commandType == "create_backup"
}

// ValidateConfigurationCommandHandler handles ValidateConfigurationCommand
type ValidateConfigurationCommandHandler struct {
	repo domain.ConfigurationRepository
}

func NewValidateConfigurationCommandHandler(repo domain.ConfigurationRepository) *ValidateConfigurationCommandHandler {
	return &ValidateConfigurationCommandHandler{repo: repo}
}

func (h *ValidateConfigurationCommandHandler) Handle(ctx context.Context, command Command) error {
	cmd, ok := command.(*ValidateConfigurationCommand)
	if !ok {
		return fmt.Errorf("invalid command type for ValidateConfigurationCommandHandler")
	}

	if err := cmd.Validate(); err != nil {
		return fmt.Errorf("command validation failed: %w", err)
	}

	// Get the configuration aggregate
	config, err := h.repo.GetByID(ctx, cmd.AggregateID)
	if err != nil {
		return fmt.Errorf("failed to get configuration: %w", err)
	}

	// Validate the configuration
	config.ValidateConfiguration(cmd.ValidatedBy)

	// Save the aggregate
	if err := h.repo.Save(ctx, config); err != nil {
		return fmt.Errorf("failed to save configuration: %w", err)
	}

	return nil
}

func (h *ValidateConfigurationCommandHandler) CanHandle(commandType string) bool {
	return commandType == "validate_configuration"
}

// CommandResult represents the result of command execution
type CommandResult struct {
	Success     bool        `json:"success"`
	CommandID   string      `json:"command_id"`
	CommandType string      `json:"command_type"`
	Error       string      `json:"error,omitempty"`
	AggregateID string      `json:"aggregate_id,omitempty"`
	Version     int         `json:"version,omitempty"`
	Metadata    interface{} `json:"metadata,omitempty"`
}

// NewCommandResult creates a new command result
func NewCommandResult(command Command) *CommandResult {
	return &CommandResult{
		CommandID:   command.CommandID(),
		CommandType: command.CommandType(),
		Success:     true,
	}
}

// SetError marks the result as failed with an error
func (r *CommandResult) SetError(err error) {
	r.Success = false
	r.Error = err.Error()
}

// SetAggregateInfo sets aggregate information
func (r *CommandResult) SetAggregateInfo(aggregateID string, version int) {
	r.AggregateID = aggregateID
	r.Version = version
}

// SetMetadata sets additional metadata
func (r *CommandResult) SetMetadata(metadata interface{}) {
	r.Metadata = metadata
}
