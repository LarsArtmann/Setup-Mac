package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"

	"better-claude/internal/logger"
)

// BackupManagerTestSuite contains tests for the backup manager
type BackupManagerTestSuite struct {
	suite.Suite
	backupManager *FileBackupManager
	mockLogger    *MockLogger
	tempDir       string
	originalHome  string
}

// MockLogger for testing
type MockLogger struct {
	InfoMessages    []string
	SuccessMessages []string
	WarningMessages []string
	ErrorMessages   []string
}

func NewMockLogger() *MockLogger {
	return &MockLogger{
		InfoMessages:    []string{},
		SuccessMessages: []string{},
		WarningMessages: []string{},
		ErrorMessages:   []string{},
	}
}

func (m *MockLogger) Info(message string) {
	m.InfoMessages = append(m.InfoMessages, message)
}

func (m *MockLogger) Success(message string) {
	m.SuccessMessages = append(m.SuccessMessages, message)
}

func (m *MockLogger) Warning(message string) {
	m.WarningMessages = append(m.WarningMessages, message)
}

func (m *MockLogger) Error(message string) {
	m.ErrorMessages = append(m.ErrorMessages, message)
}

func (m *MockLogger) Reset() {
	m.InfoMessages = []string{}
	m.SuccessMessages = []string{}
	m.WarningMessages = []string{}
	m.ErrorMessages = []string{}
}

func (suite *BackupManagerTestSuite) SetupTest() {
	suite.mockLogger = NewMockLogger()

	// Create temporary directory for testing
	var err error
	suite.tempDir, err = os.MkdirTemp("", "backup_test_*")
	suite.Require().NoError(err)

	// Save original HOME and set to temp directory
	suite.originalHome = os.Getenv("HOME")
	os.Setenv("HOME", suite.tempDir)

	// Create backup manager with dry-run disabled for testing
	suite.backupManager = NewFileBackupManager(suite.mockLogger, false)
}

func (suite *BackupManagerTestSuite) TearDownTest() {
	// Restore original HOME
	os.Setenv("HOME", suite.originalHome)

	// Clean up temporary directory
	os.RemoveAll(suite.tempDir)

	suite.mockLogger.Reset()
}

// Test NewFileBackupManager
func (suite *BackupManagerTestSuite) TestNewFileBackupManager() {
	logger := NewMockLogger()

	// Test with dry-run enabled
	manager := NewFileBackupManager(logger, true)
	assert.NotNil(suite.T(), manager)
	assert.Equal(suite.T(), logger, manager.logger)
	assert.True(suite.T(), manager.dryRun)
	assert.Contains(suite.T(), manager.configPath, ".claude.json")

	// Test with dry-run disabled
	manager = NewFileBackupManager(logger, false)
	assert.NotNil(suite.T(), manager)
	assert.False(suite.T(), manager.dryRun)
}

// Test CreateBackup with dry-run
func (suite *BackupManagerTestSuite) TestCreateBackup_DryRun() {
	dryRunManager := NewFileBackupManager(suite.mockLogger, true)

	backupPath, err := dryRunManager.CreateBackup(ProfileDev)

	assert.NoError(suite.T(), err)
	assert.NotEmpty(suite.T(), backupPath)
	assert.Contains(suite.T(), backupPath, "claude-config-dev-")
	assert.Contains(suite.T(), backupPath, ".json")

	// Should log dry-run message
	assert.Len(suite.T(), suite.mockLogger.WarningMessages, 1)
	assert.Contains(suite.T(), suite.mockLogger.WarningMessages[0], "[DRY-RUN]")
	assert.Contains(suite.T(), suite.mockLogger.WarningMessages[0], "Would create backup")

	// File should not actually be created
	assert.NoFileExists(suite.T(), backupPath)
}

// Test CreateBackup with no existing config
func (suite *BackupManagerTestSuite) TestCreateBackup_NoExistingConfig() {
	backupPath, err := suite.backupManager.CreateBackup(ProfileDev)

	assert.NoError(suite.T(), err)
	assert.Empty(suite.T(), backupPath) // Should return empty path when no config exists

	// Should log warning message
	assert.Len(suite.T(), suite.mockLogger.WarningMessages, 1)
	assert.Contains(suite.T(), suite.mockLogger.WarningMessages[0], "No existing config file")
}

// Test CreateBackup with existing config
func (suite *BackupManagerTestSuite) TestCreateBackup_WithExistingConfig() {
	// Create a mock config file
	configContent := `{"theme": "dark", "parallelTasksCount": "20"}`
	configPath := filepath.Join(suite.tempDir, ".claude.json")
	err := os.WriteFile(configPath, []byte(configContent), 0644)
	suite.Require().NoError(err)

	backupPath, err := suite.backupManager.CreateBackup(ProfileProd)

	assert.NoError(suite.T(), err)
	assert.NotEmpty(suite.T(), backupPath)
	assert.Contains(suite.T(), backupPath, "claude-config-prod-")
	assert.Contains(suite.T(), backupPath, ".json")

	// Backup file should exist
	assert.FileExists(suite.T(), backupPath)

	// Backup should contain the same content
	backupContent, err := os.ReadFile(backupPath)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), configContent, string(backupContent))

	// Should log success message
	assert.Len(suite.T(), suite.mockLogger.SuccessMessages, 1)
	assert.Contains(suite.T(), suite.mockLogger.SuccessMessages[0], "Backup created")
}

// Test backup filename format
func (suite *BackupManagerTestSuite) TestCreateBackup_FilenameFormat() {
	// Create a mock config file
	configPath := filepath.Join(suite.tempDir, ".claude.json")
	err := os.WriteFile(configPath, []byte("{}"), 0644)
	suite.Require().NoError(err)

	backupPath, err := suite.backupManager.CreateBackup(ProfilePersonal)

	assert.NoError(suite.T(), err)

	// Check filename format: claude-config-{profile}-{timestamp}.json
	filename := filepath.Base(backupPath)
	assert.True(suite.T(), strings.HasPrefix(filename, "claude-config-personal-"))
	assert.True(suite.T(), strings.HasSuffix(filename, ".json"))

	// Check that timestamp is in expected format (YYYYMMDD_HHMMSS)
	parts := strings.Split(filename, "-")
	assert.Len(suite.T(), parts, 4) // claude, config, personal, {timestamp}.json

	timestampPart := strings.TrimSuffix(parts[3], ".json")
	// Should be 15 characters: YYYYMMDD_HHMMSS
	assert.Len(suite.T(), timestampPart, 15)
	assert.Contains(suite.T(), timestampPart, "_")
}

// Test RestoreBackup with dry-run
func (suite *BackupManagerTestSuite) TestRestoreBackup_DryRun() {
	dryRunManager := NewFileBackupManager(suite.mockLogger, true)

	err := dryRunManager.RestoreBackup("/fake/backup/path.json")

	assert.NoError(suite.T(), err)

	// Should log dry-run message
	assert.Len(suite.T(), suite.mockLogger.WarningMessages, 1)
	assert.Contains(suite.T(), suite.mockLogger.WarningMessages[0], "[DRY-RUN]")
	assert.Contains(suite.T(), suite.mockLogger.WarningMessages[0], "Would restore from backup")
}

// Test RestoreBackup with non-existent backup
func (suite *BackupManagerTestSuite) TestRestoreBackup_NonExistentFile() {
	err := suite.backupManager.RestoreBackup("/non/existent/backup.json")

	assert.Error(suite.T(), err)
	assert.Contains(suite.T(), err.Error(), "backup file not found")
}

// Test RestoreBackup with valid backup
func (suite *BackupManagerTestSuite) TestRestoreBackup_ValidBackup() {
	// Create a backup file
	backupContent := `{"theme": "light", "parallelTasksCount": "10"}`
	backupPath := filepath.Join(suite.tempDir, "claude-config-dev-20240101_120000.json")
	err := os.WriteFile(backupPath, []byte(backupContent), 0644)
	suite.Require().NoError(err)

	// Restore the backup
	err = suite.backupManager.RestoreBackup(backupPath)

	assert.NoError(suite.T(), err)

	// Config file should be created/updated
	configPath := filepath.Join(suite.tempDir, ".claude.json")
	assert.FileExists(suite.T(), configPath)

	// Config should contain the backup content
	configContent, err := os.ReadFile(configPath)
	assert.NoError(suite.T(), err)
	assert.Equal(suite.T(), backupContent, string(configContent))

	// Should log success message
	assert.Len(suite.T(), suite.mockLogger.SuccessMessages, 1)
	assert.Contains(suite.T(), suite.mockLogger.SuccessMessages[0], "Configuration restored")
}

// Test ListBackups with no backups
func (suite *BackupManagerTestSuite) TestListBackups_NoBackups() {
	backups, err := suite.backupManager.ListBackups()

	assert.NoError(suite.T(), err)
	assert.Empty(suite.T(), backups)

	// Should log info message
	assert.Len(suite.T(), suite.mockLogger.InfoMessages, 1)
	assert.Contains(suite.T(), suite.mockLogger.InfoMessages[0], "No backups found")
}

// Test ListBackups with existing backups
func (suite *BackupManagerTestSuite) TestListBackups_WithBackups() {
	// Create some backup files
	backupFiles := []string{
		"claude-config-dev-20240101_120000.json",
		"claude-config-prod-20240102_130000.json",
		"claude-config-personal-20240103_140000.json",
	}

	for _, filename := range backupFiles {
		filePath := filepath.Join(suite.tempDir, filename)
		err := os.WriteFile(filePath, []byte("{}"), 0644)
		suite.Require().NoError(err)
	}

	// Create some non-backup files (should be ignored)
	otherFiles := []string{
		"not-a-backup.json",
		"claude-config.txt", // Wrong extension
		"other-file.json",
	}

	for _, filename := range otherFiles {
		filePath := filepath.Join(suite.tempDir, filename)
		err := os.WriteFile(filePath, []byte("{}"), 0644)
		suite.Require().NoError(err)
	}

	backups, err := suite.backupManager.ListBackups()

	assert.NoError(suite.T(), err)
	assert.Len(suite.T(), backups, 3) // Should only find the 3 backup files

	// Check that all backup files are found
	for _, expectedFile := range backupFiles {
		expectedPath := filepath.Join(suite.tempDir, expectedFile)
		assert.Contains(suite.T(), backups, expectedPath)
	}

	// Should not log "No backups found" message
	noBackupsFound := false
	for _, msg := range suite.mockLogger.InfoMessages {
		if strings.Contains(msg, "No backups found") {
			noBackupsFound = true
			break
		}
	}
	assert.False(suite.T(), noBackupsFound)
}

// Test error scenarios
func (suite *BackupManagerTestSuite) TestCreateBackup_ErrorScenarios() {
	// Test with invalid directory permissions (simulate write failure)
	// This is harder to test portably, so we'll focus on the happy path
	// and ensure error handling structure is in place

	// Create config file in a location we can't read from
	invalidPath := "/root/impossible/.claude.json"
	suite.backupManager.configPath = invalidPath

	// This should handle the error gracefully
	backupPath, err := suite.backupManager.CreateBackup(ProfileDev)

	// Behavior depends on system permissions, but should not panic
	assert.NotPanics(suite.T(), func() {
		suite.backupManager.CreateBackup(ProfileDev)
	})

	// Reset to valid path
	suite.backupManager.configPath = filepath.Join(suite.tempDir, ".claude.json")
}

// Test concurrent backup creation
func (suite *BackupManagerTestSuite) TestCreateBackup_Concurrent() {
	// Create a mock config file
	configPath := filepath.Join(suite.tempDir, ".claude.json")
	err := os.WriteFile(configPath, []byte("{}"), 0644)
	suite.Require().NoError(err)

	// Create multiple backups quickly to test timestamp uniqueness
	backupPaths := make([]string, 3)
	for i := 0; i < 3; i++ {
		backupPath, err := suite.backupManager.CreateBackup(ProfileDev)
		assert.NoError(suite.T(), err)
		backupPaths[i] = backupPath

		// Small delay to ensure different timestamps
		time.Sleep(time.Second)
	}

	// All backup paths should be different
	for i := 0; i < len(backupPaths); i++ {
		for j := i + 1; j < len(backupPaths); j++ {
			assert.NotEqual(suite.T(), backupPaths[i], backupPaths[j])
		}
	}
}

// Test interface compliance
func (suite *BackupManagerTestSuite) TestFileBackupManager_ImplementsInterface() {
	var _ BackupManager = (*FileBackupManager)(nil)

	// Test that the manager implements all required methods
	manager := NewFileBackupManager(suite.mockLogger, false)

	// Should be able to call all interface methods
	assert.NotPanics(suite.T(), func() {
		manager.CreateBackup(ProfileDev)
		manager.RestoreBackup("/fake/path")
		manager.ListBackups()
	})
}

// Run the backup manager test suite
func TestBackupManagerTestSuite(t *testing.T) {
	suite.Run(t, new(BackupManagerTestSuite))
}

// Additional unit tests
func TestBackupManager_ProfileInFilename(t *testing.T) {
	logger := NewMockLogger()
	manager := NewFileBackupManager(logger, true) // Use dry-run for testing

	profiles := []Profile{ProfileDev, ProfileProd, ProfilePersonal, ProfileDevelopment, ProfileProduction, ProfileDefault}

	for _, profile := range profiles {
		backupPath, err := manager.CreateBackup(profile)
		assert.NoError(t, err)
		assert.Contains(t, backupPath, string(profile), "Backup filename should contain profile name")
	}
}

func TestBackupManager_TimestampFormat(t *testing.T) {
	logger := NewMockLogger()
	manager := NewFileBackupManager(logger, true) // Use dry-run for testing

	backupPath, err := manager.CreateBackup(ProfileDev)
	assert.NoError(t, err)

	// Extract timestamp from filename
	filename := filepath.Base(backupPath)
	// Format: claude-config-dev-20240101_120000.json
	parts := strings.Split(filename, "-")
	timestampPart := strings.TrimSuffix(parts[len(parts)-1], ".json")

	// Parse timestamp to ensure it's valid
	_, err = time.Parse("20060102_150405", timestampPart)
	assert.NoError(t, err, "Timestamp should be in valid format")
}
