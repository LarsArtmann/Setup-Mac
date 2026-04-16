package main

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os/exec"
	"strconv"
	"time"

	"github.com/a-h/templ"
)

type server struct {
	socketPath string
}

func newServer(socketPath string) *server {
	return &server{socketPath: socketPath}
}

func (s *server) handleIndex(w http.ResponseWriter, r *http.Request) {
	status := fetchStatus(s.socketPath)
	templ.Handler(page(status)).ServeHTTP(w, r)
}

func (s *server) handleStatusPanel(w http.ResponseWriter, r *http.Request) {
	status := fetchStatus(s.socketPath)
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func (s *server) action(cmd string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		_, err := sendCommand(s.socketPath, cmd)
		if err != nil {
			slog.Error("command failed", "cmd", cmd, "error", err)
		}

		status := fetchStatus(s.socketPath)
		templ.Handler(statusPanel(status)).ServeHTTP(w, r)
	}
}

func (s *server) handleAudio(w http.ResponseWriter, r *http.Request) {
	mode := r.FormValue("mode")
	cmd := "audio"
	if mode != "" {
		cmd = "audio " + mode
	}

	_, err := sendCommand(s.socketPath, cmd)
	if err != nil {
		slog.Error("audio command failed", "error", err)
	}

	status := fetchStatus(s.socketPath)
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func (s *server) handlePTZ(w http.ResponseWriter, r *http.Request) {
	axis := r.PathValue("axis")
	val := r.FormValue("value")
	if axis == "" || val == "" {
		http.Error(w, "missing axis or value", http.StatusBadRequest)

		return
	}

	_, err := sendCommand(s.socketPath, axis+" "+val)
	if err != nil {
		slog.Error("ptz command failed", "axis", axis, "error", err)
	}

	status := fetchStatus(s.socketPath)
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func (s *server) handleSnapshot(w http.ResponseWriter, r *http.Request) {
	status := fetchStatus(s.socketPath)
	if status.Device == "" {
		http.Error(w, "no camera device", http.StatusServiceUnavailable)

		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "ffmpeg",
		"-f", "v4l2", "-i", status.Device,
		"-frames:v", "1",
		"-f", "image2",
		"-q:v", "2",
		"pipe:1",
	)

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		http.Error(w, "ffmpeg pipe error", http.StatusInternalServerError)

		return
	}

	startErr := cmd.Start()
	if startErr != nil {
		http.Error(w, "ffmpeg start error", http.StatusInternalServerError)

		return
	}

	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Cache-Control", "no-store")

	_, copyErr := io.Copy(w, stdout)
	if copyErr != nil {
		slog.Debug("snapshot stream error", "error", copyErr)
	}

	waitErr := cmd.Wait()
	if waitErr != nil {
		slog.Debug("ffmpeg wait error", "error", waitErr)
	}
}

func (s *server) handleStream(w http.ResponseWriter, r *http.Request) {
	status := fetchStatus(s.socketPath)
	if status.Device == "" {
		http.Error(w, "no camera device", http.StatusServiceUnavailable)

		return
	}

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming not supported", http.StatusInternalServerError)

		return
	}

	w.Header().Set("Content-Type", "multipart/x-mixed-replace; boundary=frame")
	w.Header().Set("Cache-Control", "no-store")

	ctx := r.Context()

	for {
		select {
		case <-ctx.Done():
			return
		default:
		}

		cmd := exec.CommandContext(ctx, "ffmpeg",
			"-f", "v4l2", "-i", status.Device,
			"-frames:v", "1",
			"-f", "image2",
			"-q:v", "5",
			"-vf", "scale=640:-1",
			"pipe:1",
		)

		output, err := cmd.Output()
		if err != nil {
			slog.Debug("frame capture error", "error", err)

			return
		}

		fmt.Fprintf(w, "--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %d\r\n\r\n", len(output))
		w.Write(output)
		fmt.Fprint(w, "\r\n")
		flusher.Flush()
	}
}

func (s *server) handleGestureToggle(w http.ResponseWriter, r *http.Request) {
	status := fetchStatus(s.socketPath)

	cmd := "gesture-off"
	if !status.Gesture {
		cmd = "gesture-on"
	}

	_, err := sendCommand(s.socketPath, cmd)
	if err != nil {
		slog.Error("gesture toggle failed", "error", err)
	}

	status = fetchStatus(s.socketPath)
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func (s *server) handleAutoToggle(w http.ResponseWriter, r *http.Request) {
	status := fetchStatus(s.socketPath)

	cmd := "auto-off"
	if !status.Auto {
		cmd = "auto-on"
	}

	_, err := sendCommand(s.socketPath, cmd)
	if err != nil {
		slog.Error("auto toggle failed", "error", err)
	}

	status = fetchStatus(s.socketPath)
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func ptzRange(axis string, val int) string {
	switch axis {
	case "pan":
		return fmt.Sprintf("%d", val*3600)
	case "tilt":
		return fmt.Sprintf("%d", val*3600)
	case "zoom":
		return strconv.Itoa(val)
	default:
		return strconv.Itoa(val)
	}
}
