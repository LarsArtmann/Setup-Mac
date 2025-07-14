Feature: Claude Configuration Management
  As a developer using Claude
  I want to manage my configuration profiles
  So that I can have optimal settings for different environments

  Background:
    Given the better-claude application is available
    And I have a clean configuration state

  Scenario: Configure development profile
    Given I want to use the "dev" profile
    When I run the configuration command
    Then the configuration should be applied successfully
    And the parallel tasks count should be "50"
    And the theme should be "dark-daltonized"
    And the notification channel should be "iterm2_with_bell"
    And the telemetry should be enabled

  Scenario: Configure production profile
    Given I want to use the "prod" profile
    When I run the configuration command
    Then the configuration should be applied successfully
    And the parallel tasks count should be "10"
    And the theme should be "dark-daltonized"
    And the notification channel should be "iterm2_with_bell"
    And the telemetry should be disabled

  Scenario: Configure personal profile
    Given I want to use the "personal" profile
    When I run the configuration command
    Then the configuration should be applied successfully
    And the parallel tasks count should be "20"
    And the theme should be "dark-daltonized"
    And the notification channel should be "iterm2_with_bell"
    And the telemetry should be enabled

  Scenario: Dry run mode
    Given I want to use the "dev" profile
    And I enable dry run mode
    When I run the configuration command
    Then the configuration should be previewed
    And no changes should be applied
    And dry run messages should be displayed

  Scenario: Create backup before configuration
    Given I want to use the "prod" profile
    And I enable backup creation
    When I run the configuration command
    Then a backup should be created
    And the configuration should be applied successfully

  Scenario: Invalid profile handling
    Given I want to use an invalid profile "nonexistent"
    When I run the configuration command
    Then an error should be returned
    And the error should mention "invalid profile"

  Scenario: Configuration validation success
    Given I have a valid configuration
    When I validate the configuration
    Then the validation should pass
    And success messages should be displayed

  Scenario: Configuration validation failure
    Given I have an invalid configuration with wrong theme
    When I validate the configuration
    Then the validation should fail
    And error messages should be displayed

  Scenario: Environment variable configuration
    Given I want to use the "dev" profile
    When I run the configuration command
    Then environment variables should be configured
    And EDITOR should be set to "nano"
    And CLAUDE_CODE_ENABLE_TELEMETRY should be set to "1"

  Scenario: Help command
    Given I want to see help information
    When I run the help command
    Then help information should be displayed
    And available profiles should be listed
    And command options should be explained

  Scenario: Forward arguments to Claude
    Given I want to use the "dev" profile
    And I have arguments to forward: "chat --verbose"
    When I run the configuration command
    Then the configuration should be applied successfully
    And Claude should be started with the forwarded arguments