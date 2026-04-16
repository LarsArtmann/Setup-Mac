package main

import (
	"context"
	"encoding/json"
	"net"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/larsartmann/systemnix/emeet-pixyd/internal/pixy"
)

func testConfig(dir string) Config {
	return Config{
		StateDir:      dir,
		PollInterval:  2,
		DebounceCount: 3,
	}
}

func newTestDaemon(camera CameraState, videoDev, hidrawDev string) *Daemon {
	return &Daemon{
		mu: sync.Mutex{},
		state: State{
			Camera:   camera,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		config:        Config{StateDir: "/tmp", PollInterval: 2 * time.Second, DebounceCount: 3},
		videoDev:      videoDev,
		hidrawDev:     hidrawDev,
		debounceInUse: 0,
		debounceIdle:  0,
	}
}

func newTestDaemonWithAudio(
	camera CameraState,
	audio AudioMode,
	videoDev, hidrawDev string,
) *Daemon {
	return &Daemon{
		mu: sync.Mutex{},
		state: State{
			Camera:   camera,
			Audio:    audio,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		config:        Config{StateDir: "/tmp", PollInterval: 2 * time.Second, DebounceCount: 3},
		videoDev:      videoDev,
		hidrawDev:     hidrawDev,
		debounceInUse: 0,
		debounceIdle:  0,
	}
}

func assertCameraState(t *testing.T, d *Daemon, expected CameraState) {
	t.Helper()

	if d.state.Camera != expected {
		t.Errorf("expected camera state %s, got %s", expected, d.state.Camera)
	}
}

func assertErrorPrefix(t *testing.T, result string) {
	t.Helper()

	if !strings.HasPrefix(result, "error:") {
		t.Errorf("expected error prefix, got: %s", result)
	}
}

func assertAutoMode(t *testing.T, d *Daemon, expected bool) {
	t.Helper()

	if d.state.AutoMode != expected {
		t.Errorf("expected auto mode=%v, got %v", expected, d.state.AutoMode)
	}
}

func assertGesture(t *testing.T, resp hidResponse, expected bool) {
	t.Helper()

	if !resp.Got || resp.Gesture != expected {
		t.Errorf("expected gesture=%v, got Got=%v Gesture=%v", expected, resp.Got, resp.Gesture)
	}
}

func assertParsedField(t *testing.T, parsed map[string]string, field string) {
	t.Helper()

	if _, ok := parsed[field]; !ok {
		t.Errorf("waybar output missing '%s' field", field)
	}
}

func TestStateDefaults(t *testing.T) {
	t.Parallel()

	d := &Daemon{
		mu:            sync.Mutex{},
		state:         DefaultState(),
		config:        Config{StateDir: "/tmp", PollInterval: 2 * time.Second, DebounceCount: 3},
		videoDev:      "",
		hidrawDev:     "",
		debounceInUse: 0,
		debounceIdle:  0,
	}
	assertCameraState(t, d, StatePrivacy)

	if d.state.Audio != AudioNC {
		t.Errorf("expected default audio to be nc, got %s", d.state.Audio)
	}

	assertAutoMode(t, d, true)

	if d.state.InCall != false {
		t.Error("expected in_call to be false by default")
	}
}

func TestStateSaveLoad(t *testing.T) {
	t.Parallel()

	cfg := testConfig(t.TempDir())

	d := &Daemon{
		mu:     sync.Mutex{},
		config: cfg,
		state: State{
			Camera:   StateTracking,
			Audio:    AudioLive,
			Gesture:  true,
			InCall:   true,
			AutoMode: false,
		},
		videoDev:      "",
		hidrawDev:     "",
		debounceInUse: 0,
		debounceIdle:  0,
	}

	saveErr := d.saveState()
	if saveErr != nil {
		t.Fatalf("saveState: %v", saveErr)
	}

	d2 := &Daemon{
		mu:     sync.Mutex{},
		config: cfg,
		state: State{
			Camera:   StateIdle,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		videoDev:      "",
		hidrawDev:     "",
		debounceInUse: 0,
		debounceIdle:  0,
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
	t.Parallel()

	cfg := testConfig(t.TempDir())

	err := os.WriteFile(cfg.StateFile(), []byte("not json"), pixy.PermissionStateFile)
	if err != nil {
		t.Fatalf("write corrupt file: %v", err)
	}

	d := &Daemon{
		mu:     sync.Mutex{},
		config: cfg,
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		videoDev:      "",
		hidrawDev:     "",
		debounceInUse: 0,
		debounceIdle:  0,
	}
	d.loadState()

	if d.state.Camera != StatePrivacy {
		t.Errorf("expected state to remain unchanged on corrupt file, got %s", d.state.Camera)
	}
}

func TestStateFileMissing(t *testing.T) {
	t.Parallel()

	cfg := testConfig("/nonexistent")
	d := &Daemon{
		mu:     sync.Mutex{},
		config: cfg,
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		videoDev:      "",
		hidrawDev:     "",
		debounceInUse: 0,
		debounceIdle:  0,
	}
	d.loadState()

	assertCameraState(t, d, StatePrivacy)
}

func TestHandleCommandStatus(t *testing.T) {
	t.Parallel()

	d := &Daemon{
		mu:     sync.Mutex{},
		config: Config{StateDir: "/tmp", PollInterval: 2 * time.Second, DebounceCount: 3},
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		videoDev:      "",
		hidrawDev:     "",
		debounceInUse: 0,
		debounceIdle:  0,
	}

	result := d.handleCommand(context.Background(), "status")
	if result != "camera=offline (device not found)" {
		t.Errorf("expected offline status when no device, got: %s", result)
	}
}

func TestHandleCommandUnknown(t *testing.T) {
	t.Parallel()

	d := newTestDaemon(StatePrivacy, "/dev/video0", "/dev/hidraw0")

	result := d.handleCommand(context.Background(), "foobar")
	if result != "unknown command: foobar" {
		t.Errorf("expected unknown command response, got: %s", result)
	}
}

func TestHandleCommandAutoToggle(t *testing.T) {
	t.Parallel()

	d := &Daemon{
		mu:     sync.Mutex{},
		config: testConfig(t.TempDir()),
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		videoDev:      "/dev/video0",
		hidrawDev:     "/dev/hidraw0",
		debounceInUse: 0,
		debounceIdle:  0,
	}

	result := d.handleCommand(context.Background(), "auto-off")
	if result != "auto mode off" {
		t.Errorf("expected 'auto mode off', got: %s", result)
	}

	if d.state.AutoMode != false {
		t.Error("expected auto mode to be false")
	}

	result = d.handleCommand(context.Background(), "auto-on")
	if result != "auto mode on" {
		t.Errorf("expected 'auto mode on', got: %s", result)
	}

	assertAutoMode(t, d, true)
}

func TestHandleCommandAudioInvalid(t *testing.T) {
	t.Parallel()

	d := newTestDaemonWithAudio(StatePrivacy, AudioNC, "/dev/video0", "/dev/hidraw0")

	result := d.handleCommand(context.Background(), "audio xyz")
	if result != "usage: audio [nc|live|org]" {
		t.Errorf("expected usage for invalid mode, got: %s", result)
	}
}

func TestHandleCommandDeviceRequired(t *testing.T) {
	t.Parallel()

	d := newTestDaemon(StateOffline, "", "")

	for _, cmd := range []string{"track", "idle", "privacy", "toggle-privacy", "center", "gesture-on", "gesture-off"} {
		result := d.handleCommand(context.Background(), cmd)
		if result == "" {
			t.Errorf("expected error response for '%s' with no device", cmd)
		}

		if len(result) < 6 || result[:6] != "error:" {
			t.Errorf("expected error: prefix for '%s' with no device, got: %s", cmd, result)
		}
	}
}

func TestWaybarOutput(t *testing.T) {
	t.Parallel()

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

	for _, testCase := range tests {
		d := &Daemon{
			mu:     sync.Mutex{},
			config: Config{StateDir: "/tmp", PollInterval: 2 * time.Second, DebounceCount: 3},
			state: State{
				Camera:   testCase.camera,
				Audio:    AudioNC,
				Gesture:  false,
				InCall:   testCase.inCall,
				AutoMode: true,
			},
			videoDev:      "",
			hidrawDev:     "",
			debounceInUse: 0,
			debounceIdle:  0,
		}
		output := d.waybarOutput()

		var parsed map[string]string

		err := json.Unmarshal([]byte(output), &parsed)
		if err != nil {
			t.Fatalf("waybar output is not valid JSON: %s, err: %v", output, err)
		}

		if parsed["class"] != "custom-camera "+testCase.expected {
			t.Errorf(
				"expected class 'custom-camera %s', got '%s'",
				testCase.expected,
				parsed["class"],
			)
		}

		assertParsedField(t, parsed, "text")
		assertParsedField(t, parsed, "tooltip")
	}
}

func TestIsCameraInUseEmptyDevice(t *testing.T) {
	t.Parallel()

	if isCameraInUse("") {
		t.Error("expected false for empty video device")
	}
}

func TestHandleCommandTogglePrivacy(t *testing.T) {
	t.Parallel()

	d := newTestDaemon(StatePrivacy, "/dev/video0", "/dev/hidraw0")

	result := d.handleCommand(context.Background(), "toggle-privacy")
	if result == "" {
		t.Error("expected non-empty response")
	}
}

func TestHandleCommandProbe(t *testing.T) {
	t.Parallel()

	d := newTestDaemon(StateOffline, "", "")

	result := d.handleCommand(context.Background(), "probe")

	if d.videoDev != "" {
		if !strings.HasPrefix(result, "device found:") {
			t.Errorf("expected 'device found: ...' when PIXY connected, got: %s", result)
		}
	} else {
		if result != "device not found" {
			t.Errorf("expected 'device not found' when no PIXY connected, got: %s", result)
		}
	}
}

func TestAudioModeNext(t *testing.T) {
	t.Parallel()

	tests := []struct {
		input    AudioMode
		expected AudioMode
	}{
		{AudioNC, AudioLive},
		{AudioLive, AudioOriginal},
		{AudioOriginal, AudioNC},
		{AudioMode("unknown"), AudioNC},
	}
	for _, testCase := range tests {
		result := testCase.input.Next()
		if result != testCase.expected {
			t.Errorf(
				"AudioMode(%s).Next() = %s, want %s",
				testCase.input,
				result,
				testCase.expected,
			)
		}
	}
}

func TestAudioModeHIDByte(t *testing.T) {
	t.Parallel()

	tests := []struct {
		mode     AudioMode
		expected byte
	}{
		{AudioNC, hidByteNC},
		{AudioLive, hidByteLive},
		{AudioOriginal, hidByteOriginal},
		{AudioMode("unknown"), hidByteNC},
	}
	for _, testCase := range tests {
		result := audioHIDByte(testCase.mode)
		if result != testCase.expected {
			t.Errorf(
				"audioHIDByte(%s) = 0x%02x, want 0x%02x",
				testCase.mode,
				result,
				testCase.expected,
			)
		}
	}
}

func TestCameraStateHIDByte(t *testing.T) {
	t.Parallel()

	tests := []struct {
		state    CameraState
		expected byte
	}{
		{StateTracking, hidByteTracking},
		{StatePrivacy, hidBytePrivacy},
		{StateIdle, hidByteIdle},
		{CameraState("unknown"), hidByteIdle},
	}
	for _, testCase := range tests {
		result := cameraHIDByte(testCase.state)
		if result != testCase.expected {
			t.Errorf(
				"cameraHIDByte(%s) = 0x%02x, want 0x%02x",
				testCase.state,
				result,
				testCase.expected,
			)
		}
	}
}

func TestTypeValidation(t *testing.T) {
	t.Parallel()

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
	t.Parallel()

	d := newTestDaemonWithAudio(StatePrivacy, AudioNC, "", "")

	result := d.handleCommand(context.Background(), "audio")
	assertErrorPrefix(t, result)
}

func TestConfigPaths(t *testing.T) {
	t.Parallel()

	cfg := Config{
		StateDir:      "/tmp/test-pixyd",
		PollInterval:  pixy.DefaultPollInterval,
		DebounceCount: pixy.DefaultDebounceCount,
	}
	if cfg.StateFile() != "/tmp/test-pixyd/state.json" {
		t.Errorf("unexpected StateFile: %s", cfg.StateFile())
	}

	if cfg.SocketPath() != "/tmp/test-pixyd/control.sock" {
		t.Errorf("unexpected SocketPath: %s", cfg.SocketPath())
	}
}

func TestParseHIDResponseTracking(t *testing.T) {
	t.Parallel()

	tests := []struct {
		data     []byte
		expected CameraState
	}{
		{[]byte{0x09, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01}, StateTracking},
		{[]byte{0x09, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x02}, StatePrivacy},
		{[]byte{0x09, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00}, StateIdle},
	}
	for _, testCase := range tests {
		resp := parseHIDResponse(testCase.data)
		if !resp.Got {
			t.Fatal("expected Got=true")
		}

		if resp.Tracking != testCase.expected {
			t.Errorf(
				"tracking from %x = %s, want %s",
				testCase.data,
				resp.Tracking,
				testCase.expected,
			)
		}
	}
}

func TestParseHIDResponseAudio(t *testing.T) {
	t.Parallel()

	tests := []struct {
		data     []byte
		expected AudioMode
	}{
		{[]byte{0x09, 0x05, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01}, AudioNC},
		{[]byte{0x09, 0x05, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x02}, AudioLive},
		{[]byte{0x09, 0x05, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x03}, AudioOriginal},
	}
	for _, testCase := range tests {
		resp := parseHIDResponse(testCase.data)
		if !resp.Got {
			t.Fatal("expected Got=true")
		}

		if resp.Audio != testCase.expected {
			t.Errorf("audio from %x = %s, want %s", testCase.data, resp.Audio, testCase.expected)
		}
	}
}

func TestParseHIDResponseGesture(t *testing.T) {
	t.Parallel()

	tests := []struct {
		data     []byte
		expected bool
	}{
		{[]byte{0x09, 0x04, 0x02, 0x00, 0x00, 0x01, 0x00, 0x01, 0x02, 0x01}, true},
		{[]byte{0x09, 0x04, 0x02, 0x00, 0x00, 0x01, 0x00, 0x01, 0x02, 0x00}, false},
	}
	for _, testCase := range tests {
		assertGesture(t, parseHIDResponse(testCase.data), testCase.expected)
	}
}

func TestParseHIDResponseTooShort(t *testing.T) {
	t.Parallel()

	resp := parseHIDResponse([]byte{0x09, 0x01})
	if resp.Got {
		t.Error("expected Got=false for short response")
	}
}

func TestParseHIDResponseNil(t *testing.T) {
	t.Parallel()

	resp := parseHIDResponse(nil)
	if resp.Got {
		t.Error("expected Got=false for nil response")
	}
}

func TestHandleCommandSyncNoDevice(t *testing.T) {
	t.Parallel()

	d := newTestDaemon(StateOffline, "", "")
	result := d.handleCommand(context.Background(), "sync")
	assertErrorPrefix(t, result)
}

func TestHandleCommandSyncWithDevice(t *testing.T) {
	t.Parallel()

	d := &Daemon{
		mu:     sync.Mutex{},
		config: testConfig(t.TempDir()),
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
		videoDev:      "/dev/video0",
		hidrawDev:     "/dev/hidraw0",
		debounceInUse: 0,
		debounceIdle:  0,
	}

	result := d.handleCommand(context.Background(), "sync")
	if result != "synced (no changes)" && !strings.Contains(result, "error") {
		t.Errorf("expected sync result, got: %s", result)
	}
}

func TestDefaultConfig(t *testing.T) {
	t.Parallel()

	cfg := DefaultConfig()
	if cfg.StateDir != pixy.DefaultStateDir {
		t.Errorf("expected StateDir=%s, got %s", pixy.DefaultStateDir, cfg.StateDir)
	}

	if cfg.PollInterval != pixy.DefaultPollInterval {
		t.Errorf("expected PollInterval=%v, got %v", pixy.DefaultPollInterval, cfg.PollInterval)
	}

	if cfg.DebounceCount != pixy.DefaultDebounceCount {
		t.Errorf("expected DebounceCount=%d, got %d", pixy.DefaultDebounceCount, cfg.DebounceCount)
	}
}

func TestParseAudioMode(t *testing.T) {
	t.Parallel()

	tests := []struct {
		input    string
		expected AudioMode
		wantErr  bool
	}{
		{"nc", AudioNC, false},
		{"live", AudioLive, false},
		{"org", AudioOriginal, false},
		{"unknown", "", true},
		{"", "", true},
	}
	for _, tc := range tests {
		got, err := ParseAudioMode(tc.input)
		if tc.wantErr {
			if err == nil {
				t.Errorf("ParseAudioMode(%q): expected error, got nil", tc.input)
			}
		} else {
			if err != nil {
				t.Errorf("ParseAudioMode(%q): unexpected error: %v", tc.input, err)
			}

			if got != tc.expected {
				t.Errorf("ParseAudioMode(%q) = %q, want %q", tc.input, got, tc.expected)
			}
		}
	}
}

func TestParseCameraState(t *testing.T) {
	t.Parallel()

	tests := []struct {
		input    string
		expected CameraState
		wantErr  bool
	}{
		{"idle", StateIdle, false},
		{"tracking", StateTracking, false},
		{"privacy", StatePrivacy, false},
		{"offline", StateOffline, false},
		{"unknown", "", true},
		{"", "", true},
	}
	for _, tc := range tests {
		got, err := ParseCameraState(tc.input)
		if tc.wantErr {
			if err == nil {
				t.Errorf("ParseCameraState(%q): expected error, got nil", tc.input)
			}
		} else {
			if err != nil {
				t.Errorf("ParseCameraState(%q): unexpected error: %v", tc.input, err)
			}

			if got != tc.expected {
				t.Errorf("ParseCameraState(%q) = %q, want %q", tc.input, got, tc.expected)
			}
		}
	}
}

func TestParseHIDResponseUnknownInterface(t *testing.T) {
	t.Parallel()

	data := []byte{0x09, 0x99, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x01}

	resp := parseHIDResponse(data)
	if !resp.Got {
		t.Error("expected Got=true for valid-length response with unknown interface")
	}

	if resp.Tracking != StateIdle {
		t.Errorf("expected idle tracking for unknown interface, got %s", resp.Tracking)
	}
}

func TestDefaultStateValues(t *testing.T) {
	t.Parallel()

	s := DefaultState()
	if s.Camera != StatePrivacy {
		t.Errorf("expected default camera=privacy, got %s", s.Camera)
	}

	if s.Audio != AudioNC {
		t.Errorf("expected default audio=nc, got %s", s.Audio)
	}

	if s.Gesture != false {
		t.Error("expected default gesture=false")
	}

	if s.InCall != false {
		t.Error("expected default inCall=false")
	}

	if s.AutoMode != true {
		t.Error("expected default autoMode=true")
	}
}

func TestSetDeadlineError(t *testing.T) {
	t.Parallel()

	conn := &mockConn{setDeadlineErr: errDeadline}

	err := pixy.SetDeadline(conn, time.Second)
	if err == nil {
		t.Error("expected error from SetDeadline with failing conn")
	}
}

type mockConn struct {
	setDeadlineErr error
}

func (m *mockConn) Read([]byte) (int, error)         { return 0, nil }
func (m *mockConn) Write([]byte) (int, error)        { return 0, nil }
func (m *mockConn) Close() error                     { return nil }
func (m *mockConn) LocalAddr() net.Addr              { return nil }
func (m *mockConn) RemoteAddr() net.Addr             { return nil }
func (m *mockConn) SetDeadline(time.Time) error      { return m.setDeadlineErr }
func (m *mockConn) SetReadDeadline(time.Time) error  { return nil }
func (m *mockConn) SetWriteDeadline(time.Time) error { return nil }

func writeFakeFile(t *testing.T, path, content string) {
	t.Helper()

	dir := filepath.Dir(path)

	dirErr := os.MkdirAll(dir, 0o755)
	if dirErr != nil {
		t.Fatalf("mkdir %s: %v", dir, dirErr)
	}

	writeErr := os.WriteFile(path, []byte(content), 0o644)
	if writeErr != nil {
		t.Fatalf("write %s: %v", path, writeErr)
	}
}

type fakeVideoDev struct {
	name     string
	modalias string
	index    string
}

type fakeHidrawDev struct {
	name    string
	hidID   string
	hidName string
}

func createFakeVideo4linux(t *testing.T, root string, devices []fakeVideoDev) {
	t.Helper()

	for _, dev := range devices {
		base := filepath.Join(root, dev.name)
		writeFakeFile(t, filepath.Join(base, "device/modalias"), dev.modalias)
		writeFakeFile(t, filepath.Join(base, "name"), "EMEET PIXY: EMEET PIXY")

		if dev.index != "" {
			writeFakeFile(t, filepath.Join(base, "index"), dev.index)
		}
	}
}

func createFakeHidraw(t *testing.T, root string, devices []fakeHidrawDev) {
	t.Helper()

	for _, dev := range devices {
		ueventPath := filepath.Join(root, dev.name, "device/uevent")
		content := "DRIVER=hid-generic\n"
		content += "HID_ID=" + dev.hidID + "\n"
		content += "HID_NAME=" + dev.hidName + "\n"

		writeFakeFile(t, ueventPath, content)
	}
}

func TestProbeVideo4linux_PIXYFound(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with a PIXY at index 0 and a metadata node at index 1
	root := t.TempDir()
	createFakeVideo4linux(t, root, []fakeVideoDev{
		{
			name:     "video0",
			modalias: "usb:v328Fp00C0d2004dcEFdsc02dp01ic0Eisc01ip00in00",
			index:    "0",
		},
		{
			name:     "video2",
			modalias: "usb:v328Fp00C0d2004dcEFdsc02dp01ic0Eisc01ip00in00",
			index:    "1",
		},
	})

	// When probing
	result := probeVideo4linux(root)

	// Then the primary capture device is found
	if result != "/dev/video0" {
		t.Errorf("expected /dev/video0, got %s", result)
	}
}

func TestProbeVideo4linux_PIXYOnlyCaptureNode(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with only the PIXY capture node (no metadata node)
	root := t.TempDir()
	createFakeVideo4linux(t, root, []fakeVideoDev{
		{
			name:     "video0",
			modalias: "usb:v328Fp00C0d2004dcEFdsc02dp01ic0Eisc01ip00in00",
			index:    "0",
		},
	})

	// When probing
	result := probeVideo4linux(root)

	// Then it is found
	if result != "/dev/video0" {
		t.Errorf("expected /dev/video0, got %s", result)
	}
}

func TestProbeVideo4linux_PIXYNoIndexFile(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with a PIXY but no index file (some drivers don't expose it)
	root := t.TempDir()
	createFakeVideo4linux(t, root, []fakeVideoDev{
		{
			name:     "video0",
			modalias: "usb:v328Fp00C0d2004dcEFdsc02dp01ic0Eisc01ip00in00",
			index:    "",
		},
	})

	// When probing
	result := probeVideo4linux(root)

	// Then it still matches (graceful fallback when index is absent)
	if result != "/dev/video0" {
		t.Errorf("expected /dev/video0, got %s", result)
	}
}

func TestProbeVideo4linux_NoPIXY(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with only non-PIXY devices
	root := t.TempDir()
	createFakeVideo4linux(t, root, []fakeVideoDev{
		{
			name:     "video1",
			modalias: "platform:v4l2loopback",
			index:    "0",
		},
	})

	// When probing
	result := probeVideo4linux(root)

	// Then nothing is found
	if result != "" {
		t.Errorf("expected empty, got %s", result)
	}
}

func TestProbeVideo4linux_WrongVendorProduct(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with a different USB camera
	root := t.TempDir()
	createFakeVideo4linux(t, root, []fakeVideoDev{
		{
			name:     "video0",
			modalias: "usb:v1234p5678d0100dcEFdsc02dp01ic0Eisc01ip00in00",
			index:    "0",
		},
	})

	// When probing
	result := probeVideo4linux(root)

	// Then nothing is found
	if result != "" {
		t.Errorf("expected empty, got %s", result)
	}
}

func TestProbeVideo4linux_EmptyDir(t *testing.T) {
	t.Parallel()

	// Given an empty sysfs directory
	root := t.TempDir()

	// When probing
	result := probeVideo4linux(root)

	// Then nothing is found
	if result != "" {
		t.Errorf("expected empty, got %s", result)
	}
}

func TestProbeVideo4linux_NonexistentDir(t *testing.T) {
	t.Parallel()

	// Given a nonexistent sysfs path
	result := probeVideo4linux("/nonexistent/path/video4linux")

	// Then nothing is found
	if result != "" {
		t.Errorf("expected empty, got %s", result)
	}
}

func TestProbeVideo4linux_OBSCamIgnored(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with OBS virtual cam (no device/modalias) and a PIXY
	root := t.TempDir()

	obsDir := filepath.Join(root, "video1")
	writeFakeFile(t, filepath.Join(obsDir, "name"), "OBS Cam")
	writeFakeFile(t, filepath.Join(obsDir, "index"), "0")

	createFakeVideo4linux(t, root, []fakeVideoDev{
		{
			name:     "video0",
			modalias: "usb:v328Fp00C0d2004dcEFdsc02dp01ic0Eisc01ip00in00",
			index:    "0",
		},
	})

	// When probing
	result := probeVideo4linux(root)

	// Then the PIXY is found, OBS is skipped
	if result != "/dev/video0" {
		t.Errorf("expected /dev/video0, got %s", result)
	}
}

func TestProbeVideo4linux_MetadataNodeSkipped(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree where only the metadata node (index=1) exists
	root := t.TempDir()
	createFakeVideo4linux(t, root, []fakeVideoDev{
		{
			name:     "video2",
			modalias: "usb:v328Fp00C0d2004dcEFdsc02dp01ic0Eisc01ip00in00",
			index:    "1",
		},
	})

	// When probing
	result := probeVideo4linux(root)

	// Then nothing is found (metadata node rejected)
	if result != "" {
		t.Errorf("expected empty for metadata-only node, got %s", result)
	}
}

func TestProbeHidraw_PIXYFound(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with a PIXY hidraw device
	root := t.TempDir()
	createFakeHidraw(t, root, []fakeHidrawDev{
		{
			name:    "hidraw7",
			hidID:   "0003:0000328F:000000C0",
			hidName: "EMEET PIXY",
		},
	})

	// When probing
	result := probeHidraw(root)

	// Then the PIXY hidraw is found
	if result != "/dev/hidraw7" {
		t.Errorf("expected /dev/hidraw7, got %s", result)
	}
}

func TestProbeHidraw_NoPIXY(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with only non-PIXY hidraw devices
	root := t.TempDir()
	createFakeHidraw(t, root, []fakeHidrawDev{
		{
			name:    "hidraw0",
			hidID:   "0003:00003151:0000402D",
			hidName: "2.4G Wireless Mouse",
		},
		{
			name:    "hidraw3",
			hidID:   "0003:00001A2C:00004852",
			hidName: "SEMICO USB Gaming Keyboard",
		},
	})

	// When probing
	result := probeHidraw(root)

	// Then nothing is found
	if result != "" {
		t.Errorf("expected empty, got %s", result)
	}
}

func TestProbeHidraw_EmptyDir(t *testing.T) {
	t.Parallel()

	// Given an empty hidraw sysfs directory
	root := t.TempDir()

	// When probing
	result := probeHidraw(root)

	// Then nothing is found
	if result != "" {
		t.Errorf("expected empty, got %s", result)
	}
}

func TestProbeHidraw_NonexistentDir(t *testing.T) {
	t.Parallel()

	// Given a nonexistent sysfs path
	result := probeHidraw("/nonexistent/path/hidraw")

	// Then nothing is found
	if result != "" {
		t.Errorf("expected empty, got %s", result)
	}
}

func TestProbeHidraw_MixedDevices(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with mouse, keyboard, and PIXY
	root := t.TempDir()
	createFakeHidraw(t, root, []fakeHidrawDev{
		{
			name:    "hidraw0",
			hidID:   "0003:00003151:0000402D",
			hidName: "2.4G Wireless Mouse",
		},
		{
			name:    "hidraw3",
			hidID:   "0003:00001A2C:00004852",
			hidName: "SEMICO USB Gaming Keyboard",
		},
		{
			name:    "hidraw7",
			hidID:   "0003:0000328F:000000C0",
			hidName: "EMEET PIXY",
		},
		{
			name:    "hidraw8",
			hidID:   "0003:0000043E:00009A39",
			hidName: "LG Electronics Inc. LG Monitor Controls",
		},
	})

	// When probing
	result := probeHidraw(root)

	// Then the PIXY is found
	if result != "/dev/hidraw7" {
		t.Errorf("expected /dev/hidraw7, got %s", result)
	}
}

func TestProbeHidraw_NoUeventFile(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with a directory but no uevent file
	root := t.TempDir()

	dirErr := os.MkdirAll(filepath.Join(root, "hidraw0", "device"), 0o755)
	if dirErr != nil {
		t.Fatalf("mkdir: %v", dirErr)
	}

	// When probing
	result := probeHidraw(root)

	// Then nothing is found (graceful skip)
	if result != "" {
		t.Errorf("expected empty, got %s", result)
	}
}

func TestProbeDevices_SetsStateToOfflineWhenNoVideo(t *testing.T) {
	t.Parallel()

	// Given a daemon with no PIXY video device
	d := newTestDaemon(StatePrivacy, "", "")

	// When probing (real sysfs — PIXY may or may not be connected)
	d.probeDevices()

	// Then if no video device is found, state goes offline
	if d.videoDev == "" && d.state.Camera != StateOffline {
		t.Errorf("expected offline when no video device, got %s", d.state.Camera)
	}
}

func TestProbeDevices_RecoversFromOffline(t *testing.T) {
	t.Parallel()

	// Given a daemon in offline state
	d := newTestDaemon(StateOffline, "", "")

	// When probing (may or may not find device)
	d.probeDevices()

	// Then if a video device is found, state is recovered from offline
	if d.videoDev != "" && d.state.Camera == StateOffline {
		t.Error("expected camera state to recover from offline when device found")
	}
}

func TestProbeVideo4linux_MultipleCamerasPIXYSecond(t *testing.T) {
	t.Parallel()

	// Given a sysfs tree with another camera first, then PIXY
	root := t.TempDir()

	otherDir := filepath.Join(root, "video0")
	writeFakeFile(
		t,
		filepath.Join(otherDir, "device/modalias"),
		"usb:v1234p5678d0100dcEFdsc02dp01ic0Eisc01ip00in00",
	)
	writeFakeFile(t, filepath.Join(otherDir, "index"), "0")
	writeFakeFile(t, filepath.Join(otherDir, "name"), "Other Camera")

	createFakeVideo4linux(t, root, []fakeVideoDev{
		{
			name:     "video2",
			modalias: "usb:v328Fp00C0d2004dcEFdsc02dp01ic0Eisc01ip00in00",
			index:    "0",
		},
	})

	// When probing
	result := probeVideo4linux(root)

	// Then the PIXY is found even though it's not the first device
	if result != "/dev/video2" {
		t.Errorf("expected /dev/video2, got %s", result)
	}
}
