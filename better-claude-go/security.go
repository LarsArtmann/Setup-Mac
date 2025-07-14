package main

import (
	"fmt"
	"html"
	"regexp"
	"strings"
	"unicode"
)

// InputSanitizer provides input sanitization and security validation
type InputSanitizer struct {
	maxLength           int
	allowedCharPattern  *regexp.Regexp
	blockedPatterns     []*regexp.Regexp
	dangerousCommands   []string
	systemEnvVars       []string
}

// NewInputSanitizer creates a new input sanitizer with default security rules
func NewInputSanitizer() *InputSanitizer {
	// Common dangerous command patterns
	dangerousPatterns := []*regexp.Regexp{
		regexp.MustCompile(`rm\s+-[rf]+`),              // rm -rf
		regexp.MustCompile(`sudo\s+`),                  // sudo commands
		regexp.MustCompile(`curl\s+.*\|\s*sh`),         // curl | sh
		regexp.MustCompile(`wget\s+.*\|\s*sh`),         // wget | sh
		regexp.MustCompile(`eval\s*\(`),                // eval()
		regexp.MustCompile(`exec\s*\(`),                // exec()
		regexp.MustCompile(`system\s*\(`),              // system()
		regexp.MustCompile(`\$\([^)]*\)`),              // command substitution
		regexp.MustCompile("`[^`]*`"),                  // backtick execution
		regexp.MustCompile(`\|\s*while\s+read`),        // pipe to while read
		regexp.MustCompile(`\>\s*/dev/null\s*2>&1`),    // output redirection
		regexp.MustCompile(`chmod\s+[0-9]*x`),          // chmod +x
		regexp.MustCompile(`nc\s+-[lL]`),               // netcat listen
		regexp.MustCompile(`python\s+-c`),              // python -c
		regexp.MustCompile(`perl\s+-e`),                // perl -e
		regexp.MustCompile(`ruby\s+-e`),                // ruby -e
		regexp.MustCompile(`base64\s+-d`),              // base64 decode
	}
	
	// System environment variables that should never be modified
	systemEnvVars := []string{
		"PATH", "HOME", "USER", "SHELL", "PWD", "OLDPWD",
		"UID", "GID", "EUID", "EGID", "GROUPS",
		"TERM", "DISPLAY", "SSH_CLIENT", "SSH_CONNECTION",
		"LANG", "LC_ALL", "LC_CTYPE", "TZ",
		"TMPDIR", "TEMP", "TMP",
	}
	
	// Dangerous commands that should be blocked
	dangerousCommands := []string{
		"rm", "rmdir", "dd", "mkfs", "fdisk", "format",
		"sudo", "su", "passwd", "chown", "chmod",
		"kill", "killall", "pkill", "halt", "shutdown", "reboot",
		"iptables", "ufw", "firewall-cmd",
		"crontab", "at", "systemctl", "service",
		"mount", "umount", "fsck",
		"nc", "netcat", "telnet", "ssh", "scp", "rsync",
		"curl", "wget", "git", "svn", "hg",
		"python", "perl", "ruby", "node", "php",
		"gcc", "g++", "make", "cmake",
	}
	
	return &InputSanitizer{
		maxLength:         10000, // Maximum input length
		blockedPatterns:   dangerousPatterns,
		dangerousCommands: dangerousCommands,
		systemEnvVars:     systemEnvVars,
	}
}

// SanitizeString sanitizes a string input by removing dangerous content
func (s *InputSanitizer) SanitizeString(input string) string {
	if input == "" {
		return input
	}
	
	// Trim whitespace
	sanitized := strings.TrimSpace(input)
	
	// Escape HTML entities
	sanitized = html.EscapeString(sanitized)
	
	// Remove null bytes
	sanitized = strings.ReplaceAll(sanitized, "\x00", "")
	
	// Remove non-printable characters except newlines and tabs
	var result strings.Builder
	for _, r := range sanitized {
		if unicode.IsPrint(r) || r == '\n' || r == '\t' {
			result.WriteRune(r)
		}
	}
	
	return result.String()
}

// ValidateInputSecurity validates input for security threats
func (s *InputSanitizer) ValidateInputSecurity(input string) ValidationErrors {
	var errors ValidationErrors
	
	// Check length
	if len(input) > s.maxLength {
		errors = append(errors, ValidationError{
			Field:   "input",
			Value:   input,
			Message: fmt.Sprintf("input too long, maximum %d characters", s.maxLength),
		})
	}
	
	// Check for null bytes
	if strings.Contains(input, "\x00") {
		errors = append(errors, ValidationError{
			Field:   "input",
			Value:   input,
			Message: "null bytes not allowed",
		})
	}
	
	// Check for dangerous patterns
	for _, pattern := range s.blockedPatterns {
		if pattern.MatchString(input) {
			errors = append(errors, ValidationError{
				Field:   "input",
				Value:   input,
				Message: fmt.Sprintf("dangerous pattern detected: %s", pattern.String()),
			})
		}
	}
	
	// Check for shell metacharacters in contexts where they're dangerous
	if s.containsShellMetacharacters(input) {
		errors = append(errors, ValidationError{
			Field:   "input",
			Value:   input,
			Message: "shell metacharacters detected",
		})
	}
	
	return errors
}

// ValidateCommandArguments validates command-line arguments for safety
func (s *InputSanitizer) ValidateCommandArguments(args []string) ValidationErrors {
	var errors ValidationErrors
	
	for i, arg := range args {
		field := fmt.Sprintf("args[%d]", i)
		
		// Basic input validation
		argErrors := s.ValidateInputSecurity(arg)
		for _, err := range argErrors {
			err.Field = field
			errors = append(errors, err)
		}
		
		// Check for dangerous commands
		if s.isDangerousCommand(arg) {
			errors = append(errors, ValidationError{
				Field:   field,
				Value:   arg,
				Message: "dangerous command detected",
			})
		}
		
		// Check for path traversal
		if s.containsPathTraversal(arg) {
			errors = append(errors, ValidationError{
				Field:   field,
				Value:   arg,
				Message: "path traversal attempt detected",
			})
		}
	}
	
	return errors
}

// ValidateEnvironmentVariable validates environment variable names and values
func (s *InputSanitizer) ValidateEnvironmentVariable(name, value string) ValidationErrors {
	var errors ValidationErrors
	
	// Validate name
	if name == "" {
		errors = append(errors, ValidationError{
			Field:   "env.name",
			Value:   name,
			Message: "environment variable name cannot be empty",
		})
	}
	
	// Check if it's a system variable
	if s.isSystemEnvironmentVariable(name) {
		errors = append(errors, ValidationError{
			Field:   "env." + name,
			Value:   value,
			Message: "system environment variable modification not allowed",
		})
	}
	
	// Validate name format
	namePattern := regexp.MustCompile(`^[A-Z_][A-Z0-9_]*$`)
	if !namePattern.MatchString(name) {
		errors = append(errors, ValidationError{
			Field:   "env." + name,
			Value:   name,
			Message: "invalid environment variable name format",
		})
	}
	
	// Validate value
	valueErrors := s.ValidateInputSecurity(value)
	for _, err := range valueErrors {
		err.Field = "env." + name + ".value"
		errors = append(errors, err)
	}
	
	return errors
}

// ValidateConfigurationValue validates configuration values for specific keys
func (s *InputSanitizer) ValidateConfigurationValue(key ConfigKey, value string) ValidationErrors {
	var errors ValidationErrors
	
	// Basic input validation
	inputErrors := s.ValidateInputSecurity(value)
	for _, err := range inputErrors {
		err.Field = string(key)
		errors = append(errors, err)
	}
	
	// Key-specific validation
	switch key {
	case KeyTheme:
		if !s.isValidTheme(value) {
			errors = append(errors, ValidationError{
				Field:   string(key),
				Value:   value,
				Message: "invalid theme value",
			})
		}
		
	case KeyParallelTasksCount:
		if !s.isValidNumber(value, 1, 1000) {
			errors = append(errors, ValidationError{
				Field:   string(key),
				Value:   value,
				Message: "invalid parallel tasks count",
			})
		}
		
	case KeyPreferredNotifChannel:
		if !s.isValidNotificationChannel(value) {
			errors = append(errors, ValidationError{
				Field:   string(key),
				Value:   value,
				Message: "invalid notification channel",
			})
		}
		
	case KeyMessageIdleNotifThresholdMs:
		if !s.isValidNumber(value, 0, 60000) {
			errors = append(errors, ValidationError{
				Field:   string(key),
				Value:   value,
				Message: "invalid message idle threshold",
			})
		}
		
	case KeyAutoUpdates:
		if !s.isValidBoolean(value) {
			errors = append(errors, ValidationError{
				Field:   string(key),
				Value:   value,
				Message: "invalid auto updates value",
			})
		}
		
	case KeyDiffTool:
		if !s.isValidDiffTool(value) {
			errors = append(errors, ValidationError{
				Field:   string(key),
				Value:   value,
				Message: "invalid diff tool",
			})
		}
	}
	
	return errors
}

// Helper methods
func (s *InputSanitizer) containsShellMetacharacters(input string) bool {
	dangerousChars := []string{";", "&", "|", "$", "`", "(", ")", "{", "}", "[", "]", "<", ">", "\\"}
	for _, char := range dangerousChars {
		if strings.Contains(input, char) {
			return true
		}
	}
	return false
}

func (s *InputSanitizer) isDangerousCommand(arg string) bool {
	// Extract command name (first word)
	parts := strings.Fields(arg)
	if len(parts) == 0 {
		return false
	}
	
	command := parts[0]
	// Remove path if present
	if lastSlash := strings.LastIndex(command, "/"); lastSlash != -1 {
		command = command[lastSlash+1:]
	}
	
	for _, dangerous := range s.dangerousCommands {
		if command == dangerous {
			return true
		}
	}
	
	return false
}

func (s *InputSanitizer) containsPathTraversal(input string) bool {
	patterns := []string{
		"../", "..\\", "..", 
		"/etc/", "/proc/", "/sys/", "/dev/",
		"~/../", "~/.",
	}
	
	for _, pattern := range patterns {
		if strings.Contains(input, pattern) {
			return true
		}
	}
	
	return false
}

func (s *InputSanitizer) isSystemEnvironmentVariable(name string) bool {
	upperName := strings.ToUpper(name)
	for _, sysVar := range s.systemEnvVars {
		if upperName == sysVar {
			return true
		}
	}
	return false
}

func (s *InputSanitizer) isValidTheme(value string) bool {
	validThemes := []string{"dark-daltonized", "light", "dark", "auto"}
	for _, theme := range validThemes {
		if value == theme {
			return true
		}
	}
	return false
}

func (s *InputSanitizer) isValidNumber(value string, min, max int) bool {
	if value == "" {
		return true // Allow empty (will be handled by other validation)
	}
	
	// Check if it's a valid number format
	numberPattern := regexp.MustCompile(`^[0-9]+$`)
	if !numberPattern.MatchString(value) {
		return false
	}
	
	// Convert and check range
	var num int
	if _, err := fmt.Sscanf(value, "%d", &num); err != nil {
		return false
	}
	
	return num >= min && num <= max
}

func (s *InputSanitizer) isValidNotificationChannel(value string) bool {
	validChannels := []string{"iterm2_with_bell", "desktop", "none"}
	for _, channel := range validChannels {
		if value == channel {
			return true
		}
	}
	return false
}

func (s *InputSanitizer) isValidBoolean(value string) bool {
	return value == "true" || value == "false"
}

func (s *InputSanitizer) isValidDiffTool(value string) bool {
	validTools := []string{"bat", "diff", "delta", "code"}
	for _, tool := range validTools {
		if value == tool {
			return true
		}
	}
	return false
}

// SecurityAuditResult represents the result of a security audit
type SecurityAuditResult struct {
	Passed   bool
	Findings []SecurityFinding
}

// SecurityFinding represents a security issue found during audit
type SecurityFinding struct {
	Severity    string // "high", "medium", "low"
	Category    string // "input_validation", "command_injection", "path_traversal", etc.
	Description string
	Field       string
	Value       interface{}
}

// SecurityAuditor performs comprehensive security audits
type SecurityAuditor struct {
	sanitizer *InputSanitizer
}

// NewSecurityAuditor creates a new security auditor
func NewSecurityAuditor() *SecurityAuditor {
	return &SecurityAuditor{
		sanitizer: NewInputSanitizer(),
	}
}

// AuditApplicationOptions performs security audit on application options
func (a *SecurityAuditor) AuditApplicationOptions(options ApplicationOptions) SecurityAuditResult {
	var findings []SecurityFinding
	
	// Audit profile
	if string(options.Profile) != "" {
		validator := ProfileValidator{Profile: Profile(options.Profile)}
		profileErrors := validator.Validate()
		for _, err := range profileErrors {
			findings = append(findings, SecurityFinding{
				Severity:    "medium",
				Category:    "input_validation",
				Description: err.Message,
				Field:       "profile",
				Value:       options.Profile,
			})
		}
	}
	
	// Audit forward arguments
	argErrors := a.sanitizer.ValidateCommandArguments(options.ForwardArgs)
	for _, err := range argErrors {
		severity := "high"
		if strings.Contains(err.Message, "dangerous") {
			severity = "high"
		} else {
			severity = "medium"
		}
		
		findings = append(findings, SecurityFinding{
			Severity:    severity,
			Category:    "command_injection",
			Description: err.Message,
			Field:       err.Field,
			Value:       err.Value,
		})
	}
	
	return SecurityAuditResult{
		Passed:   len(findings) == 0,
		Findings: findings,
	}
}

// AuditConfig performs security audit on configuration
func (a *SecurityAuditor) AuditConfig(config Config) SecurityAuditResult {
	var findings []SecurityFinding
	
	// Audit configuration values
	configMap := map[ConfigKey]string{
		KeyTheme:                        config.Theme,
		KeyParallelTasksCount:          config.ParallelTasksCount,
		KeyPreferredNotifChannel:       config.PreferredNotifChannel,
		KeyMessageIdleNotifThresholdMs: config.MessageIdleNotifThresholdMs,
		KeyAutoUpdates:                 config.AutoUpdates,
		KeyDiffTool:                    config.DiffTool,
	}
	
	for key, value := range configMap {
		configErrors := a.sanitizer.ValidateConfigurationValue(key, value)
		for _, err := range configErrors {
			findings = append(findings, SecurityFinding{
				Severity:    "medium",
				Category:    "input_validation",
				Description: err.Message,
				Field:       string(key),
				Value:       value,
			})
		}
	}
	
	// Audit environment variables
	for name, value := range config.Env {
		envErrors := a.sanitizer.ValidateEnvironmentVariable(name, value)
		for _, err := range envErrors {
			severity := "high"
			if strings.Contains(err.Message, "system") {
				severity = "high"
			} else {
				severity = "medium"
			}
			
			findings = append(findings, SecurityFinding{
				Severity:    severity,
				Category:    "environment_security",
				Description: err.Message,
				Field:       "env." + name,
				Value:       value,
			})
		}
	}
	
	return SecurityAuditResult{
		Passed:   len(findings) == 0,
		Findings: findings,
	}
}