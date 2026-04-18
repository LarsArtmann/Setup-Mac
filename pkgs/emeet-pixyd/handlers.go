//go:build linux

package main

import (
	"bufio"
	"bytes"
	"context"
	"embed"
	"fmt"
	"log/slog"
	"net/http"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/a-h/templ"
	"github.com/larsartmann/systemnix/emeet-pixyd/internal/pixy"
)

const (
	audioCommand        = "audio"
	offlineValue        = "offline"
	zoomDefault         = 100
	maxStreamBufferSize = 10 * 1024 * 1024
	maxBodyBytes        = 1 << 10

	panMin = -170
	panMax = 170
	tiltMin = -30
	tiltMax = 30
	zoomMin = 100
	zoomMax = 400

	staticCacheMaxAge = 7 * 24 * time.Hour
)

//go:embed static
var staticFS embed.FS

var lastFrame struct {
	sync.RWMutex
	data []byte
}

func formatLastSynced(t time.Time) string {
	if t.IsZero() {
		return ""
	}

	elapsed := time.Since(t)
	if elapsed < time.Minute {
		return "just now"
	}
	if elapsed < time.Hour {
		return fmt.Sprintf("%dm ago", int(elapsed.Minutes()))
	}

	return t.Format("15:04")
}

type webServer struct {
	daemon *Daemon
}

func (s *webServer) getWebStatus() webStatus {
	s.daemon.mu.RLock()
	defer s.daemon.mu.RUnlock()
	status := webStatus{

		Camera: string(s.daemon.state.Camera),

		Audio: string(s.daemon.state.Audio),

		Gesture: s.daemon.state.Gesture,

		Pan: 0,

		Tilt: 0,

		Zoom: 0,

		InCall: s.daemon.state.InCall,

		Auto: s.daemon.state.AutoMode,

		Online: s.daemon.videoDev != "",

		Device: s.daemon.videoDev,

		LastSynced: formatLastSynced(s.daemon.lastSyncedAt),
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
	dev := status.Device
	ptz := parsePTZValues(ctx, dev)
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
		request.Body = http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)

		resp := s.daemon.handleCommand(request.Context(), command)

		slog.Debug("web action", "cmd", command, "response", resp)

		status := s.getWebStatusWithPTZ(request.Context())
		if strings.HasPrefix(resp, "error:") {
			status.Error = resp
		}

		templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
	}
}

func (s *webServer) handleAudio(responseWriter http.ResponseWriter, request *http.Request) {
	request.Body = http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)
	mode := request.FormValue("mode")
	cmd := audioCommand
	if mode != "" {

		cmd = audioCommand + " " + mode
	}
	resp := s.daemon.handleCommand(request.Context(), cmd)
	slog.Debug("web audio", "cmd", cmd, "response", resp)
	status := s.getWebStatusWithPTZ(request.Context())
	if strings.HasPrefix(resp, "error:") {
		status.Error = resp
	}
	templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
}

func clampInt(v, lo, hi int) int {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

func ptzLimits(axis string) (int, int) {
	switch axis {
	case axisPan:
		return panMin, panMax
	case axisTilt:
		return tiltMin, tiltMax
	case axisZoom:
		return zoomMin, zoomMax
	default:
		return 0, 0
	}
}

func (s *webServer) handlePTZ(responseWriter http.ResponseWriter, request *http.Request) {
	request.Body = http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)
	axis := request.PathValue("axis")
	val := request.FormValue("value")
	if axis == "" || val == "" {

		http.Error(responseWriter, "missing axis or value", http.StatusBadRequest)

		return
	}
	if !ptzAxisValid(axis) {
		http.Error(responseWriter, "invalid axis", http.StatusBadRequest)
		return
	}
	intVal, err := strconv.Atoi(val)
	if err != nil {
		http.Error(responseWriter, "invalid value", http.StatusBadRequest)
		return
	}
	lo, hi := ptzLimits(axis)
	intVal = clampInt(intVal, lo, hi)
	resp := s.daemon.handleCommand(request.Context(), axis+" "+strconv.Itoa(intVal))
	slog.Debug("web ptz", "axis", axis, "val", intVal, "response", resp)
	status := s.getWebStatusWithPTZ(request.Context())
	switch axis {
	case axisPan:

		templ.Handler(ptzSlider("Pan", axisPan, panMin, panMax, status.Pan, "\u00b0")).
			ServeHTTP(responseWriter, request)
	case axisTilt:

		templ.Handler(ptzSlider("Tilt", axisTilt, tiltMin, tiltMax, status.Tilt, "\u00b0")).
			ServeHTTP(responseWriter, request)
	case axisZoom:

		templ.Handler(ptzSlider("Zoom", axisZoom, zoomMin, zoomMax, status.Zoom, "x")).
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
	lastFrame.RLock()
	frame := lastFrame.data
	lastFrame.RUnlock()

	if len(frame) == 0 {
		http.Error(responseWriter, "no frame available", http.StatusServiceUnavailable)

		return
	}

	responseWriter.Header().Set("Content-Type", "image/jpeg")
	responseWriter.Header().Set("Cache-Control", "no-store")
	_, _ = responseWriter.Write(frame)
}

func (s *webServer) handleStream(responseWriter http.ResponseWriter, request *http.Request) {
	status, ok := s.checkDevice(responseWriter)
	if !ok {

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
		_ = cmd.Process.Signal(syscall.SIGTERM)
		done := make(chan error, 1)
		go func() { done <- cmd.Wait() }()
		select {
		case <-done:
		case <-time.After(2 * time.Second):
			_ = cmd.Process.Kill()
			_ = cmd.Wait()
		}
	}()
	br := bufio.NewReaderSize(stdOut, 64*1024)
	var buf bytes.Buffer
	for {

		select {

		case <-ctx.Done():

			return

		default:

		}

		frame, frameErr := extractJPEGFrame(br, &buf)

		if frameErr != nil {

			slog.Debug("frame extract error", "error", frameErr)

			return

		}

		lastFrame.Lock()
		lastFrame.data = frame
		lastFrame.Unlock()

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

func extractJPEGFrame(br *bufio.Reader, buf *bytes.Buffer) ([]byte, error) {
	var soiFound bool
	for {
		if buf.Len() > maxStreamBufferSize {
			buf.Reset()
		}

		b, err := br.ReadByte()
		if err != nil {
			return nil, fmt.Errorf("read byte: %w", err)
		}

		if !soiFound {
			if b == 0xFF {
				next, nextErr := br.ReadByte()
				if nextErr != nil {
					return nil, fmt.Errorf("read soi next: %w", nextErr)
				}
				if next == 0xD8 {
					buf.Reset()
					buf.Write([]byte{0xFF, 0xD8})
					soiFound = true
				} else if next == 0xFF {
					_ = br.UnreadByte()
				}
			}
			continue
		}

		buf.WriteByte(b)

		if b == 0xFF {
			next, nextErr := br.ReadByte()
			if nextErr != nil {
				return nil, fmt.Errorf("read eoi next: %w", nextErr)
			}
			buf.WriteByte(next)
			if next == 0xD9 {
				frame := make([]byte, buf.Len())
				copy(frame, buf.Bytes())
				return frame, nil
			}
		}
	}
}

func (s *webServer) handleGestureToggle(responseWriter http.ResponseWriter, request *http.Request) {
	request.Body = http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)
	s.daemon.mu.RLock()
	currentGesture := s.daemon.state.Gesture
	s.daemon.mu.RUnlock()
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
	request.Body = http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)
	s.daemon.mu.RLock()
	currentAuto := s.daemon.state.AutoMode
	s.daemon.mu.RUnlock()
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

		Camera: string(pixy.StateOffline),

		Audio: string(pixy.AudioNC),

		Pan: 0,

		Tilt: 0,

		Zoom: zoomDefault,
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

			camera, _ := pixy.ParseCameraState(val)

			status.Camera = string(camera)

			status.Online = val != offlineValue

		case "audio":

			audio, _ := pixy.ParseAudioMode(val)

			status.Audio = string(audio)

		case "gesture":

			status.Gesture = val == "true"

		case axisPan:

			status.Pan, _ = strconv.Atoi(val)

		case axisTilt:

			status.Tilt, _ = strconv.Atoi(val)

		case axisZoom:

			status.Zoom, _ = strconv.Atoi(val)

		case "in_call":

			status.InCall = val == "yes"

		case "auto":

			status.Auto = val == "on"

		case "device":

			status.Device = val

		}
	}
	return status
}

type cachingFS struct {
	handler http.Handler
}

func (c cachingFS) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-Control", fmt.Sprintf("public, max-age=%d", int64(staticCacheMaxAge.Seconds())))
	w.Header().Set("X-Content-Type-Options", "nosniff")
	c.handler.ServeHTTP(w, r)
}

func ptzAxisValid(axis string) bool {
	switch axis {
	case axisPan, axisTilt, axisZoom:
		return true
	default:
		return false
	}
}

func securityMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Referrer-Policy", "no-referrer")
		next.ServeHTTP(w, r)
	})
}

func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reqID := r.Header.Get("X-Request-ID")
		if reqID == "" {
			reqID = fmt.Sprintf("%08x", time.Now().UnixNano()&0xFFFFFFFF)
		}
		w.Header().Set("X-Request-ID", reqID)
		next.ServeHTTP(w, r)
	})
}

func newWebMux(server *webServer) *http.ServeMux {
	mux := http.NewServeMux()
	mux.Handle("GET /static/", cachingFS{handler: http.FileServer(http.FS(staticFS))})
	mux.HandleFunc("GET /{$}", server.handleIndex)
	mux.HandleFunc("GET /panel", server.handleStatusPanel)
	mux.HandleFunc("POST /api/track", server.action("track"))
	mux.HandleFunc("POST /api/idle", server.action("idle"))
	mux.HandleFunc("POST /api/privacy", server.action(cmdPrivacy))
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
