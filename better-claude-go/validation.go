package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
)

// ValidationError represents a validation error
type ValidationError struct {
	Field   string
	Value   interface{}
	Message string
}

func (e ValidationError) Error() string {
	return fmt.Sprintf("validation failed for field '%s' with value '%v': %s", e.Field, e.Value, e.Message)
}

// ValidationErrors represents multiple validation errors
type ValidationErrors []ValidationError

func (errs ValidationErrors) Error() string {
	if len(errs) == 0 {
		return ""
	}
	
	messages := make([]string, len(errs))
	for i, err := range errs {
		messages[i] = err.Error()
	}
	return strings.Join(messages, "; ")
}

func (errs ValidationErrors) HasErrors() bool {
	return len(errs) > 0
}

// Validator interface for domain validation
type Validator interface {
	Validate() ValidationErrors
}

// ProfileValidator validates Profile values
type ProfileValidator struct {
	Profile Profile
}

func (v ProfileValidator) Validate() ValidationErrors {
	var errors ValidationErrors
	
	if v.Profile == "" {
		errors = append(errors, ValidationError{
			Field:   "profile",
			Value:   v.Profile,
			Message: "profile cannot be empty",
		})
		return errors
	}
	
	validProfiles := []Profile{
		ProfileDev, ProfileDevelopment,
		ProfileProd, ProfileProduction,
		ProfilePersonal, ProfileDefault,
	}
	
	for _, valid := range validProfiles {
		if v.Profile == valid {
			return errors // No errors, valid profile
		}
	}
	
	errors = append(errors, ValidationError{
		Field:   "profile",
		Value:   v.Profile,
		Message: "invalid profile. Valid profiles: dev, development, prod, production, personal, default",
	})
	
	return errors
}

// ConfigValidator validates Config values
type ConfigValidator struct {
	Config Config
}

func (v ConfigValidator) Validate() ValidationErrors {
	var errors ValidationErrors
	
	// Validate theme
	if v.Config.Theme == "" {
		errors = append(errors, ValidationError{
			Field:   "theme",
			Value:   v.Config.Theme,
			Message: "theme cannot be empty",
		})
	}
	
	// Validate parallel tasks count
	if v.Config.ParallelTasksCount != "" {
		if count, err := strconv.Atoi(v.Config.ParallelTasksCount); err != nil {
			errors = append(errors, ValidationError{
				Field:   "parallelTasksCount",
				Value:   v.Config.ParallelTasksCount,
				Message: "must be a valid integer",
			})
		} else if count < 1 || count > 1000 {
			errors = append(errors, ValidationError{
				Field:   "parallelTasksCount",
				Value:   v.Config.ParallelTasksCount,
				Message: "must be between 1 and 1000",
			})
		}
	}
	
	// Validate notification channel
	validChannels := []string{"iterm2_with_bell", "desktop", "none"}
	if v.Config.PreferredNotifChannel != "" {
		valid := false
		for _, channel := range validChannels {
			if v.Config.PreferredNotifChannel == channel {
				valid = true
				break
			}
		}
		if !valid {
			errors = append(errors, ValidationError{
				Field:   "preferredNotifChannel",
				Value:   v.Config.PreferredNotifChannel,
				Message: "must be one of: iterm2_with_bell, desktop, none",
			})
		}
	}
	
	// Validate message idle threshold
	if v.Config.MessageIdleNotifThresholdMs != "" {
		if threshold, err := strconv.Atoi(v.Config.MessageIdleNotifThresholdMs); err != nil {
			errors = append(errors, ValidationError{
				Field:   "messageIdleNotifThresholdMs",
				Value:   v.Config.MessageIdleNotifThresholdMs,
				Message: "must be a valid integer",
			})
		} else if threshold < 0 || threshold > 60000 {
			errors = append(errors, ValidationError{
				Field:   "messageIdleNotifThresholdMs",
				Value:   v.Config.MessageIdleNotifThresholdMs,
				Message: "must be between 0 and 60000 milliseconds",
			})
		}
	}
	
	// Validate auto updates
	if v.Config.AutoUpdates != "" {
		if v.Config.AutoUpdates != "true" && v.Config.AutoUpdates != "false" {
			errors = append(errors, ValidationError{
				Field:   "autoUpdates",
				Value:   v.Config.AutoUpdates,
				Message: "must be 'true' or 'false'",
			})
		}
	}
	
	// Validate diff tool
	validDiffTools := []string{"bat", "diff", "delta", "code"}
	if v.Config.DiffTool != "" {
		valid := false
		for _, tool := range validDiffTools {
			if v.Config.DiffTool == tool {
				valid = true
				break
			}
		}
		if !valid {
			errors = append(errors, ValidationError{
				Field:   "diffTool",
				Value:   v.Config.DiffTool,
				Message: "must be one of: bat, diff, delta, code",
			})
		}
	}
	
	// Validate environment variables
	for key, value := range v.Config.Env {
		if key == "" {
			errors = append(errors, ValidationError{
				Field:   "env.key",
				Value:   key,
				Message: "environment variable key cannot be empty",
			})
		}
		
		// Check for dangerous environment variables
		dangerousVars := []string{"PATH", "HOME", "USER", "SHELL"}
		for _, dangerous := range dangerousVars {
			if strings.EqualFold(key, dangerous) {
				errors = append(errors, ValidationError{
					Field:   "env." + key,
					Value:   value,
					Message: "modifying system environment variable '" + dangerous + "' is not allowed",
				})
			}
		}
		
		// Validate environment variable name format
		validEnvNamePattern := regexp.MustCompile(`^[A-Z_][A-Z0-9_]*$`)
		if !validEnvNamePattern.MatchString(key) {
			errors = append(errors, ValidationError{
				Field:   "env." + key,
				Value:   key,
				Message: "environment variable name must start with letter or underscore and contain only uppercase letters, numbers, and underscores",
			})
		}
	}
	
	return errors
}

// ApplicationOptionsValidator validates ApplicationOptions
type ApplicationOptionsValidator struct {
	Options ApplicationOptions
}

func (v ApplicationOptionsValidator) Validate() ValidationErrors {
	var errors ValidationErrors
	
	// Validate profile
	profileValidator := ProfileValidator{Profile: v.Options.Profile}
	errors = append(errors, profileValidator.Validate()...)
	
	// Validate forwarded arguments
	for i, arg := range v.Options.ForwardArgs {
		if strings.Contains(arg, ";") || strings.Contains(arg, "&") || strings.Contains(arg, "|") {
			errors = append(errors, ValidationError{
				Field:   fmt.Sprintf("forwardArgs[%d]", i),
				Value:   arg,
				Message: "forwarded arguments cannot contain shell metacharacters (;, &, |)",
			})
		}
	}
	
	return errors
}

// Implement Validator interface for domain objects
func (o ApplicationOptions) Validate() ValidationErrors {
	return ApplicationOptionsValidator{Options: o}.Validate()
}