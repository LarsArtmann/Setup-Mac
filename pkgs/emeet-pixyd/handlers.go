package main

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/a-h/templ"
)

type webServer struct {
	daemon *Daemon
}

func (s *webServer) getWebStatus() webStatus {
	s.daemon.mu.Lock()
	defer s.daemon.mu.Unlock()

	status := webStatus{
		Camera:  string(s.daemon.state.Camera),
		Audio:   string(s.daemon.state.Audio),
		Gesture: s.daemon.state.Gesture,
		InCall:  s.daemon.state.InCall,
		Auto:    s.daemon.state.AutoMode,
		Online:  s.daemon.videoDev != "",
		Device:  s.daemon.videoDev,
	}

	return status
}

func (s *webServer) getWebStatusWithPTZ(ctx context.Context) webStatus {
	status := s.getWebStatus()
	if !status.Online {
		return status
	}

	pan, _ := v4l2Get(ctx, s.daemon.videoDev, "pan_absolute")
	tilt, _ := v4l2Get(ctx, s.daemon.videoDev, "tilt_absolute")
	zoom, _ := v4l2Get(ctx, s.daemon.videoDev, "zoom_absolute")

	if panVal, err := strconv.Atoi(pan); err == nil {
		status.Pan = panVal / v4l2DegreesPerUnit
	}
	if tiltVal, err := strconv.Atoi(tilt); err == nil {
		status.Tilt = tiltVal / v4l2DegreesPerUnit
	}
	if zoomVal, err := strconv.Atoi(zoom); err == nil {
		status.Zoom = zoomVal
	}

	return status
}

func (s *webServer) handleIndex(w http.ResponseWriter, r *http.Request) {
	status := s.getWebStatusWithPTZ(r.Context())
	templ.Handler(page(status)).ServeHTTP(w, r)
}

func (s *webServer) handleStatusPanel(w http.ResponseWriter, r *http.Request) {
	status := s.getWebStatusWithPTZ(r.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func (s *webServer) action(cmd string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		resp := s.daemon.handleCommand(r.Context(), cmd)
		slog.Debug("web action", "cmd", cmd, "response", resp)

		status := s.getWebStatusWithPTZ(r.Context())
		templ.Handler(statusPanel(status)).ServeHTTP(w, r)
	}
}

func (s *webServer) handleAudio(w http.ResponseWriter, r *http.Request) {
	mode := r.FormValue("mode")
	cmd := "audio"
	if mode != "" {
		cmd = "audio " + mode
	}

	resp := s.daemon.handleCommand(r.Context(), cmd)
	slog.Debug("web audio", "cmd", cmd, "response", resp)

	status := s.getWebStatusWithPTZ(r.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func (s *webServer) handlePTZ(w http.ResponseWriter, r *http.Request) {
	axis := r.PathValue("axis")
	val := r.FormValue("value")
	if axis == "" || val == "" {
		http.Error(w, "missing axis or value", http.StatusBadRequest)

		return
	}

	resp := s.daemon.handleCommand(r.Context(), axis+" "+val)
	slog.Debug("web ptz", "axis", axis, "val", val, "response", resp)

	status := s.getWebStatusWithPTZ(r.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func (s *webServer) handleSnapshot(w http.ResponseWriter, r *http.Request) {
	status := s.getWebStatus()
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

func (s *webServer) handleStream(w http.ResponseWriter, r *http.Request) {
	status := s.getWebStatus()
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

func (s *webServer) handleGestureToggle(w http.ResponseWriter, r *http.Request) {
	s.daemon.mu.Lock()
	currentGesture := s.daemon.state.Gesture
	s.daemon.mu.Unlock()

	cmd := "gesture-off"
	if !currentGesture {
		cmd = "gesture-on"
	}

	resp := s.daemon.handleCommand(r.Context(), cmd)
	slog.Debug("web gesture toggle", "cmd", cmd, "response", resp)

	status := s.getWebStatusWithPTZ(r.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func (s *webServer) handleAutoToggle(w http.ResponseWriter, r *http.Request) {
	s.daemon.mu.Lock()
	currentAuto := s.daemon.state.AutoMode
	s.daemon.mu.Unlock()

	cmd := "auto-off"
	if !currentAuto {
		cmd = "auto-on"
	}

	resp := s.daemon.handleCommand(r.Context(), cmd)
	slog.Debug("web auto toggle", "cmd", cmd, "response", resp)

	status := s.getWebStatusWithPTZ(r.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(w, r)
}

func parseWebStatus(raw string) webStatus {
	s := webStatus{
		Camera: "offline",
		Audio:  "nc",
		Zoom:   100,
	}

	if strings.HasPrefix(raw, "error") {
		s.Error = raw

		return s
	}

	for _, field := range strings.Fields(raw) {
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

func newWebMux(s *webServer) *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /", s.handleIndex)
	mux.HandleFunc("GET /panel", s.handleStatusPanel)

	mux.HandleFunc("POST /api/track", s.action("track"))
	mux.HandleFunc("POST /api/idle", s.action("idle"))
	mux.HandleFunc("POST /api/privacy", s.action("privacy"))
	mux.HandleFunc("POST /api/toggle-privacy", s.action("toggle-privacy"))
	mux.HandleFunc("POST /api/audio", s.handleAudio)
	mux.HandleFunc("POST /api/gesture", s.handleGestureToggle)
	mux.HandleFunc("POST /api/auto", s.handleAutoToggle)
	mux.HandleFunc("POST /api/center", s.action("center"))
	mux.HandleFunc("POST /api/sync", s.action("sync"))
	mux.HandleFunc("POST /api/probe", s.action("probe"))
	mux.HandleFunc("POST /api/ptz/{axis}", s.handlePTZ)
	mux.HandleFunc("GET /api/snapshot", s.handleSnapshot)
	mux.HandleFunc("GET /api/stream", s.handleStream)

	return mux
}
