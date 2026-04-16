package main

import (
	"bytes"
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
	"github.com/larsartmann/systemnix/emeet-pixyd/internal/pixy"
)

const (
	audioCommand    = "audio"
	zoomDefault     = 100
	snapshotTimeout = 3 * time.Second

	maxStreamBufferSize = 10 * 1024 * 1024

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

type webStatus struct {
	Camera  pixy.CameraState
	Audio   pixy.AudioMode
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

type webServer struct {
	daemon *Daemon
}

func (s *webServer) getWebStatus() webStatus {
	s.daemon.mu.RLock()
	defer s.daemon.mu.RUnlock()

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

type ptzValues struct {
	Pan  int
	Tilt int
	Zoom int
}

func parsePTZValues(ctx context.Context, videoDev string) ptzValues {
	pan, _ := v4l2Get(ctx, videoDev, "pan_absolute")
	tilt, _ := v4l2Get(ctx, videoDev, "tilt_absolute")
	zoom, _ := v4l2Get(ctx, videoDev, "zoom_absolute")

	v := ptzValues{Zoom: zoomDefault}
	if n, err := strconv.Atoi(pan); err == nil {
		v.Pan = n / v4l2DegreesPerUnit
	}
	if n, err := strconv.Atoi(tilt); err == nil {
		v.Tilt = n / v4l2DegreesPerUnit
	}
	if n, err := strconv.Atoi(zoom); err == nil {
		v.Zoom = n
	}
	return v
}

func (s *webServer) getWebStatusWithPTZ(ctx context.Context) webStatus {
	status := s.getWebStatus()
	if !status.Online {
		return status
	}

	ptz := parsePTZValues(ctx, s.daemon.videoDev)
	status.Pan = ptz.Pan
	status.Tilt = ptz.Tilt
	status.Zoom = ptz.Zoom

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

	cmd := exec.CommandContext(
		ctx,
		"ffmpeg",
		"-f", "v4l2",
		"-input_format", "mjpeg",
		"-i", status.Device,
		"-f", "image2pipe",
		"-vcodec", "mjpeg",
		"-q:v", "5",
		"-vf", "scale=640:-1",
		"pipe:1",
	)

	stdOut, pipeErr := cmd.StdoutPipe()
	if pipeErr != nil {
		slog.Debug("stream pipe error", "error", pipeErr)

		return
	}

	startErr := cmd.Start()
	if startErr != nil {
		slog.Debug("stream start error", "error", startErr)

		return
	}

	defer func() {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
	}()

	var buf bytes.Buffer

	for {
		select {
		case <-ctx.Done():
			return
		default:
		}

		frame, frameErr := extractJPEGFrame(stdOut, &buf)
		if frameErr != nil {
			slog.Debug("frame extract error", "error", frameErr)

			return
		}

		_, headerErr := fmt.Fprintf(
			responseWriter,
			"--frame\r\nContent-Type: image/jpeg\r\nContent-Length: %d\r\n\r\n",
			len(frame),
		)
		if headerErr != nil {
			return
		}

		_, writeErr := responseWriter.Write(frame)
		if writeErr != nil {
			return
		}

		_, sepErr := fmt.Fprint(responseWriter, "\r\n")
		if sepErr != nil {
			return
		}

		flusher.Flush()
	}
}

func extractJPEGFrame(r io.Reader, buf *bytes.Buffer) ([]byte, error) {
	var soiFound bool

	for {
		if buf.Len() > maxStreamBufferSize {
			buf.Reset()
		}

		var b [1]byte

		_, err := r.Read(b[:])
		if err != nil {
			return nil, fmt.Errorf("read byte: %w", err)
		}

		if !soiFound {
			if b[0] == 0xFF {
				var next [1]byte

				_, nextErr := r.Read(next[:])
				if nextErr != nil {
					return nil, fmt.Errorf("read soi next: %w", nextErr)
				}

				if next[0] == 0xD8 {
					buf.Reset()
					buf.Write([]byte{0xFF, 0xD8})
					soiFound = true
				} else if next[0] == 0xFF {
					b[0] = 0xFF

					continue
				}
			}

			continue
		}

		buf.WriteByte(b[0])

		if b[0] == 0xFF {
			var next [1]byte

			_, nextErr := r.Read(next[:])
			if nextErr != nil {
				return nil, fmt.Errorf("read eoi next: %w", nextErr)
			}

			buf.WriteByte(next[0])

			if next[0] == 0xD9 {
				frame := make([]byte, buf.Len())
				copy(frame, buf.Bytes())

				return frame, nil
			}
		}
	}
}

func (s *webServer) handleGestureToggle(responseWriter http.ResponseWriter, request *http.Request) {
	s.daemon.mu.RLock()
	currentGesture := s.daemon.state.Gesture
	s.daemon.mu.RUnlock()

	cmd := "gesture-off"
	if !currentGesture {
		cmd = cmdGestureOn
	}

	resp := s.daemon.handleCommand(request.Context(), cmd)
	slog.Debug("web gesture toggle", "cmd", cmd, "response", resp)

	status := s.getWebStatusWithPTZ(request.Context())
	templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
}

func (s *webServer) handleAutoToggle(responseWriter http.ResponseWriter, request *http.Request) {
	s.daemon.mu.RLock()
	currentAuto := s.daemon.state.AutoMode
	s.daemon.mu.RUnlock()

	cmd := "auto-off"
	if !currentAuto {
		cmd = cmdAutoOn
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
