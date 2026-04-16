package main

import (
	"context"
	"fmt"
	"net"
	"strconv"
	"strings"
	"time"
)

const (
	defaultSocketTimeout = 2 * time.Second
	defaultWriteTimeout  = 2 * time.Second
	socketBufSize        = 256
	connBufSize          = 4096
)

type Status struct {
	Camera  string
	Audio   string
	Gesture bool
	Pan     int
	Tilt    int
	Zoom    int
	InCall  bool
	Auto    bool
	Online  bool
	Device  string
	Error   string
}

func sendCommand(socketPath, cmd string) (string, error) {
	dialer := net.Dialer{Timeout: defaultSocketTimeout}

	conn, err := dialer.DialContext(context.Background(), "unix", socketPath)
	if err != nil {
		return "", fmt.Errorf("dial: %w", err)
	}

	defer func() { _ = conn.Close() }()

	deadlineErr := conn.SetDeadline(time.Now().Add(defaultWriteTimeout))
	if deadlineErr != nil {
		return "", deadlineErr
	}

	_, writeErr := conn.Write([]byte(cmd))
	if writeErr != nil {
		return "", fmt.Errorf("write: %w", writeErr)
	}

	buf := make([]byte, connBufSize)

	n, readErr := conn.Read(buf)
	if readErr != nil {
		return "", fmt.Errorf("read: %w", readErr)
	}

	return strings.TrimSpace(string(buf[:n])), nil
}

func parseStatus(raw string) Status {
	s := Status{
		Camera: "offline",
		Audio:  "nc",
		Zoom:   100,
	}

	if strings.HasPrefix(raw, "error") {
		s.Error = raw

		return s
	}

	for field := range strings.FieldsSeq(raw) {
		key, val, ok := strings.Cut(field, "=")
		if !ok {
			continue
		}

		switch key {
		case "camera":
			s.Camera = val
			s.Online = val != "offline"
		case "audio":
			s.Audio = val
		case "gesture":
			s.Gesture = val == "true"
		case "pan":
			s.Pan, _ = strconv.Atoi(val)
		case "tilt":
			s.Tilt, _ = strconv.Atoi(val)
		case "zoom":
			s.Zoom, _ = strconv.Atoi(val)
		case "in_call":
			s.InCall = val == "yes"
		case "auto":
			s.Auto = val == "on"
		case "device":
			s.Device = val
		}
	}

	return s
}

func fetchStatus(socketPath string) Status {
	raw, err := sendCommand(socketPath, "status")
	if err != nil {
		return Status{
			Camera: "offline",
			Audio:  "nc",
			Zoom:   100,
			Error:  fmt.Sprintf("daemon not reachable: %v", err),
		}
	}

	return parseStatus(raw)
}
