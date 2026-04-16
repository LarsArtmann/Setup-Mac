package main

import (
	"context"
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

func newTestWebServer(t *testing.T, daemon *Daemon) (*webServer, *httptest.Server) {
	t.Helper()

	webSrv := &webServer{daemon: daemon}
	mux := newWebMux(webSrv)
	server := httptest.NewServer(mux)
	t.Cleanup(server.Close)

	return webSrv, server
}

func TestWeb_IndexReturnsHTML(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Get(server.URL + "/")
	if err != nil {
		t.Fatalf("GET /: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	ct := resp.Header.Get("Content-Type")
	if !strings.Contains(ct, "text/html") {
		t.Errorf("expected text/html content-type, got %s", ct)
	}
}

func TestWeb_StatusPanelReturnsHTML(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Get(server.URL + "/panel")
	if err != nil {
		t.Fatalf("GET /panel: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_AutoToggleEndpoint(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Post(server.URL+"/api/auto", "", nil)
	if err != nil {
		t.Fatalf("POST /api/auto: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	daemon.mu.Lock()
	isAuto := daemon.state.AutoMode
	daemon.mu.Unlock()

	if isAuto {
		t.Error("expected auto mode to be toggled off")
	}

	resp2, err := http.Post(server.URL+"/api/auto", "", nil)
	if err != nil {
		t.Fatalf("POST /api/auto (second): %v", err)
	}

	defer resp2.Body.Close()

	daemon.mu.Lock()
	isAuto2 := daemon.state.AutoMode
	daemon.mu.Unlock()

	if !isAuto2 {
		t.Error("expected auto mode to be toggled back on")
	}
}

func TestWeb_GestureToggleEndpoint(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Post(server.URL+"/api/gesture", "", nil)
	if err != nil {
		t.Fatalf("POST /api/gesture: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_ProbeEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Post(server.URL+"/api/probe", "", nil)
	if err != nil {
		t.Fatalf("POST /api/probe: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_SyncEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Post(server.URL+"/api/sync", "", nil)
	if err != nil {
		t.Fatalf("POST /api/sync: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_AudioEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Post(server.URL+"/api/audio", "application/x-www-form-urlencoded", strings.NewReader("mode=nc"))
	if err != nil {
		t.Fatalf("POST /api/audio: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_TrackEndpointNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Post(server.URL+"/api/track", "", nil)
	if err != nil {
		t.Fatalf("POST /api/track: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestWeb_SnapshotNoDevice(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	_, server := newTestWebServer(t, daemon)

	resp, err := http.Get(server.URL + "/api/snapshot")
	if err != nil {
		t.Fatalf("GET /api/snapshot: %v", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusServiceUnavailable {
		t.Errorf("expected 503, got %d", resp.StatusCode)
	}
}

func TestWeb_WebStatusReflectsDaemonState(t *testing.T) {
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

	if status.Online {
		t.Error("expected online=false (no device)")
	}

	if status.Device != "" {
		t.Errorf("expected empty device, got %s", status.Device)
	}
}

func TestWeb_WebStatusReflectsDeviceOnline(t *testing.T) {
	daemon := newIntegrationDaemon(t)
	daemon.videoDev = "/dev/video0"

	webSrv := &webServer{daemon: daemon}

	status := webSrv.getWebStatus()

	if !status.Online {
		t.Error("expected online=true when videoDev is set")
	}

	if status.Device != "/dev/video0" {
		t.Errorf("expected device=/dev/video0, got %s", status.Device)
	}
}

func TestWeb_ParseWebStatus(t *testing.T) {
	raw := "camera=privacy audio=nc gesture=false pan=0 tilt=0 zoom=100 in_call=no auto=on device=/dev/video0"

	status := parseWebStatus(raw)

	if status.Camera != "privacy" {
		t.Errorf("expected camera=privacy, got %s", status.Camera)
	}

	if !status.Online {
		t.Error("expected online=true")
	}

	if status.Device != "/dev/video0" {
		t.Errorf("expected device=/dev/video0, got %s", status.Device)
	}

	if status.Zoom != 100 {
		t.Errorf("expected zoom=100, got %d", status.Zoom)
	}

	if !status.Auto {
		t.Error("expected auto=true")
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
}

func TestDaemonUnixSocketIntegration(t *testing.T) {
	cfg := Config{
		StateDir:      t.TempDir(),
		PollInterval:  2 * time.Second,
		DebounceCount: 3,
		WebAddr:       "",
	}

	daemon := NewDaemon(cfg)

	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		listenErr := daemon.listenUnix(ctx)
		if listenErr != nil {
			t.Log("listenUnix ended:", listenErr)
		}
	}()

	time.Sleep(50 * time.Millisecond)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "status")
	if err != nil {
		t.Fatalf("sendCommand status: %v", err)
	}

	if resp == "" {
		t.Error("expected non-empty status response")
	}

	if !strings.Contains(resp, "camera=") {
		t.Errorf("expected camera= in status, got: %s", resp)
	}

	if !strings.Contains(resp, "audio=") {
		t.Errorf("expected audio= in status, got: %s", resp)
	}
}

func TestDaemonSocketProbeCommand(t *testing.T) {
	cfg := Config{
		StateDir:      t.TempDir(),
		PollInterval:  2 * time.Second,
		DebounceCount: 3,
		WebAddr:       "",
	}

	daemon := NewDaemon(cfg)

	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		_ = daemon.listenUnix(ctx)
	}()

	time.Sleep(50 * time.Millisecond)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "probe")
	if err != nil {
		t.Fatalf("sendCommand probe: %v", err)
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

func TestDaemonSocketAutoToggle(t *testing.T) {
	cfg := Config{
		StateDir:      t.TempDir(),
		PollInterval:  2 * time.Second,
		DebounceCount: 3,
		WebAddr:       "",
	}

	daemon := NewDaemon(cfg)

	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		_ = daemon.listenUnix(ctx)
	}()

	time.Sleep(50 * time.Millisecond)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "auto-off")
	if err != nil {
		t.Fatalf("sendCommand auto-off: %v", err)
	}

	if resp != "auto mode off" {
		t.Errorf("expected 'auto mode off', got: %s", resp)
	}

	daemon.mu.Lock()
	isAuto := daemon.state.AutoMode
	daemon.mu.Unlock()

	if isAuto {
		t.Error("expected auto mode to be false after auto-off")
	}

	resp2, err := pixy.SendCommand(cfg.SocketPath(), "auto-on")
	if err != nil {
		t.Fatalf("sendCommand auto-on: %v", err)
	}

	if resp2 != "auto mode on" {
		t.Errorf("expected 'auto mode on', got: %s", resp2)
	}
}

func TestDaemonSocketWaybar(t *testing.T) {
	cfg := Config{
		StateDir:      t.TempDir(),
		PollInterval:  2 * time.Second,
		DebounceCount: 3,
		WebAddr:       "",
	}

	daemon := NewDaemon(cfg)

	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		_ = daemon.listenUnix(ctx)
	}()

	time.Sleep(50 * time.Millisecond)

	resp, err := pixy.SendCommand(cfg.SocketPath(), "waybar")
	if err != nil {
		t.Fatalf("sendCommand waybar: %v", err)
	}

	if !strings.Contains(resp, "text") {
		t.Errorf("expected waybar JSON with 'text', got: %s", resp)
	}

	if !strings.Contains(resp, "tooltip") {
		t.Errorf("expected waybar JSON with 'tooltip', got: %s", resp)
	}
}
