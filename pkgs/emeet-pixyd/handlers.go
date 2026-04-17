//go:build linux

package main

import (
	"bufio"
	"bytes"
	"context"
	"embed"
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
	audioCommand        = "audio"
	offlineValue        = "offline"
	zoomDefault         = 100
	snapshotTimeout     = 3 * time.Second
	maxStreamBufferSize = 10 * 1024 * 1024
	maxBodyBytes        = 1 << 10

	panMin = -170
	panMax = 170
	tiltMin = -30
	tiltMax = 30
	zoomMin = 100
	zoomMax = 400
)

//go:embed static
var staticFS embed.FS

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
	s.daemon.mu.Lock()
	defer s.daemon.mu.Unlock()
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
		http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)

		resp := s.daemon.handleCommand(request.Context(), command)

		slog.Debug("web action", "cmd", command, "response", resp)

		status := s.getWebStatusWithPTZ(request.Context())

		templ.Handler(statusPanel(status)).ServeHTTP(responseWriter, request)
	}
}

func (s *webServer) handleAudio(responseWriter http.ResponseWriter, request *http.Request) {
	http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)
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
	case "pan":
		return panMin, panMax
	case "tilt":
		return tiltMin, tiltMax
	case "zoom":
		return zoomMin, zoomMax
	default:
		return 0, 0
	}
}

func (s *webServer) handlePTZ(responseWriter http.ResponseWriter, request *http.Request) {
	http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)
	axis := request.PathValue("axis")
	val := request.FormValue("value")
	if axis == "" || val == "" {

		http.Error(responseWriter, "missing axis or value", http.StatusBadRequest)

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
	case "pan":

		templ.Handler(ptzSlider("Pan", "pan", panMin, panMax, status.Pan, "\u00b0")).
			ServeHTTP(responseWriter, request)
	case "tilt":

		templ.Handler(ptzSlider("Tilt", "tilt", tiltMin, tiltMax, status.Tilt, "\u00b0")).
			ServeHTTP(responseWriter, request)
	case "zoom":

		templ.Handler(ptzSlider("Zoom", "zoom", zoomMin, zoomMax, status.Zoom, "x")).
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
	status, ok := s.checkDevice(responseWriter)
	if !ok {

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
	br := bufio.NewReaderSize(r, 64*1024)
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
	http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)
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
	http.MaxBytesReader(responseWriter, request.Body, maxBodyBytes)
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

		case "pan":

			status.Pan, _ = strconv.Atoi(val)

		case "tilt":

			status.Tilt, _ = strconv.Atoi(val)

		case "zoom":

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

func newWebMux(server *webServer) *http.ServeMux {
	mux := http.NewServeMux()
	mux.Handle("GET /static/", http.FileServer(http.FS(staticFS)))
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
