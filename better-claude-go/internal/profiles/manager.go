package profiles

import (
	"fmt"

	"github.com/samber/lo"

	"better-claude/internal/config"
	"better-claude/internal/logger"
)

// Profile type alias for consistency
type Profile = config.Profile

const (
	ProfileDev        = config.ProfileDev
	ProfileDevelopment = config.ProfileDevelopment
	ProfileProd       = config.ProfileProd
	ProfileProduction = config.ProfileProduction
	ProfilePersonal   = config.ProfilePersonal
	ProfileDefault    = config.ProfileDefault
)

// ProfileManager interface for managing configuration profiles
type ProfileManager interface {
	LoadProfile(profile Profile) (*config.ProfileConfig, error)
	GetAvailableProfiles() []Profile
	ValidateProfile(profile Profile) error
}

// StaticProfileManager implements ProfileManager with static configurations using functional patterns
type StaticProfileManager struct {
	logger   logger.Logger
	profiles map[Profile]*config.ProfileConfig
}

func NewStaticProfileManager(logger logger.Logger) *StaticProfileManager {
	// Define profiles using functional composition
	profiles := map[Profile]*config.ProfileConfig{
		ProfileDev: createDevProfile(),
		ProfileDevelopment: createDevProfile(),
		ProfileProd: createProdProfile(),
		ProfileProduction: createProdProfile(),
		ProfilePersonal: createPersonalProfile(),
		ProfileDefault: createPersonalProfile(),
	}

	return &StaticProfileManager{
		logger:   logger,
		profiles: profiles,
	}
}

func (m *StaticProfileManager) LoadProfile(profile Profile) (*config.ProfileConfig, error) {
	if err := m.ValidateProfile(profile); err != nil {
		return nil, err
	}

	profileConfig, exists := m.profiles[profile]
	if !exists {
		// Fallback to personal profile
		return m.profiles[ProfilePersonal], nil
	}

	return profileConfig, nil
}

func (m *StaticProfileManager) GetAvailableProfiles() []Profile {
	return lo.Keys(m.profiles)
}

func (m *StaticProfileManager) ValidateProfile(profile Profile) error {
	validProfiles := []Profile{
		ProfileDev, ProfileDevelopment,
		ProfileProd, ProfileProduction,
		ProfilePersonal, ProfileDefault,
	}

	isValid := lo.Contains(validProfiles, profile)
	if !isValid {
		return fmt.Errorf("invalid profile '%s'. Valid profiles: %s", 
			profile, 
			lo.Reduce(validProfiles, func(acc string, profile Profile, _ int) string {
				if acc == "" {
					return string(profile)
				}
				return acc + ", " + string(profile)
			}, ""))
	}

	return nil
}

// Profile factory functions using functional composition
func createDevProfile() *config.ProfileConfig {
	return &config.ProfileConfig{
		Profile: ProfileDev,
		Config: config.Config{
			Theme:                        "dark-daltonized",
			ParallelTasksCount:          "50",
			PreferredNotifChannel:       "iterm2_with_bell",
			MessageIdleNotifThresholdMs: "500",
			AutoUpdates:                 "false",
			DiffTool:                    "bat",
		},
		EnvVars: createDevEnvVars(),
	}
}

func createProdProfile() *config.ProfileConfig {
	return &config.ProfileConfig{
		Profile: ProfileProd,
		Config: config.Config{
			Theme:                        "dark-daltonized",
			ParallelTasksCount:          "10",
			PreferredNotifChannel:       "iterm2_with_bell",
			MessageIdleNotifThresholdMs: "2000",
			AutoUpdates:                 "false",
			DiffTool:                    "bat",
		},
		EnvVars: createProdEnvVars(),
	}
}

func createPersonalProfile() *config.ProfileConfig {
	return &config.ProfileConfig{
		Profile: ProfilePersonal,
		Config: config.Config{
			Theme:                        "dark-daltonized",
			ParallelTasksCount:          "20",
			PreferredNotifChannel:       "iterm2_with_bell",
			MessageIdleNotifThresholdMs: "1000",
			AutoUpdates:                 "false",
			DiffTool:                    "bat",
		},
		EnvVars: createPersonalEnvVars(),
	}
}

func createDevEnvVars() map[string]string {
	return map[string]string{
		"EDITOR":                         "nano",
		"CLAUDE_CODE_ENABLE_TELEMETRY":   "1",
		"OTEL_METRICS_EXPORTER":          "otlp",
		"OTEL_LOGS_EXPORTER":             "otlp",
		"OTEL_EXPORTER_OTLP_PROTOCOL":    "grpc",
		"OTEL_EXPORTER_OTLP_ENDPOINT":    "http://localhost:4317",
		"OTEL_METRIC_EXPORT_INTERVAL":    "5000",
		"OTEL_LOGS_EXPORT_INTERVAL":      "2500",
	}
}

func createProdEnvVars() map[string]string {
	return map[string]string{
		"EDITOR":                       "nano",
		"CLAUDE_CODE_ENABLE_TELEMETRY": "0",
		"OTEL_METRICS_EXPORTER":        "none",
		"OTEL_LOGS_EXPORTER":           "none",
	}
}

func createPersonalEnvVars() map[string]string {
	return map[string]string{
		"EDITOR":                         "nano",
		"CLAUDE_CODE_ENABLE_TELEMETRY":   "1",
		"OTEL_METRICS_EXPORTER":          "otlp",
		"OTEL_LOGS_EXPORTER":             "otlp",
		"OTEL_EXPORTER_OTLP_PROTOCOL":    "grpc",
		"OTEL_EXPORTER_OTLP_ENDPOINT":    "http://localhost:4317",
		"OTEL_METRIC_EXPORT_INTERVAL":    "10000",
		"OTEL_LOGS_EXPORT_INTERVAL":      "5000",
	}
}