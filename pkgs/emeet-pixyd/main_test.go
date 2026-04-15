package main

import (
	"encoding/json"
	"os"
	"strings"
	"testing"
)

func testConfig(dir string) Config {
	return Config{
		StateDir:      dir,
		PollInterval:  2,
		DebounceCount: 3,
	}
}

func TestStateDefaults(t *testing.T) {
	d := &Daemon{
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
	}
	if d.state.Camera != StatePrivacy {
		t.Errorf("expected default camera state to be privacy, got %s", d.state.Camera)
	}
	if d.state.Audio != AudioNC {
		t.Errorf("expected default audio to be nc, got %s", d.state.Audio)
	}
	if d.state.AutoMode != true {
		t.Error("expected auto mode to be on by default")
	}
	if d.state.InCall != false {
		t.Error("expected in_call to be false by default")
	}
}

func TestStateSaveLoad(t *testing.T) {
	cfg := testConfig(t.TempDir())

	d := &Daemon{
		config: cfg,
		state: State{
			Camera:   StateTracking,
			Audio:    AudioLive,
			Gesture:  true,
			InCall:   true,
			AutoMode: false,
		},
	}

	if err := d.saveState(); err != nil {
		t.Fatalf("saveState: %v", err)
	}

	d2 := &Daemon{
		config: cfg,
		state:  State{},
	}
	d2.loadState()

	if d2.state.Camera != StateTracking {
		t.Errorf("expected camera=tracking, got %s", d2.state.Camera)
	}
	if d2.state.Audio != AudioLive {
		t.Errorf("expected audio=live, got %s", d2.state.Audio)
	}
	if d2.state.Gesture != true {
		t.Error("expected gesture=true")
	}
	if d2.state.InCall != true {
		t.Error("expected in_call=true")
	}
	if d2.state.AutoMode != false {
		t.Error("expected auto_mode=false")
	}
}

func TestStateFileCorrupt(t *testing.T) {
	cfg := testConfig(t.TempDir())
	if err := os.WriteFile(cfg.StateFile(), []byte("not json"), 0644); err != nil {
		t.Fatalf("write corrupt file: %v", err)
	}

	d := &Daemon{
		config: cfg,
		state:  State{Camera: StatePrivacy},
	}
	d.loadState()

	if d.state.Camera != StatePrivacy {
		t.Errorf("expected state to remain unchanged on corrupt file, got %s", d.state.Camera)
	}
}

func TestStateFileMissing(t *testing.T) {
	cfg := testConfig("/nonexistent")
	d := &Daemon{
		config: cfg,
		state:  State{Camera: StatePrivacy, Audio: AudioNC},
	}
	d.loadState()

	if d.state.Camera != StatePrivacy {
		t.Errorf("expected state to remain unchanged on missing file, got %s", d.state.Camera)
	}
}

func TestHandleCommandStatus(t *testing.T) {
	d := &Daemon{
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			AutoMode: true,
		},
		videoDev: "",
	}
	result := d.handleCommand("status")
	if result != "camera=offline (device not found)" {
		t.Errorf("expected offline status when no device, got: %s", result)
	}
}

func TestHandleCommandUnknown(t *testing.T) {
	d := &Daemon{
		state:     State{Camera: StatePrivacy},
		videoDev:  "/dev/video0",
		hidrawDev: "/dev/hidraw0",
	}
	result := d.handleCommand("foobar")
	if result != "unknown command: foobar" {
		t.Errorf("expected unknown command response, got: %s", result)
	}
}

func TestHandleCommandAutoToggle(t *testing.T) {
	d := &Daemon{
		config: testConfig(t.TempDir()),
		state: State{
			Camera:   StatePrivacy,
			AutoMode: true,
		},
		videoDev:  "/dev/video0",
		hidrawDev: "/dev/hidraw0",
	}

	result := d.handleCommand("auto-off")
	if result != "auto mode off" {
		t.Errorf("expected 'auto mode off', got: %s", result)
	}
	if d.state.AutoMode != false {
		t.Error("expected auto mode to be false")
	}

	result = d.handleCommand("auto-on")
	if result != "auto mode on" {
		t.Errorf("expected 'auto mode on', got: %s", result)
	}
	if d.state.AutoMode != true {
		t.Error("expected auto mode to be true")
	}
}

func TestHandleCommandAudioInvalid(t *testing.T) {
	d := &Daemon{
		state:     State{Camera: StatePrivacy, Audio: AudioNC},
		videoDev:  "/dev/video0",
		hidrawDev: "/dev/hidraw0",
	}

	result := d.handleCommand("audio xyz")
	if result != "usage: audio [nc|live|org]" {
		t.Errorf("expected usage for invalid mode, got: %s", result)
	}
}

func TestHandleCommandDeviceRequired(t *testing.T) {
	d := &Daemon{
		state:     State{Camera: StateOffline},
		videoDev:  "",
		hidrawDev: "",
	}

	for _, cmd := range []string{"track", "idle", "privacy", "toggle-privacy", "center", "gesture-on", "gesture-off"} {
		result := d.handleCommand(cmd)
		if result == "" {
			t.Errorf("expected error response for '%s' with no device", cmd)
		}
		if len(result) < 6 || result[:6] != "error:" {
			t.Errorf("expected error: prefix for '%s' with no device, got: %s", cmd, result)
		}
	}
}

func TestWaybarOutput(t *testing.T) {
	tests := []struct {
		camera   CameraState
		inCall   bool
		expected string
	}{
		{StateTracking, false, "tracking"},
		{StatePrivacy, false, "privacy"},
		{StateIdle, false, "idle"},
		{StateOffline, false, "offline"},
		{StateTracking, true, "tracking in-call"},
	}

	for _, tt := range tests {
		d := &Daemon{
			state: State{
				Camera:   tt.camera,
				Audio:    AudioNC,
				AutoMode: true,
				InCall:   tt.inCall,
			},
		}
		output := d.waybarOutput()

		var parsed map[string]string
		if err := json.Unmarshal([]byte(output), &parsed); err != nil {
			t.Fatalf("waybar output is not valid JSON: %s, err: %v", output, err)
		}

		if parsed["class"] != "custom-camera "+tt.expected {
			t.Errorf("expected class 'custom-camera %s', got '%s'", tt.expected, parsed["class"])
		}

		if _, ok := parsed["text"]; !ok {
			t.Error("waybar output missing 'text' field")
		}
		if _, ok := parsed["tooltip"]; !ok {
			t.Error("waybar output missing 'tooltip' field")
		}
	}
}

func TestIsCameraInUseEmptyDevice(t *testing.T) {
	if isCameraInUse("") {
		t.Error("expected false for empty video device")
	}
}

func TestHandleCommandTogglePrivacy(t *testing.T) {
	d := &Daemon{
		state:     State{Camera: StatePrivacy},
		videoDev:  "/dev/video0",
		hidrawDev: "/dev/hidraw0",
	}

	result := d.handleCommand("toggle-privacy")
	if result == "" {
		t.Error("expected non-empty response")
	}
}

func TestHandleCommandProbe(t *testing.T) {
	d := &Daemon{
		state:     State{Camera: StateOffline},
		videoDev:  "",
		hidrawDev: "",
	}
	result := d.handleCommand("probe")
	if result != "device not found" {
		t.Errorf("expected 'device not found' when no PIXY connected, got: %s", result)
	}
}

func TestAudioModeNext(t *testing.T) {
	tests := []struct {
		input    AudioMode
		expected AudioMode
	}{
		{AudioNC, AudioLive},
		{AudioLive, AudioOriginal},
		{AudioOriginal, AudioNC},
		{AudioMode("unknown"), AudioNC},
	}
	for _, tt := range tests {
		result := tt.input.Next()
		if result != tt.expected {
			t.Errorf("AudioMode(%s).Next() = %s, want %s", tt.input, result, tt.expected)
		}
	}
}

func TestAudioModeHIDByte(t *testing.T) {
	tests := []struct {
		mode     AudioMode
		expected byte
	}{
		{AudioNC, 0x01},
		{AudioLive, 0x02},
		{AudioOriginal, 0x03},
		{AudioMode("unknown"), 0x01},
	}
	for _, tt := range tests {
		result := tt.mode.HIDByte()
		if result != tt.expected {
			t.Errorf("AudioMode(%s).HIDByte() = 0x%02x, want 0x%02x", tt.mode, result, tt.expected)
		}
	}
}

func TestCameraStateHIDByte(t *testing.T) {
	tests := []struct {
		state    CameraState
		expected byte
	}{
		{StateTracking, 0x01},
		{StatePrivacy, 0x02},
		{StateIdle, 0x00},
		{CameraState("unknown"), 0x00},
	}
	for _, tt := range tests {
		result := tt.state.HIDByte()
		if result != tt.expected {
			t.Errorf("CameraState(%s).HIDByte() = 0x%02x, want 0x%02x", tt.state, result, tt.expected)
		}
	}
}

func TestTypeValidation(t *testing.T) {
	if !AudioNC.Valid() {
		t.Error("AudioNC should be valid")
	}
	if !StateTracking.Valid() {
		t.Error("StateTracking should be valid")
	}
	if AudioMode("foo").Valid() {
		t.Error("unknown audio mode should not be valid")
	}
	if CameraState("bar").Valid() {
		t.Error("unknown camera state should not be valid")
	}
}

func TestHandleCommandAudioCycleNoDevice(t *testing.T) {
	d := &Daemon{
		state:     State{Camera: StatePrivacy, Audio: AudioNC},
		videoDev:  "",
		hidrawDev: "",
	}
	result := d.handleCommand("audio")
	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error when cycling audio with no device, got: %s", result)
	}
}

func TestConfigPaths(t *testing.T) {
	cfg := Config{StateDir: "/tmp/test-pixyd"}
	if cfg.StateFile() != "/tmp/test-pixyd/state.json" {
		t.Errorf("unexpected StateFile: %s", cfg.StateFile())
	}
	if cfg.SocketPath() != "/tmp/test-pixyd/control.sock" {
		t.Errorf("unexpected SocketPath: %s", cfg.SocketPath())
	}
}

func TestDefaultConfig(t *testing.T) {
	cfg := DefaultConfig()
	if cfg.StateDir != defaultStateDir {
		t.Errorf("expected StateDir=%s, got %s", defaultStateDir, cfg.StateDir)
	}
	if cfg.PollInterval != defaultPollInterval {
		t.Errorf("expected PollInterval=%v, got %v", defaultPollInterval, cfg.PollInterval)
	}
	if cfg.DebounceCount != defaultDebounceCount {
		t.Errorf("expected DebounceCount=%d, got %d", defaultDebounceCount, cfg.DebounceCount)
	}
}
