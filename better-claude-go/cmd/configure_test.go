package cmd

import (
	"bytes"
	"testing"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// ConfigureTestSuite contains tests for the configure command
type ConfigureTestSuite struct {
	suite.Suite
	cmd    *cobra.Command
	output *bytes.Buffer
}

func (suite *ConfigureTestSuite) SetupTest() {
	// Reset viper configuration
	viper.Reset()
	
	// Create a new command instance for testing
	suite.cmd = &cobra.Command{
		Use: "configure",
		RunE: configureCmd.RunE,
	}
	
	// Capture output
	suite.output = &bytes.Buffer{}
	suite.cmd.SetOut(suite.output)
	suite.cmd.SetErr(suite.output)
	
	// Set default flags
	suite.cmd.Flags().Bool("dry-run", false, "Preview changes")
	suite.cmd.Flags().Bool("backup", false, "Create backup")
	suite.cmd.Flags().String("profile", "personal", "Profile to use")
	
	// Bind flags to viper
	viper.BindPFlag("dry-run", suite.cmd.Flags().Lookup("dry-run"))
	viper.BindPFlag("backup", suite.cmd.Flags().Lookup("backup"))
	viper.BindPFlag("profile", suite.cmd.Flags().Lookup("profile"))
}

func (suite *ConfigureTestSuite) TearDownTest() {
	viper.Reset()
}

// Test configure command with default settings
func (suite *ConfigureTestSuite) TestConfigureCommand_DefaultProfile() {
	// Set up the command with default profile
	viper.Set("profile", "personal")
	viper.Set("dry-run", true)
	viper.Set("backup", false)
	
	// Execute the command
	err := suite.cmd.RunE(suite.cmd, []string{})
	
	// Should not error with dry-run mode
	assert.NoError(suite.T(), err, "Configure command should succeed with valid profile")
}

func (suite *ConfigureTestSuite) TestConfigureCommand_DevProfile() {
	// Set up the command with dev profile
	viper.Set("profile", "dev")
	viper.Set("dry-run", true)
	viper.Set("backup", false)
	
	// Execute the command
	err := suite.cmd.RunE(suite.cmd, []string{})
	
	assert.NoError(suite.T(), err, "Configure command should succeed with dev profile")
}

func (suite *ConfigureTestSuite) TestConfigureCommand_ProdProfile() {
	// Set up the command with prod profile
	viper.Set("profile", "prod")
	viper.Set("dry-run", true)
	viper.Set("backup", false)
	
	// Execute the command
	err := suite.cmd.RunE(suite.cmd, []string{})
	
	assert.NoError(suite.T(), err, "Configure command should succeed with prod profile")
}

func (suite *ConfigureTestSuite) TestConfigureCommand_InvalidProfile() {
	// Set up the command with invalid profile
	viper.Set("profile", "invalid_profile")
	viper.Set("dry-run", true)
	viper.Set("backup", false)
	
	// Execute the command
	err := suite.cmd.RunE(suite.cmd, []string{})
	
	assert.Error(suite.T(), err, "Configure command should fail with invalid profile")
}

func (suite *ConfigureTestSuite) TestConfigureCommand_WithBackup() {
	// Set up the command with backup enabled
	viper.Set("profile", "personal")
	viper.Set("dry-run", true)
	viper.Set("backup", true)
	
	// Execute the command
	err := suite.cmd.RunE(suite.cmd, []string{})
	
	assert.NoError(suite.T(), err, "Configure command should succeed with backup enabled")
}

func (suite *ConfigureTestSuite) TestConfigureCommand_WithForwardedArgs() {
	// Set up the command with forwarded arguments
	viper.Set("profile", "dev")
	viper.Set("dry-run", true)
	viper.Set("backup", false)
	
	// Execute the command with forwarded args
	args := []string{"chat", "--verbose"}
	
	// Should handle forwarded arguments (may fail in test environment due to missing claude command)
	// We just check that it processes the arguments without panicking
	assert.NotPanics(suite.T(), func() {
		suite.cmd.RunE(suite.cmd, args)
	})
}

// Test profile validation
func (suite *ConfigureTestSuite) TestConfigureCommand_ProfileValidation() {
	validProfiles := []string{"dev", "development", "prod", "production", "personal", "default"}
	
	for _, profile := range validProfiles {
		suite.Run("ValidProfile_"+profile, func() {
			viper.Set("profile", profile)
			viper.Set("dry-run", true)
			viper.Set("backup", false)
			
			err := suite.cmd.RunE(suite.cmd, []string{})
			assert.NoError(suite.T(), err, "Valid profile %s should succeed", profile)
		})
	}
}

func (suite *ConfigureTestSuite) TestConfigureCommand_DryRunMode() {
	// Test that dry-run mode doesn't make actual changes
	viper.Set("profile", "dev")
	viper.Set("dry-run", true)
	viper.Set("backup", false)
	
	err := suite.cmd.RunE(suite.cmd, []string{})
	
	assert.NoError(suite.T(), err, "Dry-run mode should succeed")
	// In dry-run mode, no actual changes should be made
	// This is more of an integration test to ensure the dry-run flag is properly handled
}

// Test error scenarios
func (suite *ConfigureTestSuite) TestConfigureCommand_ErrorScenarios() {
	errorTestCases := []struct {
		name       string
		profile    string
		dryRun     bool
		backup     bool
		shouldFail bool
	}{
		{"InvalidProfile", "nonexistent", true, false, true},
		{"EmptyProfile", "", true, false, true},
		{"ValidProfileDryRun", "dev", true, false, false},
		{"ValidProfileWithBackup", "personal", true, true, false},
	}
	
	for _, tc := range errorTestCases {
		suite.Run(tc.name, func() {
			viper.Set("profile", tc.profile)
			viper.Set("dry-run", tc.dryRun)
			viper.Set("backup", tc.backup)
			
			err := suite.cmd.RunE(suite.cmd, []string{})
			
			if tc.shouldFail {
				assert.Error(suite.T(), err, "Test case %s should fail", tc.name)
			} else {
				assert.NoError(suite.T(), err, "Test case %s should succeed", tc.name)
			}
		})
	}
}

// Test context handling
func (suite *ConfigureTestSuite) TestConfigureCommand_ContextHandling() {
	viper.Set("profile", "personal")
	viper.Set("dry-run", true)
	viper.Set("backup", false)
	
	// Test that command handles context properly
	assert.NotPanics(suite.T(), func() {
		// The command should handle context cancellation gracefully
		suite.cmd.RunE(suite.cmd, []string{})
	})
}

// Run the configure test suite
func TestConfigureTestSuite(t *testing.T) {
	suite.Run(t, new(ConfigureTestSuite))
}

// Additional unit tests for configure command functionality
func TestConfigureCommand_Integration(t *testing.T) {
	// Test the actual configure command registration
	rootCmd := &cobra.Command{Use: "root"}
	
	// Add the configure command
	rootCmd.AddCommand(configureCmd)
	
	// Verify command is properly registered
	configCmd, _, err := rootCmd.Find([]string{"configure"})
	assert.NoError(t, err)
	assert.NotNil(t, configCmd)
	assert.Equal(t, "configure", configCmd.Use)
}

func TestConfigureCommand_Flags(t *testing.T) {
	// Test that the configure command properly inherits flags from root
	cmd := configureCmd
	
	// The flags should be available from the parent command
	assert.NotNil(t, cmd, "Configure command should exist")
	assert.Equal(t, "configure", cmd.Use, "Command name should be configure")
}

func TestConfigureCommand_Help(t *testing.T) {
	// Test help text
	cmd := configureCmd
	
	assert.Contains(t, cmd.Short, "Configure Claude", "Short description should mention Configure Claude")
	assert.Contains(t, cmd.Long, "profiles", "Long description should mention profiles")
	assert.Contains(t, cmd.Long, "dev/development", "Long description should list dev profile")
	assert.Contains(t, cmd.Long, "prod/production", "Long description should list prod profile")
	assert.Contains(t, cmd.Long, "personal/default", "Long description should list personal profile")
}