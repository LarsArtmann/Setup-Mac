//go:build linux

package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
	"strings"

	"github.com/larsartmann/systemnix/emeet-pixyd/internal/pixy"
)

var (
	errAudioSourceNotFound = errors.New("PIXY audio source not found")
	errInvalidValue        = errors.New("invalid value")
)

const (
	respAutoModeOff    = "auto mode off"
	respAutoModeOn     = "auto mode on"
	respAudioUsage     = "usage: audio [nc|live|org]"
	respDeviceNotFound = "device not found"

	cmdGestureOn = "gesture-on"
	cmdAutoOn    = "auto-on"
)

func (d *Daemon) handleCommand(ctx context.Context, cmd string) string {
	d.mu.Lock()
	defer d.mu.Unlock()

	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		return d.getStatus(ctx)
	}

	switch parts[0] {
	case "status":
		return d.getStatus(ctx)

	case "track":
		return d.handleTrackingCommand(pixy.StateTracking, "track")

	case "idle":
		return d.handleTrackingCommand(pixy.StateIdle, "idle")

	case "privacy":
		return d.handleTrackingCommand(pixy.StatePrivacy, "privacy")

	case "toggle-privacy":
		if d.state.Camera == pixy.StatePrivacy {
			return d.handleTrackingCommand(pixy.StateTracking, "toggle-privacy")
		}

		return d.handleTrackingCommand(pixy.StatePrivacy, "toggle-privacy")

	case "audio":
		return d.handleAudioCommand(parts)

	case cmdGestureOn, "gesture-off":
		return d.handleGestureCommand(parts[0])

	case "center":
		return d.handleCenterCommand(ctx)

	case cmdAutoOn, "auto-off":
		return d.handleAutoCommand(parts[0])

	case "waybar":
		return d.waybarOutput()

	case "sync":
		return d.syncState(ctx)

	case "probe":
		d.probeDevices()

		if d.isDevicePresent() {
			return "device found: " + d.videoDev
		}

		return respDeviceNotFound

	case "pan", "tilt", "zoom":
		return d.handlePTZCommand(ctx, parts)

	case "device":
		if d.videoDev != "" {
			return d.videoDev
		}

		return respDeviceNotFound

	default:
		return "unknown command: " + parts[0]
	}
}

func (d *Daemon) handleTrackingCommand(state pixy.CameraState, label string) string {
	if err := d.setTracking(state); err != nil {
		return fmt.Sprintf("error: %s: %v", label, err)
	}

	if state == pixy.StateTracking {
		return "tracking on"
	}

	if state == pixy.StatePrivacy {
		return "privacy on"
	}

	return "tracking off"
}

func (d *Daemon) handleAudioCommand(parts []string) string {
	var mode pixy.AudioMode
	if len(parts) < 2 {
		mode = d.state.Audio.Next()
	} else {
		var parseErr error

		mode, parseErr = pixy.ParseAudioMode(parts[1])
		if parseErr != nil {
			return respAudioUsage
		}
	}

	audioErr := d.setAudio(mode)
	if audioErr != nil {
		return fmt.Sprintf("error: audio %s: %v", mode, audioErr)
	}

	return "audio: " + string(mode)
}

func (d *Daemon) handleGestureCommand(cmd string) string {
	enable := cmd == cmdGestureOn
	if err := d.setGesture(enable); err != nil {
		return fmt.Sprintf("error: %s: %v", cmd, err)
	}

	if enable {
		return "gesture on"
	}

	return "gesture off"
}

func (d *Daemon) handleCenterCommand(ctx context.Context) string {
	if err := d.centerCamera(ctx); err != nil {
		return fmt.Sprintf("error: center: %v", err)
	}

	return "centered"
}

func (d *Daemon) handleAutoCommand(cmd string) string {
	mode := cmd == cmdAutoOn
	d.state.AutoMode = mode

	if saveErr := d.saveState(); saveErr != nil {
		slog.Error("failed to save state", "error", saveErr)
	}

	if mode {
		return respAutoModeOn
	}

	return respAutoModeOff
}

func (d *Daemon) handlePTZCommand(ctx context.Context, parts []string) string {
	if len(parts) < 2 {
		return fmt.Sprintf("usage: %s <value>", parts[0])
	}

	val, err := strconv.Atoi(parts[1])
	if err != nil {
		return fmt.Sprintf("error: %s: %v", parts[0], errInvalidValue)
	}

	multiplier := v4l2DegreesPerUnit
	if parts[0] == "zoom" {
		multiplier = 1
	}

	if v4l2Err := v4l2Set(ctx, d.videoDev, parts[0]+"_absolute", strconv.Itoa(val*multiplier)); v4l2Err != nil {
		return fmt.Sprintf("error: %s: %v", parts[0], v4l2Err)
	}

	return fmt.Sprintf("%s set to %d", parts[0], val)
}
