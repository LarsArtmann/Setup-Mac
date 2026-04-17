//go:build linux

package main

import (
	"context"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

const (
	v4l2DegreesPerUnit = 3600
	v4l2SplitCount     = 2
)

type ptzValues struct {
	Pan  int
	Tilt int
	Zoom int
}

func v4l2Set(ctx context.Context, dev, ctrl, value string) error {
	err := exec.CommandContext(ctx, "v4l2-ctl", "-d", dev, "--set-ctrl="+ctrl+"="+value).
		Run()
	if err != nil {
		return fmt.Errorf("v4l2Set %s=%s on %s: %w", ctrl, value, dev, err)
	}

	return nil
}

func v4l2Get(ctx context.Context, dev, ctrl string) (string, error) {
	out, err := exec.CommandContext(ctx, "v4l2-ctl", "-d", dev, "--get-ctrl="+ctrl).
		Output()
	if err != nil {
		return "", fmt.Errorf("v4l2Get %s on %s: %w", ctrl, dev, err)
	}

	parts := strings.Split(strings.TrimSpace(string(out)), ":")
	if len(parts) == v4l2SplitCount {
		return strings.TrimSpace(parts[1]), nil
	}

	return strings.TrimSpace(string(out)), nil
}

func parsePTZValues(ctx context.Context, dev string) ptzValues {
	pan, _ := v4l2Get(ctx, dev, "pan_absolute")
	tilt, _ := v4l2Get(ctx, dev, "tilt_absolute")
	zoom, _ := v4l2Get(ctx, dev, "zoom_absolute")

	var ptz ptzValues

	panVal, panErr := strconv.Atoi(pan)
	if panErr == nil {
		ptz.Pan = panVal / v4l2DegreesPerUnit
	}

	tiltVal, tiltErr := strconv.Atoi(tilt)
	if tiltErr == nil {
		ptz.Tilt = tiltVal / v4l2DegreesPerUnit
	}

	zoomVal, zoomErr := strconv.Atoi(zoom)
	if zoomErr == nil {
		ptz.Zoom = zoomVal
	}

	return ptz
}
