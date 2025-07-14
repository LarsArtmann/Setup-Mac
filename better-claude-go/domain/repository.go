package domain

import (
	"context"
	"fmt"
)

// ConfigurationRepository defines the interface for persisting Configuration aggregates
type ConfigurationRepository interface {
	Save(ctx context.Context, aggregate *Configuration) error
	GetByID(ctx context.Context, id string) (*Configuration, error)
	GetByProfile(ctx context.Context, profile Profile) (*Configuration, error)
	Exists(ctx context.Context, id string) (bool, error)
	Delete(ctx context.Context, id string) error
	GetAll(ctx context.Context) ([]*Configuration, error)
}

// ProfileRepository defines the interface for managing profiles
type ProfileRepository interface {
	GetAvailableProfiles(ctx context.Context) ([]Profile, error)
	GetDefaultProfile(ctx context.Context) (Profile, error)
	ValidateProfile(ctx context.Context, profile Profile) error
	GetProfileSettings(ctx context.Context, profile Profile) (map[ConfigKey]ConfigValue, error)
}

// BackupRepository defines the interface for managing configuration backups
type BackupRepository interface {
	CreateBackup(ctx context.Context, config *Configuration, path string) error
	RestoreFromBackup(ctx context.Context, path string) (*Configuration, error)
	ListBackups(ctx context.Context) ([]BackupInfo, error)
	DeleteBackup(ctx context.Context, path string) error
	GetBackupInfo(ctx context.Context, path string) (*BackupInfo, error)
}

// BackupInfo represents metadata about a configuration backup
type BackupInfo struct {
	Path         string
	Profile      Profile
	CreatedAt    string
	ConfigCount  int
	FileSize     int64
}

// RepositoryError represents errors from repository operations
type RepositoryError struct {
	Operation string
	ID        string
	Cause     error
}

func (e RepositoryError) Error() string {
	if e.ID != "" {
		return fmt.Sprintf("repository error during %s for ID %s: %v", e.Operation, e.ID, e.Cause)
	}
	return fmt.Sprintf("repository error during %s: %v", e.Operation, e.Cause)
}

// NewRepositoryError creates a new repository error
func NewRepositoryError(operation, id string, cause error) error {
	return RepositoryError{
		Operation: operation,
		ID:        id,
		Cause:     cause,
	}
}

// AggregateNotFoundError is returned when an aggregate is not found
type AggregateNotFoundError struct {
	ID string
}

func (e AggregateNotFoundError) Error() string {
	return fmt.Sprintf("configuration aggregate not found: %s", e.ID)
}

// NewAggregateNotFoundError creates a new aggregate not found error
func NewAggregateNotFoundError(id string) error {
	return AggregateNotFoundError{ID: id}
}

// ConcurrencyError is returned when there's a version conflict
type ConcurrencyError struct {
	AggregateID     string
	ExpectedVersion int
	ActualVersion   int
}

func (e ConcurrencyError) Error() string {
	return fmt.Sprintf("concurrency error for aggregate %s: expected version %d, got %d", 
		e.AggregateID, e.ExpectedVersion, e.ActualVersion)
}

// NewConcurrencyError creates a new concurrency error
func NewConcurrencyError(aggregateID string, expectedVersion, actualVersion int) error {
	return ConcurrencyError{
		AggregateID:     aggregateID,
		ExpectedVersion: expectedVersion,
		ActualVersion:   actualVersion,
	}
}