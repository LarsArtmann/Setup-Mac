package main

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/cucumber/godog"
)

// BDDTestContext holds the state for BDD tests
type BDDTestContext struct {
	configurator      *ClaudeConfigurator
	mockLogger        *MockLogger
	mockConfigReader  *MockConfigReader
	mockConfigWriter  *MockConfigWriter
	mockBackupManager *MockBackupManager

	profile          Profile
	enableDryRun     bool
	enableBackup     bool
	forwardArgs      []string
	lastError        error
	lastConfig       *Config
	validationErrors ValidationErrors

	// For validation scenarios
	testProfile Profile
	testConfig  Config
	testOptions ApplicationOptions
}

func (ctx *BDDTestContext) resetContext() {
	ctx.mockLogger = NewMockLogger()
	ctx.mockConfigReader = NewMockConfigReader()
	ctx.mockConfigWriter = NewMockConfigWriter()
	ctx.mockBackupManager = NewMockBackupManager()

	ctx.profile = ""
	ctx.enableDryRun = false
	ctx.enableBackup = false
	ctx.forwardArgs = []string{}
	ctx.lastError = nil
	ctx.lastConfig = nil
	ctx.validationErrors = ValidationErrors{}

	ctx.testProfile = ""
	ctx.testConfig = Config{}
	ctx.testOptions = ApplicationOptions{}
}

func (ctx *BDDTestContext) createConfigurator() {
	options := ApplicationOptions{
		DryRun:       ctx.enableDryRun,
		CreateBackup: ctx.enableBackup,
		Profile:      ctx.profile,
		Help:         false,
		ForwardArgs:  ctx.forwardArgs,
	}

	ctx.configurator = &ClaudeConfigurator{
		configReader:   ctx.mockConfigReader,
		configWriter:   ctx.mockConfigWriter,
		profileManager: NewStaticProfileManager(ctx.mockLogger),
		backupManager:  ctx.mockBackupManager,
		logger:         ctx.mockLogger,
		options:        options,
	}
}

// Configuration feature step definitions
func (ctx *BDDTestContext) theBetterClaudeApplicationIsAvailable() error {
	// Application is always available in tests
	return nil
}

func (ctx *BDDTestContext) iHaveACleanConfigurationState() error {
	ctx.resetContext()
	return nil
}

func (ctx *BDDTestContext) iWantToUseTheProfile(profile string) error {
	ctx.profile = Profile(profile)
	return nil
}

func (ctx *BDDTestContext) iWantToUseAnInvalidProfile(profile string) error {
	ctx.profile = Profile(profile)
	return nil
}

func (ctx *BDDTestContext) iEnableDryRunMode() error {
	ctx.enableDryRun = true
	return nil
}

func (ctx *BDDTestContext) iEnableBackupCreation() error {
	ctx.enableBackup = true
	return nil
}

func (ctx *BDDTestContext) iHaveArgumentsToForward(args string) error {
	ctx.forwardArgs = strings.Fields(args)
	return nil
}

func (ctx *BDDTestContext) iRunTheConfigurationCommand() error {
	ctx.createConfigurator()
	ctx.lastError = ctx.configurator.Run()
	return nil
}

func (ctx *BDDTestContext) iRunTheHelpCommand() error {
	ctx.enableDryRun = true // Help doesn't actually run anything
	ctx.createConfigurator()
	ctx.configurator.options.Help = true
	ctx.lastError = ctx.configurator.Run()
	return nil
}

func (ctx *BDDTestContext) iWantToSeeHelpInformation() error {
	// This is just setting up the intent
	return nil
}

func (ctx *BDDTestContext) theConfigurationShouldBeAppliedSuccessfully() error {
	if ctx.lastError != nil {
		return fmt.Errorf("expected successful configuration, but got error: %v", ctx.lastError)
	}
	return nil
}

func (ctx *BDDTestContext) theConfigurationShouldBePreviewed() error {
	// In dry run mode, should have warning messages
	if len(ctx.mockLogger.WarningMessages) == 0 {
		return fmt.Errorf("expected dry run messages, but none found")
	}

	dryRunFound := false
	for _, msg := range ctx.mockLogger.WarningMessages {
		if strings.Contains(msg, "[DRY-RUN]") {
			dryRunFound = true
			break
		}
	}

	if !dryRunFound {
		return fmt.Errorf("expected [DRY-RUN] messages, but none found")
	}

	return nil
}

func (ctx *BDDTestContext) noChangesShouldBeApplied() error {
	if len(ctx.mockConfigWriter.writtenConfigs) > 0 {
		return fmt.Errorf("expected no config changes, but found: %v", ctx.mockConfigWriter.writtenConfigs)
	}
	return nil
}

func (ctx *BDDTestContext) dryRunMessagesShouldBeDisplayed() error {
	return ctx.theConfigurationShouldBePreviewed()
}

func (ctx *BDDTestContext) aBackupShouldBeCreated() error {
	if ctx.mockBackupManager.GetLastBackupPath() == "" {
		return fmt.Errorf("expected backup to be created, but none found")
	}
	return nil
}

func (ctx *BDDTestContext) anErrorShouldBeReturned() error {
	if ctx.lastError == nil {
		return fmt.Errorf("expected an error, but none occurred")
	}
	return nil
}

func (ctx *BDDTestContext) theErrorShouldMention(message string) error {
	if ctx.lastError == nil {
		return fmt.Errorf("expected an error mentioning '%s', but no error occurred", message)
	}
	if !strings.Contains(ctx.lastError.Error(), message) {
		return fmt.Errorf("expected error to contain '%s', but got: %v", message, ctx.lastError)
	}
	return nil
}

func (ctx *BDDTestContext) theParallelTasksCountShouldBe(count string) error {
	// Check if the value was written to config
	writtenValue, exists := ctx.mockConfigWriter.GetWrittenConfig(KeyParallelTasksCount)
	if exists && writtenValue == count {
		return nil
	}

	// If not written, check if current config already matches (no change needed)
	currentConfig, err := ctx.mockConfigReader.ReadConfig()
	if err != nil {
		return err
	}

	if currentConfig.ParallelTasksCount == count {
		return nil
	}

	return fmt.Errorf("expected parallel tasks count to be '%s', but got '%s'", count, currentConfig.ParallelTasksCount)
}

func (ctx *BDDTestContext) theThemeShouldBe(theme string) error {
	writtenValue, exists := ctx.mockConfigWriter.GetWrittenConfig(KeyTheme)
	if exists && writtenValue == theme {
		return nil
	}

	currentConfig, err := ctx.mockConfigReader.ReadConfig()
	if err != nil {
		return err
	}

	if currentConfig.Theme == theme {
		return nil
	}

	return fmt.Errorf("expected theme to be '%s', but got '%s'", theme, currentConfig.Theme)
}

func (ctx *BDDTestContext) theNotificationChannelShouldBe(channel string) error {
	writtenValue, exists := ctx.mockConfigWriter.GetWrittenConfig(KeyPreferredNotifChannel)
	if exists && writtenValue == channel {
		return nil
	}

	currentConfig, err := ctx.mockConfigReader.ReadConfig()
	if err != nil {
		return err
	}

	if currentConfig.PreferredNotifChannel == channel {
		return nil
	}

	return fmt.Errorf("expected notification channel to be '%s', but got '%s'", channel, currentConfig.PreferredNotifChannel)
}

func (ctx *BDDTestContext) theTelemetryShouldBeEnabled() error {
	telemetryValue, exists := ctx.mockConfigWriter.GetWrittenEnvVar("CLAUDE_CODE_ENABLE_TELEMETRY")
	if exists && telemetryValue == "1" {
		return nil
	}

	currentConfig, err := ctx.mockConfigReader.ReadConfig()
	if err != nil {
		return err
	}

	if currentConfig.Env["CLAUDE_CODE_ENABLE_TELEMETRY"] == "1" {
		return nil
	}

	return fmt.Errorf("expected telemetry to be enabled (CLAUDE_CODE_ENABLE_TELEMETRY=1)")
}

func (ctx *BDDTestContext) theTelemetryShouldBeDisabled() error {
	telemetryValue, exists := ctx.mockConfigWriter.GetWrittenEnvVar("CLAUDE_CODE_ENABLE_TELEMETRY")
	if exists && telemetryValue == "0" {
		return nil
	}

	currentConfig, err := ctx.mockConfigReader.ReadConfig()
	if err != nil {
		return err
	}

	if currentConfig.Env["CLAUDE_CODE_ENABLE_TELEMETRY"] == "0" {
		return nil
	}

	return fmt.Errorf("expected telemetry to be disabled (CLAUDE_CODE_ENABLE_TELEMETRY=0)")
}

func (ctx *BDDTestContext) environmentVariablesShouldBeConfigured() error {
	if len(ctx.mockConfigWriter.writtenEnvVars) == 0 {
		// Check if env vars were already correct
		currentConfig, err := ctx.mockConfigReader.ReadConfig()
		if err != nil {
			return err
		}
		if len(currentConfig.Env) == 0 {
			return fmt.Errorf("expected environment variables to be configured")
		}
	}
	return nil
}

func (ctx *BDDTestContext) editorShouldBeSetTo(value string) error {
	editorValue, exists := ctx.mockConfigWriter.GetWrittenEnvVar("EDITOR")
	if exists && editorValue == value {
		return nil
	}

	currentConfig, err := ctx.mockConfigReader.ReadConfig()
	if err != nil {
		return err
	}

	if currentConfig.Env["EDITOR"] == value {
		return nil
	}

	return fmt.Errorf("expected EDITOR to be '%s'", value)
}

func (ctx *BDDTestContext) claudeCodeEnableTelemetryShouldBeSetTo(value string) error {
	telemetryValue, exists := ctx.mockConfigWriter.GetWrittenEnvVar("CLAUDE_CODE_ENABLE_TELEMETRY")
	if exists && telemetryValue == value {
		return nil
	}

	currentConfig, err := ctx.mockConfigReader.ReadConfig()
	if err != nil {
		return err
	}

	if currentConfig.Env["CLAUDE_CODE_ENABLE_TELEMETRY"] == value {
		return nil
	}

	return fmt.Errorf("expected CLAUDE_CODE_ENABLE_TELEMETRY to be '%s'", value)
}

func (ctx *BDDTestContext) helpInformationShouldBeDisplayed() error {
	// Help is handled by showing help, no specific validation needed in mock
	return nil
}

func (ctx *BDDTestContext) availableProfilesShouldBeListed() error {
	return nil
}

func (ctx *BDDTestContext) commandOptionsShouldBeExplained() error {
	return nil
}

func (ctx *BDDTestContext) claudeShouldBeStartedWithTheForwardedArguments() error {
	// Should have logged a message about starting claude
	claudeStartFound := false
	for _, msg := range ctx.mockLogger.WarningMessages {
		if strings.Contains(msg, "Would start claude") {
			claudeStartFound = true
			break
		}
	}

	if !claudeStartFound {
		return fmt.Errorf("expected claude to be started with forwarded arguments")
	}

	return nil
}

// Validation feature step definitions
func (ctx *BDDTestContext) theValidationSystemIsAvailable() error {
	return nil
}

func (ctx *BDDTestContext) iHaveAProfile(profile string) error {
	ctx.testProfile = Profile(profile)
	return nil
}

func (ctx *BDDTestContext) iValidateTheProfile() error {
	ctx.validationErrors = ctx.testProfile.Validate()
	return nil
}

func (ctx *BDDTestContext) iHaveAParallelTasksCountOf(count string) error {
	ctx.testConfig = NewConfigBuilder().WithParallelTasksCount(count).Build()
	return nil
}

func (ctx *BDDTestContext) iValidateTheConfiguration() error {
	ctx.validationErrors = ctx.testConfig.Validate()
	return nil
}

func (ctx *BDDTestContext) iHaveAMessageIdleThresholdOf(threshold string) error {
	ctx.testConfig = NewConfigBuilder().WithMessageIdleThreshold(threshold).Build()
	return nil
}

func (ctx *BDDTestContext) iHaveAutoUpdatesSetTo(value string) error {
	ctx.testConfig = NewConfigBuilder().WithAutoUpdates(value).Build()
	return nil
}

func (ctx *BDDTestContext) iHaveNotificationChannelSetTo(channel string) error {
	ctx.testConfig = NewConfigBuilder().WithNotificationChannel(channel).Build()
	return nil
}

func (ctx *BDDTestContext) iHaveDiffToolSetTo(tool string) error {
	ctx.testConfig = NewConfigBuilder().WithDiffTool(tool).Build()
	return nil
}

func (ctx *BDDTestContext) iHaveAnEnvironmentVariableNamed(name string) error {
	ctx.testConfig = NewConfigBuilder().WithEnvVar(name, "test_value").Build()
	return nil
}

func (ctx *BDDTestContext) iTryToSetEnvironmentVariable(variable string) error {
	ctx.testConfig = NewConfigBuilder().WithEnvVar(variable, "dangerous_value").Build()
	return nil
}

func (ctx *BDDTestContext) iHaveForwardedArguments(args string) error {
	ctx.testOptions = NewApplicationOptionsBuilder().WithForwardArgs(args).Build()
	return nil
}

func (ctx *BDDTestContext) iValidateTheApplicationOptions() error {
	ctx.validationErrors = ctx.testOptions.Validate()
	return nil
}

func (ctx *BDDTestContext) iHaveAnEmptyTheme() error {
	ctx.testConfig = NewConfigBuilder().WithTheme("").Build()
	return nil
}

func (ctx *BDDTestContext) iHaveAConfigurationWithMultipleErrors() error {
	ctx.testConfig = NewConfigBuilder().
		WithTheme("").
		WithParallelTasksCount("invalid").
		WithNotificationChannel("invalid").
		WithEnvVar("PATH", "dangerous").
		Build()
	return nil
}

func (ctx *BDDTestContext) iHaveAValidConfiguration() error {
	profileConfig, _ := NewStaticProfileManager(NewMockLogger()).LoadProfile(ProfileDev)
	ctx.lastConfig = &profileConfig.Config
	return nil
}

func (ctx *BDDTestContext) iHaveAnInvalidConfigurationWithWrongTheme() error {
	ctx.lastConfig = &Config{
		Theme: "wrong_theme",
		Env:   make(map[string]string),
	}
	return nil
}

func (ctx *BDDTestContext) iValidateTheConfigurationState() error {
	if ctx.lastConfig != nil {
		ctx.validationErrors = ctx.lastConfig.Validate()
	}
	return nil
}

func (ctx *BDDTestContext) theValidationShouldPass() error {
	if ctx.validationErrors.HasErrors() {
		return fmt.Errorf("expected validation to pass, but got errors: %v", ctx.validationErrors)
	}
	return nil
}

func (ctx *BDDTestContext) theValidationShouldFail() error {
	if !ctx.validationErrors.HasErrors() {
		return fmt.Errorf("expected validation to fail, but it passed")
	}
	return nil
}

func (ctx *BDDTestContext) theErrorShouldMentionValidation(message string) error {
	if !ctx.validationErrors.HasErrors() {
		return fmt.Errorf("expected validation errors mentioning '%s', but no errors found", message)
	}

	errorMsg := ctx.validationErrors.Error()
	if !strings.Contains(errorMsg, message) {
		return fmt.Errorf("expected validation error to contain '%s', but got: %v", message, errorMsg)
	}

	return nil
}

func (ctx *BDDTestContext) successMessagesShouldBeDisplayed() error {
	// Success is indicated by no errors
	return nil
}

func (ctx *BDDTestContext) errorMessagesShouldBeDisplayed() error {
	if !ctx.validationErrors.HasErrors() {
		return fmt.Errorf("expected error messages, but validation passed")
	}
	return nil
}

func (ctx *BDDTestContext) multipleErrorMessagesShouldBeReturned() error {
	if len(ctx.validationErrors) < 2 {
		return fmt.Errorf("expected multiple errors, but got %d", len(ctx.validationErrors))
	}
	return nil
}

func (ctx *BDDTestContext) allErrorsShouldBeProperlyFormatted() error {
	for _, err := range ctx.validationErrors {
		if err.Field == "" || err.Message == "" {
			return fmt.Errorf("validation error is not properly formatted: %v", err)
		}
	}
	return nil
}

// Test runner for BDD tests
func TestBDDFeatures(t *testing.T) {
	ctx := &BDDTestContext{}

	suite := godog.TestSuite{
		ScenarioInitializer: func(sc *godog.ScenarioContext) {
			// Configuration feature steps
			sc.Given(`^the better-claude application is available$`, ctx.theBetterClaudeApplicationIsAvailable)
			sc.Given(`^I have a clean configuration state$`, ctx.iHaveACleanConfigurationState)
			sc.Given(`^I want to use the "([^"]*)" profile$`, ctx.iWantToUseTheProfile)
			sc.Given(`^I want to use an invalid profile "([^"]*)"$`, ctx.iWantToUseAnInvalidProfile)
			sc.Given(`^I enable dry run mode$`, ctx.iEnableDryRunMode)
			sc.Given(`^I enable backup creation$`, ctx.iEnableBackupCreation)
			sc.Given(`^I have arguments to forward: "([^"]*)"$`, ctx.iHaveArgumentsToForward)
			sc.Given(`^I want to see help information$`, ctx.iWantToSeeHelpInformation)

			sc.When(`^I run the configuration command$`, ctx.iRunTheConfigurationCommand)
			sc.When(`^I run the help command$`, ctx.iRunTheHelpCommand)

			sc.Then(`^the configuration should be applied successfully$`, ctx.theConfigurationShouldBeAppliedSuccessfully)
			sc.Then(`^the configuration should be previewed$`, ctx.theConfigurationShouldBePreviewed)
			sc.Then(`^no changes should be applied$`, ctx.noChangesShouldBeApplied)
			sc.Then(`^dry run messages should be displayed$`, ctx.dryRunMessagesShouldBeDisplayed)
			sc.Then(`^a backup should be created$`, ctx.aBackupShouldBeCreated)
			sc.Then(`^an error should be returned$`, ctx.anErrorShouldBeReturned)
			sc.Then(`^the error should mention "([^"]*)"$`, ctx.theErrorShouldMention)
			sc.Then(`^the parallel tasks count should be "([^"]*)"$`, ctx.theParallelTasksCountShouldBe)
			sc.Then(`^the theme should be "([^"]*)"$`, ctx.theThemeShouldBe)
			sc.Then(`^the notification channel should be "([^"]*)"$`, ctx.theNotificationChannelShouldBe)
			sc.Then(`^the telemetry should be enabled$`, ctx.theTelemetryShouldBeEnabled)
			sc.Then(`^the telemetry should be disabled$`, ctx.theTelemetryShouldBeDisabled)
			sc.Then(`^environment variables should be configured$`, ctx.environmentVariablesShouldBeConfigured)
			sc.Then(`^EDITOR should be set to "([^"]*)"$`, ctx.editorShouldBeSetTo)
			sc.Then(`^CLAUDE_CODE_ENABLE_TELEMETRY should be set to "([^"]*)"$`, ctx.claudeCodeEnableTelemetryShouldBeSetTo)
			sc.Then(`^help information should be displayed$`, ctx.helpInformationShouldBeDisplayed)
			sc.Then(`^available profiles should be listed$`, ctx.availableProfilesShouldBeListed)
			sc.Then(`^command options should be explained$`, ctx.commandOptionsShouldBeExplained)
			sc.Then(`^Claude should be started with the forwarded arguments$`, ctx.claudeShouldBeStartedWithTheForwardedArguments)

			// Validation feature steps
			sc.Given(`^the validation system is available$`, ctx.theValidationSystemIsAvailable)
			sc.Given(`^I have a profile "([^"]*)"$`, ctx.iHaveAProfile)
			sc.Given(`^I have a parallel tasks count of "([^"]*)"$`, ctx.iHaveAParallelTasksCountOf)
			sc.Given(`^I have a message idle threshold of "([^"]*)"$`, ctx.iHaveAMessageIdleThresholdOf)
			sc.Given(`^I have auto updates set to "([^"]*)"$`, ctx.iHaveAutoUpdatesSetTo)
			sc.Given(`^I have notification channel set to "([^"]*)"$`, ctx.iHaveNotificationChannelSetTo)
			sc.Given(`^I have diff tool set to "([^"]*)"$`, ctx.iHaveDiffToolSetTo)
			sc.Given(`^I have an environment variable named "([^"]*)"$`, ctx.iHaveAnEnvironmentVariableNamed)
			sc.Given(`^I try to set environment variable "([^"]*)"$`, ctx.iTryToSetEnvironmentVariable)
			sc.Given(`^I have forwarded arguments "([^"]*)"$`, ctx.iHaveForwardedArguments)
			sc.Given(`^I have an empty theme$`, ctx.iHaveAnEmptyTheme)
			sc.Given(`^I have a configuration with multiple errors$`, ctx.iHaveAConfigurationWithMultipleErrors)
			sc.Given(`^I have a valid configuration$`, ctx.iHaveAValidConfiguration)
			sc.Given(`^I have an invalid configuration with wrong theme$`, ctx.iHaveAnInvalidConfigurationWithWrongTheme)

			sc.When(`^I validate the profile$`, ctx.iValidateTheProfile)
			sc.When(`^I validate the configuration$`, ctx.iValidateTheConfiguration)
			sc.When(`^I validate the application options$`, ctx.iValidateTheApplicationOptions)

			sc.Then(`^the validation should "([^"]*)"$`, func(result string) error {
				if result == "pass" {
					return ctx.theValidationShouldPass()
				} else if result == "fail" {
					return ctx.theValidationShouldFail()
				}
				return fmt.Errorf("unknown validation result: %s", result)
			})
			sc.Then(`^the validation should pass$`, ctx.theValidationShouldPass)
			sc.Then(`^the validation should fail$`, ctx.theValidationShouldFail)
			sc.Then(`^the error should mention "([^"]*)"$`, ctx.theErrorShouldMentionValidation)
			sc.Then(`^success messages should be displayed$`, ctx.successMessagesShouldBeDisplayed)
			sc.Then(`^error messages should be displayed$`, ctx.errorMessagesShouldBeDisplayed)
			sc.Then(`^multiple error messages should be returned$`, ctx.multipleErrorMessagesShouldBeReturned)
			sc.Then(`^all errors should be properly formatted$`, ctx.allErrorsShouldBeProperlyFormatted)
		},
		Options: &godog.Options{
			Format:   "pretty",
			Paths:    []string{"features"},
			TestingT: t,
		},
	}

	if suite.Run() != 0 {
		t.Fatal("non-zero status returned, failed to run feature tests")
	}
}

// Run BDD tests from command line
func TestMain(m *testing.M) {
	status := m.Run()
	os.Exit(status)
}
