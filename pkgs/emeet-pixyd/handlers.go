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

const (
	audioCommand    = "audio"
	zoomDefault     = 100
	snapshotTimeout = 3 * time.Second

	ptzAxisPan  = "pan"
	ptzAxisTilt = "tilt"
	ptzAxisZoom = "zoom"
	inCallYes   = "yes"

	ptzPanMin  = -170
	ptzPanMax  = 170
	ptzTiltMin = -30
	ptzTiltMax = 30
	ptzZoomMin = 100
	ptzZoomMax = 400
)

type webServer struct {
	daemon *Daemon
}

func (s *webServer) getWebStatus() webStatus {
	s.daemon.mu.Lock()
	defer s.daemon.mu.Unlock()

	status := webStatus{
		Camera:  s.daemon.state.Camera,
		Audio:   s.daemon.state.Audio,
		Gesture: s.daemon.state.Gesture,
		Pan:     0,
		Tilt:    0,
		Zoom:    0,
		InCall:  s.daemon.state.InCall,
		Auto:    s.daemon.state.AutoMode,
		Online:  s.daemon.videoDev != "",
		Device:  s.daemon.videoDev,
	}

	if status.Online {
		status.Zoom = zoomDefault
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

	panVal, panErr := strconv.Atoi(pan)
	if panErr == nil {
		status.Pan = panVal / v4l2DegreesPerUnit
	}

	tiltVal, tiltErr := strconv.Atoi(tilt)
	if tiltErr == nil {
		status.Tilt = tiltVal / v4l2DegreesPerUnit
	}

	zoomVal, zoomErr := strconv.Atoi(zoom)
	if zoomErr == nil {
		status.Zoom = zoomVal
	}

	return status
}

func (s *webServer) handleIndex(responseWriter http.ResponseWriter, request *http.Request) {
	status := s.getWebStatusWithPTZ(request.Context())
	templ.Handler(page(status)).ServeHTTP(responseWriter, request)
}

func (s *webServer) handleStatusPanel(responseWriter http.ResponseWriter, request *http.Request) {
	status := s.getWebStatusWithPTZ(request.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
}

func (s *webServer) action(command string) http.HandlerFunc {
	return func(responseWriter http.ResponseWriter, request *http.Request) {
		resp := s.daemon.handleCommand(request.Context(), command)
		slog.Debug("web action", "cmd", command, "response", resp)

		status := s.getWebStatusWithPTZ(request.Context())
		templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
	}
}

func (s *webServer) handleAudio(responseWriter http.ResponseWriter, request *http.Request) {
	mode := request.FormValue("mode")

	cmd := audioCommand
	if mode != "" {
		cmd = audioCommand + " " + mode
	}

	resp := s.daemon.handleCommand(request.Context(), cmd)
	slog.Debug("web audio", "cmd", cmd, "response", resp)

	status := s.getWebStatusWithPTZ(request.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
}

func (s *webServer) handlePTZ(responseWriter http.ResponseWriter, request *http.Request) {
	axis := request.PathValue("axis")

	val := request.FormValue("value")
	if axis == "" || val == "" {
		http.Error(responseWriter, "missing axis or value", http.StatusBadRequest)

		return
	}

	resp := s.daemon.handleCommand(request.Context(), axis+" "+val)
	slog.Debug("web ptz", "axis", axis, "val", val, "response", resp)

	status := s.getWebStatusWithPTZ(request.Context())

	switch axis {
	case ptzAxisPan:
		templ.Handler(ptzSlider("Pan", ptzAxisPan, ptzPanMin, ptzPanMax, status.Pan, "\u00b0")).
			ServeHTTP(responseWriter, request)
	case ptzAxisTilt:
		templ.Handler(ptzSlider("Tilt", ptzAxisTilt, ptzTiltMin, ptzTiltMax, status.Tilt, "\u00b0")).
			ServeHTTP(responseWriter, request)
	case ptzAxisZoom:
		templ.Handler(ptzSlider("Zoom", ptzAxisZoom, ptzZoomMin, ptzZoomMax, status.Zoom, "x")).
			ServeHTTP(responseWriter, request)
	default:
		templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
	}
}

func (s *webServer) checkDevice(responseWriter http.ResponseWriter) (webStatus, bool) {
	status := s.getWebStatus()
	if status.Device == "" {
		http.Error(responseWriter, "no camera device", http.StatusServiceUnavailable)

		return status, false
	}

	return status, true
}

func (s *webServer) handleSnapshot(responseWriter http.ResponseWriter, request *http.Request) {
	status, hasDevice := s.checkDevice(responseWriter)
	if !hasDevice {
		return
	}

	ctx, cancel := context.WithTimeout(request.Context(), snapshotTimeout)
	defer cancel()

	cmd := exec.CommandContext(
		ctx,
		"ffmpeg",
		"-f",
		"v4l2",
		"-i",
		status.Device,
		"-frames:v",
		"1",
		"-f",
		"image2",
		"-q:v",
		"2",
		"pipe:1",
	)

	stdOut, err := cmd.StdoutPipe()
	if err != nil {
		http.Error(responseWriter, "ffmpeg pipe error", http.StatusInternalServerError)

		return
	}

	startErr := cmd.Start()
	if startErr != nil {
		http.Error(responseWriter, "ffmpeg start error", http.StatusInternalServerError)

		return
	}

	responseWriter.Header().Set("Content-Type", "image/jpeg")
	responseWriter.Header().Set("Cache-Control", "no-store")

	_, copyErr := io.Copy(responseWriter, stdOut)
	if copyErr != nil {
		slog.Debug("snapshot stream error", "error", copyErr)
	}

	waitErr := cmd.Wait()
	if waitErr != nil {
		slog.Debug("ffmpeg wait error", "error", waitErr)
	}
}

func (s *webServer) handleStream(responseWriter http.ResponseWriter, request *http.Request) {
	status, hasDevice := s.checkDevice(responseWriter)
	if !hasDevice {
		return
	}

	flusher, flushOk := responseWriter.(http.Flusher)
	if !flushOk {
		http.Error(responseWriter, "streaming not supported", http.StatusInternalServerError)

		return
	}

	responseWriter.Header().Set("Content-Type", "multipart/x-mixed-replace; boundary=frame")
	responseWriter.Header().Set("Cache-Control", "no-store")

	ctx := request.Context()

	for {
		select {
		case <-ctx.Done():
			return
		default:
		}

		cmd := exec.CommandContext(
			ctx,
			"ffmpeg",
			"-f",
			"v4l2",
			"-i",
			status.Device,
			"-frames:v",
			"1",
			"-f",
			"image2",
			"-q:v",
			"5",
			"-vf",
			"scale=640:-1",
			"pipe:1",
		)

		output, err := cmd.Output()
		if err != nil {
			slog.Debug("frame capture error", "error", err)

			return
		}

		_, fErr := fmt.Fprintf(
			responseWriter,
			"--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %d\r\n\r\n",
			len(output),
		)
		if fErr != nil {
			slog.Debug("stream write error", "error", fErr)

			return
		}

		_, wErr := responseWriter.Write(output)
		if wErr != nil {
			slog.Debug("stream write error", "error", wErr)

			return
		}

		_, pfErr := fmt.Fprint(responseWriter, "\r\n")
		if pfErr != nil {
			slog.Debug("stream write error", "error", pfErr)

			return
		}

		flusher.Flush()
	}
}

func (s *webServer) handleGestureToggle(responseWriter http.ResponseWriter, request *http.Request) {
	s.daemon.mu.Lock()
	currentGesture := s.daemon.state.Gesture
	s.daemon.mu.Unlock()

	cmd := "gesture-off"
	if !currentGesture {
		cmd = "gesture-on"
	}

	resp := s.daemon.handleCommand(request.Context(), cmd)
	slog.Debug("web gesture toggle", "cmd", cmd, "response", resp)

	status := s.getWebStatusWithPTZ(request.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
}

func (s *webServer) handleAutoToggle(responseWriter http.ResponseWriter, request *http.Request) {
	s.daemon.mu.Lock()
	currentAuto := s.daemon.state.AutoMode
	s.daemon.mu.Unlock()

	cmd := "auto-off"
	if !currentAuto {
		cmd = "auto-on"
	}

	resp := s.daemon.handleCommand(request.Context(), cmd)
	slog.Debug("web auto toggle", "cmd", cmd, "response", resp)

	status := s.getWebStatusWithPTZ(request.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
}

func parseWebStatus(raw string) webStatus {
	status := webStatus{
		Camera: StateOffline,
		Audio:  AudioNC,
		Pan:    0,
		Tilt:   0,
		Zoom:   zoomDefault,
	}

	if strings.HasPrefix(raw, "error") {
		status.Error = raw

		return status
	}

	for field := range strings.FieldsSeq(raw) {
		key, val, ok := strings.Cut(field, "=")
		if !ok {
			continue
		}

		switch key {
		case "camera":
			if cam, camErr := ParseCameraState(val); camErr == nil {
				status.Camera = cam
			}
			status.Online = status.Camera != StateOffline
		case "audio":
			if aud, audErr := ParseAudioMode(val); audErr == nil {
				status.Audio = aud
			}
		case "gesture":
			status.Gesture = val == "true"
		case ptzAxisPan:
			status.Pan, _ = strconv.Atoi(val)
		case ptzAxisTilt:
			status.Tilt, _ = strconv.Atoi(val)
		case ptzAxisZoom:
			status.Zoom, _ = strconv.Atoi(val)
		case "in_call":
			status.InCall = val == inCallYes
		case "auto":
			status.Auto = val == "on"
		case "device":
			status.Device = val
		}
	}

	return status
}

func newWebMux(server *webServer) *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /{$}", server.handleIndex)
	mux.HandleFunc("GET /panel", server.handleStatusPanel)

	mux.HandleFunc("POST /api/track", server.action("track"))
	mux.HandleFunc("POST /api/idle", server.action("idle"))
	mux.HandleFunc("POST /api/privacy", server.action("privacy"))
	mux.HandleFunc("POST /api/toggle-privacy", server.action("toggle-privacy"))
	mux.HandleFunc("POST /api/audio", server.handleAudio)
	mux.HandleFunc("POST /api/gesture", server.handleGestureToggle)
	mux.HandleFunc("POST /api/auto", server.handleAutoToggle)
	mux.HandleFunc("POST /api/center", server.action("center"))
	mux.HandleFunc("POST /api/sync", server.action("sync"))
	mux.HandleFunc("POST /api/probe", server.action("probe"))
	mux.HandleFunc("POST /api/ptz/{axis}", server.handlePTZ)
	mux.HandleFunc("POST /api/ptz/", func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "missing axis", http.StatusBadRequest)
	})
	mux.HandleFunc("GET /api/snapshot", server.handleSnapshot)
	mux.HandleFunc("GET /api/stream", server.handleStream)

	return mux
}
