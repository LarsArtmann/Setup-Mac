Feature: Configuration Validation
  As a developer using Claude
  I want my configuration to be validated
  So that I can avoid invalid settings and security issues

  Background:
    Given the validation system is available

  Scenario Outline: Profile validation
    Given I have a profile "<profile>"
    When I validate the profile
    Then the validation should "<result>"

    Examples:
      | profile     | result |
      | dev         | pass   |
      | development | pass   |
      | prod        | pass   |
      | production  | pass   |
      | personal    | pass   |
      | default     | pass   |
      | invalid     | fail   |
      | ""          | fail   |
      | DEV         | fail   |

  Scenario Outline: Parallel tasks count validation
    Given I have a parallel tasks count of "<count>"
    When I validate the configuration
    Then the validation should "<result>"

    Examples:
      | count | result |
      | 1     | pass   |
      | 10    | pass   |
      | 500   | pass   |
      | 1000  | pass   |
      | 0     | fail   |
      | -1    | fail   |
      | 1001  | fail   |
      | abc   | fail   |
      | ""    | pass   |

  Scenario Outline: Message idle threshold validation
    Given I have a message idle threshold of "<threshold>"
    When I validate the configuration
    Then the validation should "<result>"

    Examples:
      | threshold | result |
      | 0         | pass   |
      | 1000      | pass   |
      | 60000     | pass   |
      | -1        | fail   |
      | 60001     | fail   |
      | abc       | fail   |
      | ""        | pass   |

  Scenario Outline: Auto updates validation
    Given I have auto updates set to "<value>"
    When I validate the configuration
    Then the validation should "<result>"

    Examples:
      | value | result |
      | true  | pass   |
      | false | pass   |
      | yes   | fail   |
      | no    | fail   |
      | 1     | fail   |
      | 0     | fail   |
      | ""    | pass   |

  Scenario Outline: Notification channel validation
    Given I have notification channel set to "<channel>"
    When I validate the configuration
    Then the validation should "<result>"

    Examples:
      | channel           | result |
      | iterm2_with_bell  | pass   |
      | desktop           | pass   |
      | none              | pass   |
      | invalid_channel   | fail   |
      | ""                | pass   |

  Scenario Outline: Diff tool validation
    Given I have diff tool set to "<tool>"
    When I validate the configuration
    Then the validation should "<result>"

    Examples:
      | tool         | result |
      | bat          | pass   |
      | diff         | pass   |
      | delta        | pass   |
      | code         | pass   |
      | invalid_tool | fail   |
      | ""           | pass   |

  Scenario Outline: Environment variable name validation
    Given I have an environment variable named "<name>"
    When I validate the configuration
    Then the validation should "<result>"

    Examples:
      | name                    | result |
      | VALID_NAME              | pass   |
      | ANOTHER_VALID_NAME      | pass   |
      | _STARTS_WITH_UNDERSCORE | pass   |
      | API_KEY_123             | pass   |
      | 123invalid              | fail   |
      | invalid-name            | fail   |
      | invalid name            | fail   |
      | ""                      | fail   |

  Scenario Outline: Dangerous environment variable protection
    Given I try to set environment variable "<variable>"
    When I validate the configuration
    Then the validation should fail
    And the error should mention "not allowed"

    Examples:
      | variable |
      | PATH     |
      | HOME     |
      | USER     |
      | SHELL    |

  Scenario Outline: Dangerous forwarded arguments protection
    Given I have forwarded arguments "<args>"
    When I validate the application options
    Then the validation should fail
    And the error should mention "shell metacharacters"

    Examples:
      | args                  |
      | rm -rf /              |
      | echo test; rm file    |
      | cat file \| rm        |
      | test & background     |

  Scenario: Empty theme validation
    Given I have an empty theme
    When I validate the configuration
    Then the validation should fail
    And the error should mention "theme cannot be empty"

  Scenario: Multiple validation errors
    Given I have a configuration with multiple errors
    When I validate the configuration
    Then the validation should fail
    And multiple error messages should be returned
    And all errors should be properly formatted