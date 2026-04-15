package main

import (
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

const (
	defaultStateDir      = "/run/emeet-pixyd"
	defaultPollInterval  = 2 * time.Second
	defaultDebounceCount = 3

	pixyVendorID  = "328f"
	pixyProductID = "00c0"
)

var (
	errHIDDeviceNotAvailable = errors.New("PIXY HID device not available")
	errPIXYNotConnected      = errors.New("PIXY not connected")
	errNoHIDResponse         = errors.New("no HID response")
	errUnrecognizedHID       = errors.New("unrecognized HID response")
	errAudioSourceNotFound   = errors.New("PIXY audio source not found")
)

const (
	hidByteTracking = 0x01
	hidBytePrivacy  = 0x02
	hidByteIdle     = 0x00
	hidByteNC       = 0x01
	hidByteLive     = 0x02
	hidByteOriginal = 0x03

	hidBufSize     = 32
	hidRespBufSize = 64
	hidMinLen      = 9
	hidDebugLen    = 16

	hidInterfaceTracking = 0x01
	hidInterfaceAudio    = 0x05
	hidInterfaceGesture  = 0x04

	v4l2DegreesPerUnit = 3600
	hidResponseMs       = 500

	defaultSocketTimeout = 2 * time.Second
	defaultWriteTimeout  = 2 * time.Second
	socketBufSize       = 256
	connBufSize         = 4096

	cameraConfigPrefix  byte = 0x09
	cameraConfigMarker byte = 0x01
	audioConfigMarker  byte = 0x00
	gestureConfigMark1 byte = 0x02
	gestureConfigMark2 byte = 0x01
	gestureConfigMark3 byte = 0x02
	hidCommitMarker    byte = 0x01
	gestureEnabledByte byte = 0x01

	permissionStateDir  = 0o750
	permissionStateFile = 0o600
	permissionSocket   = 0o600
)

type CameraState string

const (
	StateIdle     CameraState = "idle"
	StateTracking CameraState = "tracking"
	StatePrivacy  CameraState = "privacy"
	StateOffline  CameraState = "offline"
)

func (s CameraState) HIDByte() byte {
	switch s {
	case StateTracking:
		return hidByteTracking
	case StatePrivacy:
		return hidBytePrivacy
	case StateIdle:
		return hidByteIdle
	case StateOffline:
		return hidByteIdle
	default:
		return hidByteIdle
	}
}

func (s CameraState) Valid() bool {
	switch s {
	case StateIdle, StateTracking, StatePrivacy, StateOffline:
		return true
	default:
		return false
	}
}

type AudioMode string

const (
	AudioNC       AudioMode = "nc"
	AudioLive     AudioMode = "live"
	AudioOriginal AudioMode = "original"
)

func (m AudioMode) HIDByte() byte {
	switch m {
	case AudioNC:
		return hidByteNC
	case AudioLive:
		return hidByteLive
	case AudioOriginal:
		return hidByteOriginal
	default:
		return hidByteNC
	}
}

func (m AudioMode) Valid() bool {
	switch m {
	case AudioNC, AudioLive, AudioOriginal:
		return true
	default:
		return false
	}
}

func (m AudioMode) Next() AudioMode {
	switch m {
	case AudioNC:
		return AudioLive
	case AudioLive:
		return AudioOriginal
	case AudioOriginal:
		return AudioNC
	default:
		return AudioNC
	}
}

type Config struct {
	StateDir      string
	PollInterval  time.Duration
	DebounceCount int
}

func DefaultConfig() Config {
	return Config{
		StateDir:      defaultStateDir,
		PollInterval:  defaultPollInterval,
		DebounceCount: defaultDebounceCount,
	}
}

func (c Config) StateFile() string  { return c.StateDir + "/state.json" }
func (c Config) SocketPath() string { return c.StateDir + "/control.sock" }

type State struct {
	Camera   CameraState `json:"camera"`
	Audio    AudioMode   `json:"audio"`
	Gesture  bool        `json:"gesture"`
	InCall   bool        `json:"inCall"`
	AutoMode bool        `json:"autoMode"`
}

func DefaultState() State {
	return State{
		Camera:   StatePrivacy,
		Audio:    AudioNC,
		Gesture:  false,
		InCall:   false,
		AutoMode: true,
	}
}

type Daemon struct {
	mu        sync.Mutex
	state     State
	config    Config
	videoDev  string
	hidrawDev string

	debounceInUse int
	debounceIdle  int
}

func NewDaemon(cfg Config) *Daemon {
	d := &Daemon{
		mu:        sync.Mutex{},
		config:    cfg,
		state:     DefaultState(),
		videoDev:  "",
		hidrawDev: "",
	}
	d.loadState()
	d.probeDevices()

	return d
}

func (d *Daemon) probeDevices() {
	d.videoDev = ""
	d.hidrawDev = ""

	entries, err := os.ReadDir("/sys/class/video4linux")
	if err != nil {
		return
	}

	for _, entry := range entries {
		indexPath := filepath.Join("/sys/class/video4linux", entry.Name(), "device/index")

		data, err := os.ReadFile(indexPath)
		if err != nil {
			continue
		}

		if strings.TrimSpace(string(data)) != "0" {
			continue
		}

		modaliasPath := filepath.Join("/sys/class/video4linux", entry.Name(), "device/modalias")

		modalias, err := os.ReadFile(modaliasPath)
		if err != nil {
			continue
		}

		ms := string(modalias)
		if strings.Contains(ms, "v"+pixyVendorID) && strings.Contains(ms, "p"+pixyProductID) {
			d.videoDev = filepath.Join("/dev", entry.Name())

			break
		}
	}

	hidEntries, err := os.ReadDir("/sys/class/hidraw")
	if err != nil {
		return
	}

	for _, entry := range hidEntries {
		ueventPath := filepath.Join("/sys/class/hidraw", entry.Name(), "device/uevent")

		data, err := os.ReadFile(ueventPath)
		if err != nil {
			continue
		}

		content := string(data)
		if strings.Contains(content, "EMEET") && strings.Contains(content, "PIXY") {
			d.hidrawDev = filepath.Join("/dev", entry.Name())

			break
		}
	}

	if d.videoDev != "" {
		if d.state.Camera == StateOffline {
			d.state.Camera = StatePrivacy
		}

		slog.Info("found PIXY device", "video", d.videoDev, "hidraw", d.hidrawDev)
	} else {
		d.state.Camera = StateOffline

		slog.Warn("PIXY not found, will retry on next probe")
	}
}

func (d *Daemon) loadState() {
	data, err := os.ReadFile(d.config.StateFile())
	if err != nil {
		return
	}

	err = json.Unmarshal(data, &d.state)
	if err != nil {
		slog.Warn(
			"failed to parse state file, using defaults",
			"path",
			d.config.StateFile(),
			"error",
			err,
		)
	}
}

func (d *Daemon) ensureStateDir() error {
	return os.MkdirAll(d.config.StateDir, permissionStateDir)
}

func (d *Daemon) saveState() error {
	err := d.ensureStateDir()
	if err != nil {
		return fmt.Errorf("create state dir: %w", err)
	}

	data, err := json.Marshal(d.state)
	if err != nil {
		return fmt.Errorf("marshal state: %w", err)
	}

	return os.WriteFile(d.config.StateFile(), data, permissionStateFile)
}

func (d *Daemon) isDevicePresent() bool {
	return d.videoDev != ""
}

const hidResponseTimeout = hidResponseMs * time.Millisecond

func hidSend(hidrawDev string, report []byte) (err error) {
	if hidrawDev == "" {
		return fmt.Errorf("hidSend: %w", errHIDDeviceNotAvailable)
	}

	buf := make([]byte, hidBufSize)
	copy(buf, report)

	hidFile, err := os.OpenFile(hidrawDev, os.O_WRONLY, 0)
	if err != nil {
		return fmt.Errorf("open hidraw: %w", err)
	}

	defer func() {
		cerr := hidFile.Close()
		if cerr != nil && err == nil {
			err = cerr
		}
	}()

	_, err = hidFile.Write(buf)
	if err != nil {
		return fmt.Errorf("write hidraw: %w", err)
	}

	return nil
}

type hidResponse struct {
	Tracking CameraState
	Audio    AudioMode
	Gesture  bool
	Got      bool
}

func hidSendRecv(ctx context.Context, hidrawDev string, report []byte) ([]byte, error) {
	if hidrawDev == "" {
		return nil, fmt.Errorf("hidSendRecv: %w", errHIDDeviceNotAvailable)
	}

	buf := make([]byte, hidBufSize)
	copy(buf, report)

	hidFile, err := os.OpenFile(hidrawDev, os.O_RDWR, 0)
	if err != nil {
		return nil, fmt.Errorf("open hidraw: %w", err)
	}

	defer func() { _ = hidFile.Close() }()

	written, writeErr := hidFile.Write(buf)
	if writeErr != nil || written == 0 {
		return nil, fmt.Errorf("write hidraw: %w", writeErr)
	}

	type readResult struct {
		data []byte
		err  error
	}

	resultChan := make(chan readResult, 1)

	go func() {
		resp := make([]byte, hidRespBufSize)

		n, readErr := hidFile.Read(resp)
		resultChan <- readResult{resp[:n], readErr}
	}()

	select {
	case <-ctx.Done():
		return nil, fmt.Errorf("hidSendRecv context: %w", ctx.Err())
	case r := <-resultChan:
		if r.err != nil {
			return nil, r.err
		}

		return r.data, nil
	case <-time.After(hidResponseTimeout):
		return nil, nil
	}
}

func parseHIDResponse(data []byte) hidResponse {
	if len(data) < hidMinLen {
		return hidResponse{
			Tracking: StateIdle,
			Audio:    AudioNC,
			Gesture:  false,
			Got:      false,
		}
	}

	resp := hidResponse{
		Tracking: StateIdle,
		Audio:    AudioNC,
		Gesture:  false,
		Got:      true,
	}

	slog.Debug("HID response", "hex", hex.EncodeToString(data[:min(len(data), hidDebugLen)]))

	switch {
	case data[0] == cameraConfigPrefix && data[1] == hidInterfaceTracking:
		switch data[8] {
		case hidByteTracking:
			resp.Tracking = StateTracking
		case hidBytePrivacy:
			resp.Tracking = StatePrivacy
		default:
			resp.Tracking = StateIdle
		}
	case data[0] == cameraConfigPrefix && data[1] == hidInterfaceAudio:
		switch data[8] {
		case hidByteLive:
			resp.Audio = AudioLive
		case hidByteOriginal:
			resp.Audio = AudioOriginal
		default:
			resp.Audio = AudioNC
		}
	case data[0] == cameraConfigPrefix && data[1] == hidInterfaceGesture:
		resp.Gesture = data[len(data)-1] == gestureEnabledByte
	}

	return resp
}

func v4l2Set(ctx context.Context, dev, ctrl, value string) error {
	return exec.CommandContext(ctx, "v4l2-ctl", "-d", dev, "--set-ctrl="+ctrl+"="+value).Run()
}

func v4l2Get(ctx context.Context, dev, ctrl string) (string, error) {
	out, err := exec.CommandContext(ctx, "v4l2-ctl", "-d", dev, "--get-ctrl="+ctrl).Output()
	if err != nil {
		return "", fmt.Errorf("v4l2Get: %w", err)
	}

	parts := strings.Split(strings.TrimSpace(string(out)), ":")
	if len(parts) == 2 {
		return strings.TrimSpace(parts[1]), nil
	}

	return strings.TrimSpace(string(out)), nil
}

type stateSetter func(d *Daemon)

type hidMode interface {
	HIDByte() byte
}

func pixyConfig(iface byte, mode hidMode) []byte {
	var buf [hidMinLen]byte

	buf[0] = cameraConfigPrefix
	buf[1] = iface
	buf[2] = cameraConfigMarker
	buf[3] = 0x00
	buf[4] = 0x00
	buf[5] = cameraConfigMarker
	buf[6] = 0x00
	buf[7] = cameraConfigMarker
	buf[8] = mode.HIDByte()

	return buf[:]
}

func pixyCommit(iface byte) []byte {
	return []byte{0x09, iface, 0x01, iface}
}

func (d *Daemon) setDeviceState(configBytes, commitBytes []byte, setter stateSetter) error {
	if !d.isDevicePresent() {
		return fmt.Errorf("setDeviceState: %w", errPIXYNotConnected)
	}

	err := hidSend(d.hidrawDev, configBytes)
	if err != nil {
		d.probeDevices()

		return err
	}

	time.Sleep(200 * time.Millisecond)

	err = hidSend(d.hidrawDev, commitBytes)
	if err != nil {
		return err
	}

	setter(d)

	saveErr := d.saveState()
	if saveErr != nil {
		slog.Error("failed to save state", "error", saveErr)
	}

	return nil
}

func (d *Daemon) setTracking(mode CameraState) error {
	return d.setDeviceState(
		pixyConfig(hidInterfaceTracking, mode),
		pixyCommit(hidInterfaceTracking),
		func(d *Daemon) { d.state.Camera = mode },
	)
}

func (d *Daemon) setAudio(mode AudioMode) error {
	return d.setDeviceState(
		pixyConfig(hidInterfaceAudio, mode),
		pixyCommit(hidInterfaceAudio),
		func(d *Daemon) { d.state.Audio = mode },
	)
}

func (d *Daemon) setGesture(enabled bool) error {
	var modeByte byte
	if enabled {
		modeByte = 0x01
	}

	configBytes := []byte{0x09, 0x04, 0x02, 0x00, 0x00, 0x02, 0x00, 0x02, 0x02, modeByte}
	commitBytes := []byte{0x09, 0x04, 0x02, 0x01, 0x00, 0x01, 0x00, 0x01, 0x02}

	return d.setDeviceState(configBytes, commitBytes, func(d *Daemon) { d.state.Gesture = enabled })
}

func setDeadline(conn net.Conn, timeout time.Duration) error {
	return fmt.Errorf("setDeadline: %w", conn.SetDeadline(time.Now().Add(timeout)))
}

func (d *Daemon) centerCamera(ctx context.Context) error {
	if !d.isDevicePresent() {
		return fmt.Errorf("centerCamera: %w", errPIXYNotConnected)
	}

	err := v4l2Set(ctx, d.videoDev, "pan_absolute", "0")
	if err != nil {
		return err
	}

	err = v4l2Set(ctx, d.videoDev, "tilt_absolute", "0")
	if err != nil {
		return err
	}

	return v4l2Set(ctx, d.videoDev, "zoom_absolute", "100")
}

func (d *Daemon) queryHIDState(
	ctx context.Context,
	payload []byte,
	getResult func(hidResponse) any,
) (any, error) {
	if d.hidrawDev == "" {
		return nil, fmt.Errorf("queryHIDState: %w", errHIDDeviceNotAvailable)
	}

	resp, err := hidSendRecv(ctx, d.hidrawDev, payload)
	if err != nil {
		return nil, err
	}

	if resp == nil {
		return nil, fmt.Errorf("queryHIDState: %w", errNoHIDResponse)
	}

	parsed := parseHIDResponse(resp)
	if !parsed.Got {
		return nil, fmt.Errorf("queryHIDState: %w", errUnrecognizedHID)
	}

	return getResult(parsed), nil
}

func (d *Daemon) queryTracking(_ context.Context) (CameraState, error) {
	result, err := d.queryHIDState(
		context.Background(),
		[]byte{cameraConfigPrefix, hidInterfaceTracking, 0x01, 0x01},
		func(p hidResponse) any {
			return p.Tracking
		},
	)
	if err != nil {
		return "", err
	}

	resultCamera, ok := result.(CameraState)
	if !ok {
		return "", fmt.Errorf("queryTracking type assertion failed: %w", err)
	}

	return resultCamera, nil
}

func (d *Daemon) queryAudio(_ context.Context) (AudioMode, error) {
	result, err := d.queryHIDState(
		context.Background(),
		[]byte{cameraConfigPrefix, hidInterfaceAudio, audioConfigMarker, 0x04},
		func(p hidResponse) any {
			return p.Audio
		},
	)
	if err != nil {
		return "", err
	}

	resultAudio, ok := result.(AudioMode)
	if !ok {
		return "", fmt.Errorf("queryAudio type assertion failed: %w", err)
	}

	return resultAudio, nil
}

func (d *Daemon) queryGesture(ctx context.Context) (bool, error) {
	if d.hidrawDev == "" {
		return false, fmt.Errorf("queryGesture: %w", errHIDDeviceNotAvailable)
	}

	resp, err := hidSendRecv(
		ctx,
		d.hidrawDev,
		[]byte{
			cameraConfigPrefix, hidInterfaceGesture,
			gestureConfigMark1, gestureConfigMark2,
			0x00, cameraConfigMarker,
			0x00, cameraConfigMarker,
			gestureConfigMark3,
		},
	)
	if err != nil {
		return false, err
	}

	if resp == nil {
		return false, fmt.Errorf("queryGesture: %w", errNoHIDResponse)
	}

	parsed := parseHIDResponse(resp)
	if !parsed.Got {
		return false, fmt.Errorf("queryGesture: %w", errUnrecognizedHID)
	}

	return parsed.Gesture, nil
}

func (d *Daemon) syncState(ctx context.Context) string {
	if !d.isDevicePresent() {
		return "error: PIXY not connected"
	}

	changed := false

	tracking, trackingErr := d.queryTracking(ctx)
	if trackingErr == nil && tracking.Valid() && tracking != StateOffline {
		if d.state.Camera != tracking {
			slog.Info("state sync: camera changed", "believed", d.state.Camera, "actual", tracking)
			d.state.Camera = tracking
			changed = true
		}
	} else if trackingErr != nil {
		slog.Debug("tracking query failed", "error", trackingErr)
	}

	audio, audioErr := d.queryAudio(ctx)
	if audioErr == nil && audio.Valid() {
		if d.state.Audio != audio {
			slog.Info("state sync: audio changed", "believed", d.state.Audio, "actual", audio)
			d.state.Audio = audio
			changed = true
		}
	} else if audioErr != nil {
		slog.Debug("audio query failed", "error", audioErr)
	}

	gesture, gestureErr := d.queryGesture(ctx)
	if gestureErr == nil {
		if d.state.Gesture != gesture {
			slog.Info("state sync: gesture changed", "believed", d.state.Gesture, "actual", gesture)
			d.state.Gesture = gesture
			changed = true
		}
	} else if gestureErr != nil {
		slog.Debug("gesture query failed", "error", gestureErr)
	}

	if changed {
		saveErr := d.saveState()
		if saveErr != nil {
			slog.Error("failed to save synced state", "error", saveErr)
		}

		return "synced (state updated from camera)"
	}

	return "synced (no changes)"
}

func isCameraInUse(videoDev string) bool {
	if videoDev == "" {
		return false
	}

	procEntries, err := os.ReadDir("/proc")
	if err != nil {
		return false
	}

	for _, proc := range procEntries {
		if !proc.IsDir() {
			continue
		}

		_, parseErr := strconv.Atoi(proc.Name())
		if parseErr != nil {
			continue
		}

		fdPath := filepath.Join("/proc", proc.Name(), "fd")

		fdEntries, err := os.ReadDir(fdPath)
		if err != nil {
			continue
		}

		for _, fd := range fdEntries {
			link, err := os.Readlink(filepath.Join(fdPath, fd.Name()))
			if err != nil {
				continue
			}

			if link != videoDev {
				continue
			}

			statPath := filepath.Join("/proc", proc.Name(), "stat")

			statData, err := os.ReadFile(statPath)
			if err != nil {
				continue
			}

			statStr := string(statData)

			lastParen := strings.LastIndex(statStr, ")")
			if lastParen == -1 {
				continue
			}

			comm := statStr[:lastParen+1]
			if strings.Contains(comm, "emeet-pixyd") {
				continue
			}

			return true
		}
	}

	return false
}

func findPixySource(ctx context.Context) (string, error) {
	out, err := exec.CommandContext(ctx, "wpctl", "status").Output()
	if err != nil {
		return "", fmt.Errorf("findPixySource: %w", err)
	}

	for line := range strings.SplitSeq(string(out), "\n") {
		if strings.Contains(line, "EMEET") || strings.Contains(line, "Pixy") ||
			strings.Contains(line, "PIXY") {
			for field := range strings.FieldsSeq(line) {
				field = strings.TrimSuffix(field, ".")
					_, parseErr := strconv.Atoi(field)
				if parseErr == nil {
					return field, nil
				}
			}
		}
	}

	return "", fmt.Errorf("findPixySource: %w", errAudioSourceNotFound)
}

func setDefaultSource(ctx context.Context, sourceID string) {
	err := exec.CommandContext(ctx, "wpctl", "set-default", sourceID).Run()
	if err != nil {
		slog.Error("failed to set default audio source", "id", sourceID, "error", err)
	}
}

func notify(ctx context.Context, title, body string) {
	err := exec.CommandContext(ctx, "notify-send", "-a", "emeet-pixyd", title, body).Run()
	if err != nil {
		slog.Debug("notification failed", "error", err)
	}
}

func sdNotify(state string) {
	socket := os.Getenv("NOTIFY_SOCKET")
	if socket == "" {
		return
	}

	conn, err := net.DialTimeout("unixgram", socket, 1*time.Second)
	if err != nil {
		slog.Debug("sd_notify failed", "error", err)

		return
	}
	defer func() {
		if closeErr := conn.Close(); closeErr != nil {
			slog.Debug("conn close error", "error", closeErr)
		}
	}()

	deadlineErr := setDeadline(conn, 1*time.Second)
	if deadlineErr != nil {
		return
	}

	writeErr := conn.Write([]byte(state))
	if writeErr != nil {
		slog.Debug("sd_notify write failed", "error", writeErr)
	}
}

func (d *Daemon) autoManage(ctx context.Context) {
	d.mu.Lock()
	defer d.mu.Unlock()

	if !d.isDevicePresent() {
		d.probeDevices()

		if !d.isDevicePresent() {
			return
		}
	}

	if !d.state.AutoMode {
		return
	}

	inUse := isCameraInUse(d.videoDev)

	if inUse {
		d.debounceIdle = 0
		d.debounceInUse++
	} else {
		d.debounceInUse = 0
		d.debounceIdle++
	}

	cameraInUseNotInCall := inUse && !d.state.InCall && d.debounceInUse >= d.config.DebounceCount
	if cameraInUseNotInCall {
		slog.Info("camera in use, activating tracking and noise cancellation")

		d.state.InCall = true
		if d.state.Camera == StatePrivacy || d.state.Camera == StateIdle {
			trackErr := d.setTracking(StateTracking)
			if trackErr != nil {
				slog.Error("failed to activate tracking", "error", trackErr)
			}
		}

		if d.state.Audio != AudioNC {
			audioErr := d.setAudio(AudioNC)
			if audioErr != nil {
				slog.Error("failed to set audio mode", "error", audioErr)
			}
		}

		src, srcErr := findPixySource(ctx)
	if srcErr == nil {
			setDefaultSource(ctx, src)
			slog.Info("set PipeWire default source to PIXY", "id", src)
		}

		notify(ctx, "EMEET PIXY", "Camera activated — tracking enabled")
	}

	cameraReleasedInCall := !inUse && d.state.InCall && d.debounceIdle >= d.config.DebounceCount
	if cameraReleasedInCall {
		slog.Info("camera released, entering privacy mode")

		d.state.InCall = false

		privacyErr := d.setTracking(StatePrivacy)
		if privacyErr != nil {
			slog.Error("failed to enter privacy mode", "error", privacyErr)
		}

		notify(ctx, "EMEET PIXY", "Camera privacy mode — physically disabled")
	}

	saveErr := d.saveState()
	if saveErr != nil {
		slog.Error("failed to save state", "error", saveErr)
	}
}

func (d *Daemon) getStatus(ctx context.Context) string {
	if !d.isDevicePresent() {
		return "camera=offline (device not found)"
	}

	pan, _ := v4l2Get(ctx, d.videoDev, "pan_absolute")
	tilt, _ := v4l2Get(ctx, d.videoDev, "tilt_absolute")
	zoom, _ := v4l2Get(ctx, d.videoDev, "zoom_absolute")

	panDeg := 0
	tiltDeg := 0
	zoomVal := 100

	panVal, panErr := strconv.Atoi(pan)
	if panErr == nil {
		panDeg = panVal / v4l2DegreesPerUnit
	}

	tiltVal, tiltErr := strconv.Atoi(tilt)
	if tiltErr == nil {
		tiltDeg = tiltVal / v4l2DegreesPerUnit
	}

	zoomValInt, zoomErr := strconv.Atoi(zoom)
	if zoomErr == nil {
		zoomVal = zoomValInt
	}

	inCallStr := "no"
	if d.state.InCall {
		inCallStr = "yes"
	}

	autoStr := "on"
	if !d.state.AutoMode {
		autoStr = "off"
	}

	return fmt.Sprintf(
		"camera=%s audio=%s gesture=%v pan=%d tilt=%d zoom=%d in_call=%s auto=%s",
		d.state.Camera,
		d.state.Audio,
		d.state.Gesture,
		panDeg,
		tiltDeg,
		zoomVal,
		inCallStr,
		autoStr,
	)
}

func (d *Daemon) handleCommand(ctx context.Context, cmd string) string {
	d.mu.Lock()
	defer d.mu.Unlock()

	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		return d.getStatus(ctx)
	}

	switch parts[0] {
	case "status":
		return d.getStatus(ctx)

	case "track":
		err := d.setTracking(StateTracking)
		if err != nil {
			return "error: " + err.Error()
		}

		return "tracking on"

	case "idle":
		err := d.setTracking(StateIdle)
		if err != nil {
			return "error: " + err.Error()
		}

		return "tracking off"

	case "privacy":
		err := d.setTracking(StatePrivacy)
		if err != nil {
			return "error: " + err.Error()
		}

		return "privacy on"

	case "toggle-privacy":
		newState := StatePrivacy
		if d.state.Camera == StatePrivacy {
			newState = StateTracking
		}

		privacyErr := d.setTracking(newState)
		if privacyErr != nil {
			return "error: " + privacyErr.Error()
		}

		if newState == StatePrivacy {
			return "privacy on"
		}

		return "tracking on"

	case "audio":
		var mode AudioMode
		if len(parts) < 2 {
			mode = d.state.Audio.Next()
		} else {
			switch parts[1] {
			case "nc":
				mode = AudioNC
			case "live":
				mode = AudioLive
			case "org":
				mode = AudioOriginal
			default:
				return "usage: audio [nc|live|org]"
			}
		}

		audioErr := d.setAudio(mode)
		if audioErr != nil {
			return "error: " + audioErr.Error()
		}

		return "audio: " + string(mode)

	case "gesture-on":
		gestureErr := d.setGesture(true)
		if gestureErr != nil {
			return "error: " + gestureErr.Error()
		}

		return "gesture on"

	case "gesture-off":
		gestureErr := d.setGesture(false)
		if gestureErr != nil {
			return "error: " + gestureErr.Error()
		}

		return "gesture off"

	case "center":
		centerErr := d.centerCamera(ctx)
		if centerErr != nil {
			return "error: " + centerErr.Error()
		}

		return "centered"

	case "auto-on":
		d.state.AutoMode = true

		saveErr := d.saveState()
		if saveErr != nil {
			slog.Error("failed to save state", "error", saveErr)
		}

		return "auto mode on"

	case "auto-off":
		d.state.AutoMode = false

		saveErr := d.saveState()
		if saveErr != nil {
			slog.Error("failed to save state", "error", saveErr)
		}

		return "auto mode off"

	case "waybar":
		return d.waybarOutput()

	case "sync":
		return d.syncState(ctx)

	case "probe":
		d.probeDevices()

		if d.isDevicePresent() {
			return "device found: " + d.videoDev
		}

		return "device not found"

	default:
		return "unknown command: " + parts[0]
	}
}

func (d *Daemon) waybarOutput() string {
	icon := ""
	class := ""
	text := ""

	switch d.state.Camera {
	case StateTracking:
		icon = "\uf030"
		class = "tracking"
		text = "CAM"
	case StatePrivacy:
		icon = "\uf011"
		class = "privacy"
		text = "OFF"
	case StateIdle:
		icon = "\uf03d"
		class = "idle"
		text = "IDLE"
	case StateOffline:
		icon = "\uf00d"
		class = "offline"
		text = "---"
	}

	if d.state.InCall {
		class += " in-call"
	}

	tooltip := fmt.Sprintf("EMEET PIXY: %s", d.state.Camera)
	tooltip += fmt.Sprintf("\nAudio: %s", d.state.Audio)

	tooltip += fmt.Sprintf("\nAuto: %t", d.state.AutoMode)
	if d.state.InCall {
		tooltip += "\nIn call: yes"
	}

	out := map[string]string{
		"text":    icon + " " + text,
		"tooltip": tooltip,
		"class":   "custom-camera " + class,
	}

	data, err := json.Marshal(out)
	if err != nil {
		return `{"text":"?","tooltip":"json marshal error","class":"custom-camera offline"}`
	}

	return string(data)
}

func (d *Daemon) listenUnix(ctx context.Context) error {
	socketPath := d.config.SocketPath()
	_ = os.Remove(socketPath)

	createErr := os.MkdirAll(d.config.StateDir, permissionStateDir)
	if createErr != nil {
		return fmt.Errorf("create state dir: %w", createErr)
	}

	listener, err := net.Listen("unix", socketPath)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	defer func() {
		if closeErr := listener.Close(); closeErr != nil {
			slog.Debug("listener close error", "error", closeErr)
		}
	}()

	if chmodErr := os.Chmod(socketPath, permissionSocket); chmodErr != nil {
		slog.Error("failed to set socket permissions", "error", chmodErr)
	}

	for {
		conn, acceptErr := listener.Accept()
		if acceptErr != nil {
			slog.Error("socket accept error", "error", acceptErr)

			continue
		}

		buf := make([]byte, socketBufSize)

		n, readErr := conn.Read(buf)
		if readErr == nil && n > 0 {
			cmd := strings.TrimSpace(string(buf[:n]))

			response := d.handleCommand(ctx, cmd) + "\n"
			if _, writeErr := conn.Write([]byte(response)); writeErr != nil {
				slog.Debug("socket write error", "error", writeErr)
			}
		}

		if closeErr := conn.Close(); closeErr != nil {
			slog.Debug("conn close error", "error", closeErr)
		}
	}
}

func sendCommand(cfg Config, cmd string) (string, error) {
	conn, err := net.DialTimeout("unix", cfg.SocketPath(), defaultSocketTimeout)
	if err != nil {
		return "", fmt.Errorf("sendCommand dial: %w", err)
	}

	defer func() { _ = conn.Close() }()

	if deadlineErr := setDeadline(conn, defaultWriteTimeout); deadlineErr != nil {
		return "", deadlineErr
	}

	if _, writeErr := conn.Write([]byte(cmd)); writeErr != nil {
		return "", fmt.Errorf("sendCommand write: %w", writeErr)
	}

	buf := make([]byte, connBufSize)

	n, readErr := conn.Read(buf)
	if readErr != nil {
		return "", fmt.Errorf("sendCommand read: %w", readErr)
	}

	return strings.TrimSpace(string(buf[:n])), nil
}

func (d *Daemon) Run() {
	createErr := os.MkdirAll(d.config.StateDir, permissionStateDir)
	if createErr != nil {
		slog.Error("failed to create state dir", "error", createErr)
	}

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigs
		sdNotify("STOPPING=1")

		_ = os.Remove(d.config.SocketPath())
		_ = os.Remove(d.config.StateFile())

		os.Exit(0)
	}()

	go func() {
		listenErr := d.listenUnix(context.Background())
		if listenErr != nil {
			slog.Error("unix socket error", "error", listenErr)
			os.Exit(1)
		}
	}()

	slog.Info("EMEET PIXY daemon started")
	sdNotify("READY=1")
	d.mu.Lock()
	slog.Info(
		"initial state",
		"camera",
		d.state.Camera,
		"audio",
		d.state.Audio,
		"auto",
		d.state.AutoMode,
	)
	d.mu.Unlock()

	ticker := time.NewTicker(d.config.PollInterval)
	defer ticker.Stop()

	for range ticker.C {
		d.autoManage(context.Background())
		sdNotify("WATCHDOG=1")
	}
}

func main() {
	cfg := DefaultConfig()

	if len(os.Args) > 1 {
		cmd := strings.Join(os.Args[1:], " ")

		resp, err := sendCommand(cfg, cmd)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\nIs emeet-pixyd running?\n", err)
			os.Exit(1)
		}

		fmt.Fprintln(os.Stdout, resp)

		return
	}

	d := NewDaemon(cfg)
	d.Run()
}
