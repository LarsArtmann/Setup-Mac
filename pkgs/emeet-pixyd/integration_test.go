package main

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/larsartmann/systemnix/emeet-pixyd/internal/pixy"
)

func newIntegrationDaemon(t *testing.T) *Daemon {
	t.Helper()

	return &Daemon{
		mu:  sync.Mutex{},
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		config:        Config{StateDir: t.TempDir(), PollInterval: 2, DebounceCount: 3},
		videoDev:      "",
		hidrawDev:     "",
		debounceInUse: 0,
		debounceIdle:  0,
	}
}

func newDaemonWithDevice(t *testing.T) *Daemon {
	t.Helper()

	d := newIntegrationDaemon(t)
	d.videoDev = "/dev/video0"
	d.hidrawDev = "/dev/hidraw7"

	return d
}

func newTestWebServer(t *testing.T, daemon *Daemon) (*webServer, *httptest.Server) {
	t.Helper()

	webSrv := &webServer{daemon: daemon}
	mux := newWebMux(webSrv)
	server := httptest.NewServer(mux)
	t.Cleanup(server.Close)

	return webSrv, server
}

func getBody(t *testing.T, resp *http.Response) string {
	t.Helper()

	body, err := io.ReadAll(resp.Body)

	if err != nil {
		t.Fatalf("read body: %v", err)
	}

	return string(body)
}

func assertContains(t *testing.T, haystack, needle, label string) {
	t.Helper()

	if !strings.Contains(haystack, needle) {
		t.Errorf("%s: expected body to contain %q", label, needle)
	}
}

func assertNotContains(t *testing.T, haystack, needle, label string) {
	t.Helper()

	if strings.Contains(haystack, needle) {
		t.Errorf("%s: expected body NOT to contain %q", label, needle)
	}
}

func post(t *testing.T, url, contentType string, body io.Reader) *http.Response {
	t.Helper()

	resp, err := http.Post(url, contentType, body)
	if err != nil {
		t.Fatalf("POST %s: %v", url, err)
	}

	return resp
}

func get(t *testing.T, url string) *http.Response {
	t.Helper()

	resp, err := http.Get(url)
	if err != nil {
		t.Fatalf("GET %s: %v", url, err)
	}

	return resp
}

// ---------- Index page ----------

func TestWeb_IndexReturnsHTML(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := get(t, server.URL+"/")
	defer resp.Body.Close()

	body := getBody(t, resp)

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	assertContains(t, body, "<!DOCTYPE html>", "index page")
	assertContains(t, body, "EMEET PIXY", "index page title")
	assertContains(t, body, "status-panel", "index has status panel")
}

func TestWeb_IndexShowsOfflineWhenNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := get(t, server.URL+"/")
	defer resp.Body.Close()

	body := getBody(t, resp)

	assertContains(t, body, "Offline", "offline badge")
	assertContains(t, body, "camera=offline", "status shows offline")
}

func TestWeb_IndexShowsOnlineWithDevice(t *testing.T) {
	daemon := newDaemonWithDevice(t)
	_, server := newTestWebServer(t, daemon)

	resp := get(t, server.URL+"/")
	defer resp.Body.Close()

	body := getBody(t, resp)

	assertContains(t, body, "Online", "online badge")
	assertNotContains(t, body, "Offline", "should not show offline")
}

// ---------- Status panel (HTMX partial) ----------

func TestWeb_PanelReturnsHTMLFragment(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := get(t, server.URL+"/panel")
	defer resp.Body.Close()

	body := getBody(t, resp)

	assertContains(t, body, "status-panel", "panel has status-panel div")
	assertContains(t, body, "Track", "panel has track button")
	assertContains(t, body, "Privacy", "panel has privacy button")
	assertContains(t, body, "Noise Cancel", "panel has audio buttons")
}

func TestWeb_PanelReflectsDaemonState(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := get(t, server.URL+"/panel")
	defer resp.Body.Close()

	body := getBody(t, resp)

	assertContains(t, body, "privacy", "panel shows privacy state")
	assertContains(t, body, "gesture", "panel has gesture control")
}

// ---------- Auto toggle ----------

func TestWeb_AutoToggleOff(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/auto", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	daemon.mu.Lock()
	isAuto := daemon.state.AutoMode
	daemon.mu.Unlock()

	if isAuto {
		t.Error("expected auto=false after toggle from true")
	}
}

func TestWeb_AutoToggleOn(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	daemon.state.AutoMode = false
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/auto", "", nil)
	defer resp.Body.Close()

	daemon.mu.Lock()
	isAuto := daemon.state.AutoMode
	daemon.mu.Unlock()

	if !isAuto {
		t.Error("expected auto=true after toggle from false")
	}
}

func TestWeb_AutoToggleRoundTrip(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	post(t, server.URL+"/api/auto", "", nil).Body.Close()

	daemon.mu.Lock()
	if daemon.state.AutoMode {
		t.Fatal("first toggle should turn auto off")
	}
	daemon.mu.Unlock()

	post(t, server.URL+"/api/auto", "", nil).Body.Close()

	daemon.mu.Lock()
	if !daemon.state.AutoMode {
		t.Fatal("second toggle should turn auto back on")
	}
	daemon.mu.Unlock()
}

// ---------- Gesture toggle ----------

func TestWeb_GestureToggleEndpoint(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/gesture", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_GestureToggleReturnsPanel(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/gesture", "", nil)
	defer resp.Body.Close()

	body := getBody(t, resp)
	assertContains(t, body, "status-panel", "gesture response is panel fragment")
}

// ---------- Audio endpoint ----------

func TestWeb_AudioWithValidModes(t *testing.T) {
	for _, mode := range []string{"nc", "live", "org"} {
		t.Run(mode, func(t *testing.T) {
			daemon := newIntegrationDaemon(t)
			_, server := newTestWebServer(t, daemon)

			resp := post(t, server.URL+"/api/audio", "application/x-www-form-urlencoded", strings.NewReader("mode="+mode))
			defer resp.Body.Close()

			if resp.StatusCode != http.StatusOK {
				t.Fatalf("expected 200 for mode=%s, got %d", mode, resp.StatusCode)
			}
		})
	}
}

func TestWeb_AudioInvalidMode(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/audio", "application/x-www-form-urlencoded", strings.NewReader("mode=blorp"))
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	body := getBody(t, resp)
	assertContains(t, body, "status-panel", "still returns panel even on invalid mode")
}

func TestWeb_AudioNoModeParam(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/audio", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

// ---------- PTZ endpoint ----------

func TestWeb_PTZMissingAxis(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/ptz/", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("expected 400 for missing axis, got %d", resp.StatusCode)
	}
}

func TestWeb_PTZMissingValue(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/ptz/pan", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("expected 400 for missing value, got %d", resp.StatusCode)
	}
}

func TestWeb_PTZWithAxisAndValue(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/ptz/pan", "application/x-www-form-urlencoded", strings.NewReader("value=10"))
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

// ---------- Track/Idle/Privacy ----------

func TestWeb_TrackEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/track", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_IdleEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/idle", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_PrivacyEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/privacy", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_TogglePrivacyEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/toggle-privacy", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_CenterEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/center", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

// ---------- Probe/Sync ----------

func TestWeb_ProbeEndpoint(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/probe", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	body := getBody(t, resp)
	assertContains(t, body, "status-panel", "probe returns panel")
}

func TestWeb_SyncEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := post(t, server.URL+"/api/sync", "", nil)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

// ---------- Snapshot/Stream (require device) ----------

func TestWeb_SnapshotNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := get(t, server.URL+"/api/snapshot")
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusServiceUnavailable {
		t.Errorf("expected 503, got %d", resp.StatusCode)
	}

	body := getBody(t, resp)
	assertContains(t, body, "no camera device", "503 body")
}

func TestWeb_StreamNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := get(t, server.URL+"/api/stream")
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusServiceUnavailable {
		t.Errorf("expected 503, got %d", resp.StatusCode)
	}

	body := getBody(t, resp)
	assertContains(t, body, "no camera device", "503 body")
}

// ---------- Method enforcement ----------

func TestWeb_POSTEndpointsRejectGET(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	endpoints := []string{
		"/api/track",
		"/api/idle",
		"/api/privacy",
		"/api/toggle-privacy",
		"/api/audio",
		"/api/gesture",
		"/api/auto",
		"/api/center",
		"/api/sync",
		"/api/probe",
	}

	for _, ep := range endpoints {
		t.Run(ep, func(t *testing.T) {
			resp, err := http.Get(server.URL + ep)
			if err != nil {
				t.Fatalf("GET %s: %v", ep, err)
			}

			resp.Body.Close()

			if resp.StatusCode == http.StatusOK {
				t.Errorf("GET %s should not be 200, got %d", ep, resp.StatusCode)
			}
		})
	}
}

func TestWeb_GETEndpointsRejectPOST(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	endpoints := []string{"/", "/panel", "/api/snapshot", "/api/stream"}

	for _, ep := range endpoints {
		t.Run(ep, func(t *testing.T) {
			resp, err := http.Post(server.URL+ep, "", nil)
			if err != nil {
				t.Fatalf("POST %s: %v", ep, err)
			}

			resp.Body.Close()

			if resp.StatusCode == http.StatusOK {
				t.Errorf("POST %s should not be 200, got %d", ep, resp.StatusCode)
			}
		})
	}
}

// ---------- 404 for unknown routes ----------

func TestWeb_UnknownRouteReturns404(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp := get(t, server.URL+"/api/nonexistent")
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		t.Errorf("expected 404 for unknown route, got %d", resp.StatusCode)
	}
}

// ---------- webStatus mapping ----------

func TestWeb_WebStatusOfflineNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	webSrv := &webServer{daemon: daemon}

	status := webSrv.getWebStatus()

	if status.Camera != "privacy" {
		t.Errorf("expected camera=privacy, got %s", status.Camera)
	}

	if status.Audio != "nc" {
		t.Errorf("expected audio=nc, got %s", status.Audio)
	}

	if status.Gesture {
		t.Error("expected gesture=false")
	}

	if !status.Auto {
		t.Error("expected auto=true")
	}

	if status.InCall {
		t.Error("expected inCall=false")
	}

	if status.Online {
		t.Error("expected online=false (no device)")
	}

	if status.Device != "" {
		t.Errorf("expected empty device, got %s", status.Device)
	}

	if status.Pan != 0 {
		t.Errorf("expected pan=0, got %d", status.Pan)
	}

	if status.Tilt != 0 {
		t.Errorf("expected tilt=0, got %d", status.Tilt)
	}

	if status.Zoom != 0 {
		t.Errorf("expected zoom=0, got %d", status.Zoom)
	}
}

func TestWeb_WebStatusOnlineWithDevice(t *testing.T) {
	daemon := newDaemonWithDevice(t)
	daemon.state.Camera = StateTracking
	daemon.state.Audio = AudioLive
	daemon.state.Gesture = true
	daemon.state.InCall = true

	webSrv := &webServer{daemon: daemon}
	status := webSrv.getWebStatus()

	if !status.Online {
		t.Error("expected online=true")
	}

	if status.Device != "/dev/video0" {
		t.Errorf("expected device=/dev/video0, got %s", status.Device)
	}

	if status.Camera != "tracking" {
		t.Errorf("expected camera=tracking, got %s", status.Camera)
	}

	if status.Audio != "live" {
		t.Errorf("expected audio=live, got %s", status.Audio)
	}

	if !status.Gesture {
		t.Error("expected gesture=true")
	}

	if !status.InCall {
		t.Error("expected inCall=true")
	}
}

func TestWeb_WebStatusAllCameraStates(t *testing.T) {
	tests := []struct {
		camera CameraState
	}{
		{StateTracking},
		{StatePrivacy},
		{StateIdle},
		{StateOffline},
	}

	for _, tc := range tests {
		t.Run(string(tc.camera), func(t *testing.T) {
			daemon := newIntegrationDaemon(t)
			daemon.videoDev = "/dev/video0"
			daemon.state.Camera = tc.camera

			webSrv := &webServer{daemon: daemon}
			status := webSrv.getWebStatus()

			if status.Camera != string(tc.camera) {
				t.Errorf("expected camera=%s, got %s", tc.camera, status.Camera)
			}
		})
	}
}

func TestWeb_WebStatusAllAudioModes(t *testing.T) {
	tests := []struct {
		audio AudioMode
	}{
		{AudioNC},
		{AudioLive},
		{AudioOriginal},
	}

	for _, tc := range tests {
		t.Run(string(tc.audio), func(t *testing.T) {
			daemon := newIntegrationDaemon(t)
			daemon.state.Audio = tc.audio

			webSrv := &webServer{daemon: daemon}
			status := webSrv.getWebStatus()

			if status.Audio != string(tc.audio) {
				t.Errorf("expected audio=%s, got %s", tc.audio, status.Audio)
			}
		})
	}
}

// ---------- parseWebStatus ----------

func TestWeb_ParseWebStatusFull(t *testing.T) {
	raw := "camera=tracking audio=live gesture=true pan=5 tilt=-3 zoom=200 in_call=yes auto=on device=/dev/video0"

	status := parseWebStatus(raw)

	if status.Camera != "tracking" {
		t.Errorf("expected camera=tracking, got %s", status.Camera)
	}

	if !status.Online {
		t.Error("expected online=true for camera=tracking")
	}

	if status.Audio != "live" {
		t.Errorf("expected audio=live, got %s", status.Audio)
	}

	if !status.Gesture {
		t.Error("expected gesture=true")
	}

	if status.Pan != 5 {
		t.Errorf("expected pan=5, got %d", status.Pan)
	}

	if status.Tilt != -3 {
		t.Errorf("expected tilt=-3, got %d", status.Tilt)
	}

	if status.Zoom != 200 {
		t.Errorf("expected zoom=200, got %d", status.Zoom)
	}

	if !status.InCall {
		t.Error("expected inCall=true")
	}

	if !status.Auto {
		t.Error("expected auto=true")
	}

	if status.Device != "/dev/video0" {
		t.Errorf("expected device=/dev/video0, got %s", status.Device)
	}

	if status.Error != "" {
		t.Errorf("expected no error, got %s", status.Error)
	}
}

func TestWeb_ParseWebStatusOffline(t *testing.T) {
	raw := "camera=offline (device not found)"

	status := parseWebStatus(raw)

	if status.Camera != "offline" {
		t.Errorf("expected camera=offline, got %s", status.Camera)
	}

	if status.Online {
		t.Error("expected online=false for offline camera")
	}
}

func TestWeb_ParseWebStatusError(t *testing.T) {
	raw := "error: PIXY not connected"

	status := parseWebStatus(raw)

	if status.Error == "" {
		t.Error("expected error to be set")
	}

	if status.Camera != "offline" {
		t.Errorf("expected camera=offline on error, got %s", status.Camera)
	}

	if status.Audio != "nc" {
		t.Errorf("expected default audio=nc on error, got %s", status.Audio)
	}

	if status.Zoom != 100 {
		t.Errorf("expected default zoom=100 on error, got %d", status.Zoom)
	}
}

func TestWeb_ParseWebStatusEmpty(t *testing.T) {
	status := parseWebStatus("")

	if status.Camera != "offline" {
		t.Errorf("expected camera=offline for empty input, got %s", status.Camera)
	}

	if status.Online {
		t.Error("expected online=false for empty input")
	}
}

func TestWeb_ParseWebStatusGarbage(t *testing.T) {
	status := parseWebStatus("blah blah notkeyvalue garbage")

	if status.Camera != "offline" {
		t.Errorf("expected camera=offline for garbage, got %s", status.Camera)
	}

	if status.Error != "" {
		t.Errorf("expected no error for garbage (no 'error:' prefix), got %s", status.Error)
	}
}

func TestWeb_ParseWebStatusGestureFalse(t *testing.T) {
	raw := "camera=privacy audio=nc gesture=false pan=0 tilt=0 zoom=100 in_call=no auto=on device=/dev/video0"

	status := parseWebStatus(raw)

	if status.Gesture {
		t.Error("expected gesture=false")
	}
}

func TestWeb_ParseWebStatusAutoOff(t *testing.T) {
	raw := "camera=privacy audio=nc gesture=false pan=0 tilt=0 zoom=100 in_call=no auto=off device=/dev/video0"

	status := parseWebStatus(raw)

	if status.Auto {
		t.Error("expected auto=false")
	}
}

func TestWeb_ParseWebStatusInCallNo(t *testing.T) {
	raw := "camera=tracking audio=nc gesture=false pan=0 tilt=0 zoom=100 in_call=no auto=on device=/dev/video0"

	status := parseWebStatus(raw)

	if status.InCall {
		t.Error("expected inCall=false for in_call=no")
	}
}

func TestWeb_ParseWebStatusDefaults(t *testing.T) {
	status := parseWebStatus("camera=tracking")

	if status.Zoom != 100 {
		t.Errorf("expected default zoom=100, got %d", status.Zoom)
	}

	if status.Audio != "nc" {
		t.Errorf("expected default audio=nc, got %s", status.Audio)
	}

	if status.Pan != 0 {
		t.Errorf("expected default pan=0, got %d", status.Pan)
	}

	if status.Tilt != 0 {
		t.Errorf("expected default tilt=0, got %d", status.Tilt)
	}
}

// ---------- Daemon unix socket integration ----------

func startSocketDaemon(t *testing.T) (*Daemon, Config) {
	t.Helper()

	cfg := Config{
		StateDir:      t.TempDir(),
		PollInterval:  2 * time.Second,
		DebounceCount: 3,
		WebAddr:       "",
	}

	daemon := NewDaemon(cfg)

	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		_ = daemon.listenUnix(ctx)
	}()

	time.Sleep(50 * time.Millisecond)

	return daemon, cfg
}

func TestSocket_StatusCommand(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "status")
	if err != nil {
		t.Fatalf("status: %v", err)
	}

	if !strings.Contains(resp, "camera=") {
		t.Errorf("expected camera= in status, got: %s", resp)
	}

	if !strings.Contains(resp, "audio=") {
		t.Errorf("expected audio= in status, got: %s", resp)
	}

	if !strings.Contains(resp, "auto=") {
		t.Errorf("expected auto= in status, got: %s", resp)
	}

	if !strings.Contains(resp, "device=") {
		t.Errorf("expected device= in status, got: %s", resp)
	}
}

func TestSocket_AutoToggleRoundTrip(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "auto-off")
	if err != nil {
		t.Fatalf("auto-off: %v", err)
	}

	if resp != "auto mode off" {
		t.Errorf("expected 'auto mode off', got: %s", resp)
	}

	resp2, err := pixy.SendCommand(cfg.SocketPath(), "auto-on")
	if err != nil {
		t.Fatalf("auto-on: %v", err)
	}

	if resp2 != "auto mode on" {
		t.Errorf("expected 'auto mode on', got: %s", resp2)
	}
}

func TestSocket_ProbeCommand(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "probe")
	if err != nil {
		t.Fatalf("probe: %v", err)
	}

	if daemon.videoDev != "" {
		if !strings.HasPrefix(resp, "device found:") {
			t.Errorf("expected 'device found: ...', got: %s", resp)
		}
	} else {
		if resp != "device not found" {
			t.Errorf("expected 'device not found', got: %s", resp)
		}
	}
}

func TestSocket_WaybarCommand(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "waybar")
	if err != nil {
		t.Fatalf("waybar: %v", err)
	}

	if !strings.Contains(resp, `"text"`) {
		t.Errorf("expected waybar JSON with 'text', got: %s", resp)
	}

	if !strings.Contains(resp, `"tooltip"`) {
		t.Errorf("expected waybar JSON with 'tooltip', got: %s", resp)
	}

	if !strings.Contains(resp, `"class"`) {
		t.Errorf("expected waybar JSON with 'class', got: %s", resp)
	}
}

func TestSocket_DeviceCommand(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "device")
	if err != nil {
		t.Fatalf("device: %v", err)
	}

	if daemon.videoDev != "" {
		if resp != daemon.videoDev {
			t.Errorf("expected %s, got: %s", daemon.videoDev, resp)
		}
	} else {
		if resp != "device not found" {
			t.Errorf("expected 'device not found', got: %s", resp)
		}
	}
}

func TestSocket_UnknownCommand(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "foobar")
	if err != nil {
		t.Fatalf("foobar: %v", err)
	}

	if !strings.HasPrefix(resp, "unknown command:") {
		t.Errorf("expected 'unknown command: ...', got: %s", resp)
	}
}

func TestSocket_EmptyCommandReturnsStatus(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "")
	if err != nil {
		t.Fatalf("empty command: %v", err)
	}

	if !strings.Contains(resp, "camera=") {
		t.Errorf("expected status from empty command, got: %s", resp)
	}
}

func TestSocket_TrackNoDevice(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	if daemon.videoDev != "" {
		t.Skip("device connected, track would succeed")
	}

	resp, err := pixy.SendCommand(cfg.SocketPath(), "track")
	if err != nil {
		t.Fatalf("track: %v", err)
	}

	if !strings.HasPrefix(resp, "error:") {
		t.Errorf("expected error without device, got: %s", resp)
	}
}

func TestSocket_PrivacyNoDevice(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	if daemon.videoDev != "" {
		t.Skip("device connected, privacy would succeed")
	}

	resp, err := pixy.SendCommand(cfg.SocketPath(), "privacy")
	if err != nil {
		t.Fatalf("privacy: %v", err)
	}

	if !strings.HasPrefix(resp, "error:") {
		t.Errorf("expected error without device, got: %s", resp)
	}
}

func TestSocket_AudioInvalidMode(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "audio badmode")
	if err != nil {
		t.Fatalf("audio badmode: %v", err)
	}

	if resp != "usage: audio [nc|live|org]" {
		t.Errorf("expected usage message, got: %s", resp)
	}
}

func TestSocket_AudioValidModes(t *testing.T) {
	for _, mode := range []string{"nc", "live", "org"} {
		t.Run(mode, func(t *testing.T) {
			_, cfg := startSocketDaemon(t)

			resp, err := pixy.SendCommand(cfg.SocketPath(), "audio "+mode)
			if err != nil {
				t.Fatalf("audio %s: %v", mode, err)
			}

			expected := "audio: " + mode
			if !strings.HasPrefix(resp, expected) {
				t.Errorf("expected %q, got: %s", expected, resp)
			}
		})
	}
}

func TestSocket_AudioCycleNoDevice(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	if daemon.videoDev != "" {
		t.Skip("device connected")
	}

	resp, err := pixy.SendCommand(cfg.SocketPath(), "audio")
	if err != nil {
		t.Fatalf("audio (cycle): %v", err)
	}

	if !strings.HasPrefix(resp, "error:") {
		t.Errorf("expected error cycling audio without device, got: %s", resp)
	}
}

func TestSocket_GestureNoDevice(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	if daemon.videoDev != "" {
		t.Skip("device connected")
	}

	resp, err := pixy.SendCommand(cfg.SocketPath(), "gesture-on")
	if err != nil {
		t.Fatalf("gesture-on: %v", err)
	}

	if !strings.HasPrefix(resp, "error:") {
		t.Errorf("expected error for gesture-on without device, got: %s", resp)
	}
}

func TestSocket_SyncNoDevice(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	if daemon.videoDev != "" {
		t.Skip("device connected")
	}

	resp, err := pixy.SendCommand(cfg.SocketPath(), "sync")
	if err != nil {
		t.Fatalf("sync: %v", err)
	}

	if !strings.HasPrefix(resp, "error:") {
		t.Errorf("expected error for sync without device, got: %s", resp)
	}
}

func TestSocket_CenterNoDevice(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	if daemon.videoDev != "" {
		t.Skip("device connected")
	}

	resp, err := pixy.SendCommand(cfg.SocketPath(), "center")
	if err != nil {
		t.Fatalf("center: %v", err)
	}

	if !strings.HasPrefix(resp, "error:") {
		t.Errorf("expected error for center without device, got: %s", resp)
	}
}

func TestSocket_PanTiltZoomNoDevice(t *testing.T) {
	daemon, cfg := startSocketDaemon(t)

	if daemon.videoDev != "" {
		t.Skip("device connected")
	}

	for _, cmd := range []string{"pan 10", "tilt -5", "zoom 200"} {
		resp, err := pixy.SendCommand(cfg.SocketPath(), cmd)
		if err != nil {
			t.Fatalf("%s: %v", cmd, err)
		}

		if !strings.HasPrefix(resp, "error:") {
			t.Errorf("expected error for '%s' without device, got: %s", cmd, resp)
		}
	}
}

func TestSocket_PanTiltZoomMissingValue(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	for _, cmd := range []string{"pan", "tilt", "zoom"} {
		resp, err := pixy.SendCommand(cfg.SocketPath(), cmd)
		if err != nil {
			t.Fatalf("%s: %v", cmd, err)
		}

		if !strings.HasPrefix(resp, "usage:") {
			t.Errorf("expected usage for '%s' without value, got: %s", cmd, resp)
		}
	}
}

func TestSocket_PanTiltZoomInvalidValue(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	for _, cmd := range []string{"pan abc", "tilt !", "zoom x"} {
		resp, err := pixy.SendCommand(cfg.SocketPath(), cmd)
		if err != nil {
			t.Fatalf("%s: %v", cmd, err)
		}

		if !strings.HasPrefix(resp, "error:") {
			t.Errorf("expected error for '%s' with invalid value, got: %s", cmd, resp)
		}
	}
}

func TestSocket_TogglePrivacy(t *testing.T) {
	_, cfg := startSocketDaemon(t)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "toggle-privacy")
	if err != nil {
		t.Fatalf("toggle-privacy: %v", err)
	}

	if !strings.Contains(resp, "privacy") && !strings.Contains(resp, "tracking") {
		t.Errorf("expected privacy/tracking response, got: %s", resp)
	}
}
