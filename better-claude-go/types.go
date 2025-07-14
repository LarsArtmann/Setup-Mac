package main

import "better-claude/internal/config"

// ApplicationOptions represents command-line options for the application
type ApplicationOptions struct {
	DryRun       bool
	CreateBackup bool
	Profile      config.Profile
	Help         bool
	ForwardArgs  []string
}

// Config alias for easier importing in tests
type Config = config.Config

// Profile alias for easier importing in tests  
type Profile = config.Profile

// ConfigKey alias for easier importing in tests
type ConfigKey = config.ConfigKey

// ProfileConfig alias for easier importing in tests
type ProfileConfig = config.ProfileConfig

// Profile constants for easier access in tests
var (
	ProfileDev         = config.ProfileDev
	ProfileDevelopment = config.ProfileDevelopment
	ProfileProd        = config.ProfileProd
	ProfileProduction  = config.ProfileProduction
	ProfilePersonal    = config.ProfilePersonal
	ProfileDefault     = config.ProfileDefault
)

// ConfigKey constants for easier access
var (
	KeyTheme                        = config.KeyTheme
	KeyParallelTasksCount          = config.KeyParallelTasksCount
	KeyPreferredNotifChannel       = config.KeyPreferredNotifChannel
	KeyMessageIdleNotifThresholdMs = config.KeyMessageIdleNotifThresholdMs
	KeyAutoUpdates                 = config.KeyAutoUpdates
	KeyDiffTool                    = config.KeyDiffTool
)