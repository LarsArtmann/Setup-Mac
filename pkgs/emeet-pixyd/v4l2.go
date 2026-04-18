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

func parsePTZValues(ctx context.Context, dev string) ptzValues {
	out, err := exec.CommandContext(
		ctx, "v4l2-ctl", "-d", dev,
		"--get-ctrl=pan_absolute,tilt_absolute,zoom_absolute",
	).Output()
	if err != nil {
		return ptzValues{}
	}

	var ptz ptzValues

	for line := range strings.SplitSeq(strings.TrimSpace(string(out)), "\n") {
		key, val, ok := strings.Cut(line, ":")
		if !ok {
			continue
		}

		v, parseErr := strconv.Atoi(strings.TrimSpace(val))
		if parseErr != nil {
			continue
		}

		switch strings.TrimSpace(key) {
		case "pan_absolute":
			ptz.Pan = v / v4l2DegreesPerUnit
		case "tilt_absolute":
			ptz.Tilt = v / v4l2DegreesPerUnit
		case "zoom_absolute":
			ptz.Zoom = v
		}
	}

	return ptz
}
