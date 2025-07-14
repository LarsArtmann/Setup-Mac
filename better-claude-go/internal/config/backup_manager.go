package config

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/bitfield/script"
	"github.com/samber/lo"

	"better-claude/internal/logger"
)

// FileBackupManager implements BackupManager using filesystem with functional patterns
type FileBackupManager struct {
	logger     logger.Logger
	configPath string
	dryRun     bool
}

func NewFileBackupManager(logger logger.Logger, dryRun bool) *FileBackupManager {
	homeDir := lo.Must(os.UserHomeDir())
	return &FileBackupManager{
		logger:     logger,
		configPath: filepath.Join(homeDir, ".claude.json"),
		dryRun:     dryRun,
	}
}

func (b *FileBackupManager) CreateBackup(profile Profile) (string, error) {
	timestamp := time.Now().Format("20060102_150405")
	backupName := fmt.Sprintf("claude-config-%s-%s.json", profile, timestamp)

	homeDir := lo.Must(os.UserHomeDir())
	backupPath := filepath.Join(homeDir, backupName)

	if b.dryRun {
		b.logger.Warning(fmt.Sprintf("[DRY-RUN] Would create backup: %s", backupPath))
		return backupPath, nil
	}

	// Check if source config exists
	if _, err := os.Stat(b.configPath); os.IsNotExist(err) {
		b.logger.Warning("No existing config file to backup")
		return "", nil
	}

	b.logger.Info(fmt.Sprintf("Creating profile-aware backup: %s", backupPath))

	// Copy the file using script library
	content := lo.Must(script.File(b.configPath).String())
	_, err := script.Echo(content).WriteFile(backupPath)
	if err != nil {
		return "", fmt.Errorf("failed to create backup: %w", err)
	}

	b.logger.Success(fmt.Sprintf("✓ Backup created: %s", backupPath))
	return backupPath, nil
}

func (b *FileBackupManager) RestoreBackup(backupPath string) error {
	if b.dryRun {
		b.logger.Warning(fmt.Sprintf("[DRY-RUN] Would restore from backup: %s", backupPath))
		return nil
	}

	// Check if backup exists using functional error handling
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		return fmt.Errorf("backup file not found: %s", backupPath)
	}

	b.logger.Info(fmt.Sprintf("Restoring configuration from backup: %s", backupPath))

	// Copy backup to config location
	content := lo.Must(script.File(backupPath).String())
	_, err := script.Echo(content).WriteFile(b.configPath)
	if err != nil {
		return fmt.Errorf("failed to restore backup: %w", err)
	}

	b.logger.Success("✓ Configuration restored from backup")
	return nil
}

func (b *FileBackupManager) ListBackups() ([]string, error) {
	homeDir := lo.Must(os.UserHomeDir())

	// Find all claude config backup files using functional patterns
	backups, err := script.FindFiles(homeDir).Match("claude-config-*.json").Slice()
	if err != nil {
		return nil, fmt.Errorf("failed to list backups: %w", err)
	}

	// Use samber/lo for functional filtering and transformation
	filteredBackups := lo.Filter(backups, func(backup string, _ int) bool {
		return backup != ""
	})

	if len(filteredBackups) == 0 {
		b.logger.Info("No backups found")
		return []string{}, nil
	}

	return filteredBackups, nil
}
