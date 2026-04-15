package main

import (
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
		return 0x01
	case StatePrivacy:
		return 0x02
	default:
		return 0x00
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
		return 0x01
	case AudioLive:
		return 0x02
	case AudioOriginal:
		return 0x03
	default:
		return 0x01
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
	InCall   bool        `json:"in_call"`
	AutoMode bool        `json:"auto_mode"`
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
		config: cfg,
		state: State{
			Camera:   StatePrivacy,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
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

	if err := json.Unmarshal(data, &d.state); err != nil {
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
	return os.MkdirAll(d.config.StateDir, 0o755)
}

func (d *Daemon) saveState() error {
	if err := d.ensureStateDir(); err != nil {
		return fmt.Errorf("create state dir: %w", err)
	}

	data, err := json.Marshal(d.state)
	if err != nil {
		return err
	}

	return os.WriteFile(d.config.StateFile(), data, 0o644)
}

func (d *Daemon) isDevicePresent() bool {
	return d.videoDev != ""
}

const hidResponseTimeout = 500 * time.Millisecond

func hidSend(hidrawDev string, report []byte) (err error) {
	if hidrawDev == "" {
		return errors.New("PIXY HID device not available")
	}

	buf := make([]byte, 32)
	copy(buf, report)

	var f *os.File

	f, err = os.OpenFile(hidrawDev, os.O_WRONLY, 0)
	if err != nil {
		return fmt.Errorf("open hidraw: %w", err)
	}

	defer func() {
		cerr := f.Close()
		if cerr != nil && err == nil {
			err = cerr
		}
	}()

	_, err = f.Write(buf)

	return err
}

type hidResponse struct {
	Tracking CameraState
	Audio    AudioMode
	Gesture  bool
	Got      bool
}

func hidSendRecv(hidrawDev string, report []byte) ([]byte, error) {
	if hidrawDev == "" {
		return nil, errors.New("PIXY HID device not available")
	}

	buf := make([]byte, 32)
	copy(buf, report)

	f, err := os.OpenFile(hidrawDev, os.O_RDWR, 0)
	if err != nil {
		return nil, fmt.Errorf("open hidraw: %w", err)
	}
	defer func() { _ = f.Close() }()

	if _, err := f.Write(buf); err != nil {
		return nil, err
	}

	type readResult struct {
		data []byte
		err  error
	}

	ch := make(chan readResult, 1)

	go func() {
		resp := make([]byte, 64)

		n, rerr := f.Read(resp)
		ch <- readResult{resp[:n], rerr}
	}()

	select {
	case r := <-ch:
		if r.err != nil {
			return nil, r.err
		}

		return r.data, nil
	case <-time.After(hidResponseTimeout):
		return nil, nil
	}
}

func parseHIDResponse(data []byte) hidResponse {
	if len(data) < 9 {
		return hidResponse{}
	}

	resp := hidResponse{Got: true}

	slog.Debug("HID response", "hex", hex.EncodeToString(data[:min(len(data), 16)]))

	switch {
	case data[0] == 0x09 && data[1] == 0x01:
		switch data[8] {
		case 0x01:
			resp.Tracking = StateTracking
		case 0x02:
			resp.Tracking = StatePrivacy
		default:
			resp.Tracking = StateIdle
		}
	case data[0] == 0x09 && data[1] == 0x05:
		switch data[8] {
		case 0x02:
			resp.Audio = AudioLive
		case 0x03:
			resp.Audio = AudioOriginal
		default:
			resp.Audio = AudioNC
		}
	case data[0] == 0x09 && data[1] == 0x04:
		resp.Gesture = data[len(data)-1] == 0x01
	}

	return resp
}

func v4l2Set(dev, ctrl, value string) error {
	return exec.Command("v4l2-ctl", "-d", dev, "--set-ctrl="+ctrl+"="+value).Run()
}

func v4l2Get(dev, ctrl string) (string, error) {
	out, err := exec.Command("v4l2-ctl", "-d", dev, "--get-ctrl="+ctrl).Output()
	if err != nil {
		return "", err
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
	var b [9]byte
	b[0] = 0x09
	b[1] = iface
	b[2] = 0x01
	b[3] = 0x00
	b[4] = 0x00
	b[5] = 0x01
	b[6] = 0x00
	b[7] = 0x01
	b[8] = mode.HIDByte()
	return b[:]
}

func pixyCommit(iface byte) []byte {
	return []byte{0x09, iface, 0x01, iface}
}

func (d *Daemon) setDeviceState(configBytes, commitBytes []byte, setter stateSetter) error {
	if !d.isDevicePresent() {
		return errors.New("PIXY not connected")
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

	err = d.saveState()
	if err != nil {
		slog.Error("failed to save state", "error", err)
	}

	return nil
}

func (d *Daemon) setTracking(mode CameraState) error {
	return d.setDeviceState(pixyConfig(0x01, mode), pixyCommit(0x01), func(d *Daemon) { d.state.Camera = mode })
}

func (d *Daemon) setAudio(mode AudioMode) error {
	return d.setDeviceState(pixyConfig(0x05, mode), pixyCommit(0x05), func(d *Daemon) { d.state.Audio = mode })
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
	return conn.SetDeadline(time.Now().Add(timeout))
}

func (d *Daemon) centerCamera() error {
	if !d.isDevicePresent() {
		return errors.New("PIXY not connected")
	}

	err := v4l2Set(d.videoDev, "pan_absolute", "0")
	if err != nil {
		return err
	}

	err = v4l2Set(d.videoDev, "tilt_absolute", "0")
	if err != nil {
		return err
	}

	return v4l2Set(d.videoDev, "zoom_absolute", "100")
}

func (d *Daemon) queryTracking() (CameraState, error) {
	if d.hidrawDev == "" {
		return "", errors.New("PIXY HID device not available")
	}

	resp, err := hidSendRecv(d.hidrawDev, []byte{0x09, 0x01, 0x01, 0x01})
	if err != nil {
		return "", err
	}

	if resp == nil {
		return "", errors.New("no HID response")
	}

	parsed := parseHIDResponse(resp)
	if !parsed.Got {
		return "", errors.New("unrecognized HID response")
	}

	return parsed.Tracking, nil
}

func (d *Daemon) queryAudio() (AudioMode, error) {
	if d.hidrawDev == "" {
		return "", errors.New("PIXY HID device not available")
	}

	resp, err := hidSendRecv(d.hidrawDev, []byte{0x09, 0x05, 0x00, 0x04})
	if err != nil {
		return "", err
	}

	if resp == nil {
		return "", errors.New("no HID response")
	}

	parsed := parseHIDResponse(resp)
	if !parsed.Got {
		return "", errors.New("unrecognized HID response")
	}

	return parsed.Audio, nil
}

func (d *Daemon) queryGesture() (bool, error) {
	if d.hidrawDev == "" {
		return false, errors.New("PIXY HID device not available")
	}

	resp, err := hidSendRecv(
		d.hidrawDev,
		[]byte{0x09, 0x04, 0x02, 0x01, 0x00, 0x01, 0x00, 0x01, 0x02},
	)
	if err != nil {
		return false, err
	}

	if resp == nil {
		return false, errors.New("no HID response")
	}

	parsed := parseHIDResponse(resp)
	if !parsed.Got {
		return false, errors.New("unrecognized HID response")
	}

	return parsed.Gesture, nil
}

func (d *Daemon) syncState() string {
	if !d.isDevicePresent() {
		return "error: PIXY not connected"
	}

	changed := false

	if tracking, err := d.queryTracking(); err == nil && tracking.Valid() &&
		tracking != StateOffline {
		if d.state.Camera != tracking {
			slog.Info("state sync: camera changed", "believed", d.state.Camera, "actual", tracking)
			d.state.Camera = tracking
			changed = true
		}
	} else if err != nil {
		slog.Debug("tracking query failed", "error", err)
	}

	if audio, err := d.queryAudio(); err == nil && audio.Valid() {
		if d.state.Audio != audio {
			slog.Info("state sync: audio changed", "believed", d.state.Audio, "actual", audio)
			d.state.Audio = audio
			changed = true
		}
	} else if err != nil {
		slog.Debug("audio query failed", "error", err)
	}

	if gesture, err := d.queryGesture(); err == nil {
		if d.state.Gesture != gesture {
			slog.Info("state sync: gesture changed", "believed", d.state.Gesture, "actual", gesture)
			d.state.Gesture = gesture
			changed = true
		}
	} else if err != nil {
		slog.Debug("gesture query failed", "error", err)
	}

	if changed {
		err := d.saveState()
		if err != nil {
			slog.Error("failed to save synced state", "error", err)
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

		if _, err := strconv.Atoi(proc.Name()); err != nil {
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

func findPixySource() (string, error) {
	out, err := exec.Command("wpctl", "status").Output()
	if err != nil {
		return "", err
	}

	for line := range strings.SplitSeq(string(out), "\n") {
		if strings.Contains(line, "EMEET") || strings.Contains(line, "Pixy") ||
			strings.Contains(line, "PIXY") {
			for f := range strings.FieldsSeq(line) {
				f = strings.TrimSuffix(f, ".")
				if _, err := strconv.Atoi(f); err == nil {
					return f, nil
				}
			}
		}
	}

	return "", errors.New("PIXY audio source not found")
}

func setDefaultSource(sourceID string) {
	err := exec.Command("wpctl", "set-default", sourceID).Run()
	if err != nil {
		slog.Error("failed to set default audio source", "id", sourceID, "error", err)
	}
}

func notify(title, body string) {
	err := exec.Command("notify-send", "-a", "emeet-pixyd", title, body).Run()
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
	defer conn.Close()

	if err := setDeadline(conn, 1*time.Second); err != nil {
		return
	}

	if _, err := conn.Write([]byte(state)); err != nil {
		slog.Debug("sd_notify write failed", "error", err)
	}
}

func (d *Daemon) autoManage() {
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

	if inUse && !d.state.InCall && d.debounceInUse >= d.config.DebounceCount {
		slog.Info("camera in use, activating tracking and noise cancellation")

		d.state.InCall = true
		if d.state.Camera == StatePrivacy || d.state.Camera == StateIdle {
			err := d.setTracking(StateTracking)
			if err != nil {
				slog.Error("failed to activate tracking", "error", err)
			}
		}

		if d.state.Audio != AudioNC {
			err := d.setAudio(AudioNC)
			if err != nil {
				slog.Error("failed to set audio mode", "error", err)
			}
		}

		if src, err := findPixySource(); err == nil {
			setDefaultSource(src)
			slog.Info("set PipeWire default source to PIXY", "id", src)
		}

		notify("EMEET PIXY", "Camera activated — tracking enabled")
	} else if !inUse && d.state.InCall && d.debounceIdle >= d.config.DebounceCount {
		slog.Info("camera released, entering privacy mode")

		d.state.InCall = false

		err := d.setTracking(StatePrivacy)
		if err != nil {
			slog.Error("failed to enter privacy mode", "error", err)
		}

		notify("EMEET PIXY", "Camera privacy mode — physically disabled")
	}

	err := d.saveState()
	if err != nil {
		slog.Error("failed to save state", "error", err)
	}
}

func (d *Daemon) getStatus() string {
	if !d.isDevicePresent() {
		return "camera=offline (device not found)"
	}

	pan, _ := v4l2Get(d.videoDev, "pan_absolute")
	tilt, _ := v4l2Get(d.videoDev, "tilt_absolute")
	zoom, _ := v4l2Get(d.videoDev, "zoom_absolute")

	panDeg := 0
	tiltDeg := 0
	zoomVal := 100

	if p, err := strconv.Atoi(pan); err == nil {
		panDeg = p / 3600
	}

	if t, err := strconv.Atoi(tilt); err == nil {
		tiltDeg = t / 3600
	}

	if z, err := strconv.Atoi(zoom); err == nil {
		zoomVal = z
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

func (d *Daemon) handleCommand(cmd string) string {
	d.mu.Lock()
	defer d.mu.Unlock()

	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		return d.getStatus()
	}

	switch parts[0] {
	case "status":
		return d.getStatus()

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

		err := d.setTracking(newState)
		if err != nil {
			return "error: " + err.Error()
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

		err := d.setAudio(mode)
		if err != nil {
			return "error: " + err.Error()
		}

		return "audio: " + string(mode)

	case "gesture-on":
		err := d.setGesture(true)
		if err != nil {
			return "error: " + err.Error()
		}

		return "gesture on"

	case "gesture-off":
		err := d.setGesture(false)
		if err != nil {
			return "error: " + err.Error()
		}

		return "gesture off"

	case "center":
		err := d.centerCamera()
		if err != nil {
			return "error: " + err.Error()
		}

		return "centered"

	case "auto-on":
		d.state.AutoMode = true

		err := d.saveState()
		if err != nil {
			slog.Error("failed to save state", "error", err)
		}

		return "auto mode on"

	case "auto-off":
		d.state.AutoMode = false

		err := d.saveState()
		if err != nil {
			slog.Error("failed to save state", "error", err)
		}

		return "auto mode off"

	case "waybar":
		return d.waybarOutput()

	case "sync":
		return d.syncState()

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

func (d *Daemon) listenUnix() error {
	socketPath := d.config.SocketPath()
	_ = os.Remove(socketPath)

	if err := os.MkdirAll(d.config.StateDir, 0o755); err != nil {
		return fmt.Errorf("create state dir: %w", err)
	}

	l, err := net.Listen("unix", socketPath)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	defer l.Close()

	if err := os.Chmod(socketPath, 0o600); err != nil {
		slog.Error("failed to set socket permissions", "error", err)
	}

	for {
		conn, err := l.Accept()
		if err != nil {
			slog.Error("socket accept error", "error", err)

			continue
		}

		buf := make([]byte, 256)

		n, err := conn.Read(buf)
		if err == nil && n > 0 {
			cmd := strings.TrimSpace(string(buf[:n]))

			response := d.handleCommand(cmd) + "\n"
			if _, err := conn.Write([]byte(response)); err != nil {
				slog.Debug("socket write error", "error", err)
			}
		}

		_ = conn.Close()
	}
}

func sendCommand(cfg Config, cmd string) (string, error) {
	conn, err := net.DialTimeout("unix", cfg.SocketPath(), 2*time.Second)
	if err != nil {
		return "", err
	}
	defer func() { _ = conn.Close() }()

	if err := setDeadline(conn, 2*time.Second); err != nil {
		return "", err
	}

	if _, err := conn.Write([]byte(cmd)); err != nil {
		return "", err
	}

	buf := make([]byte, 4096)

	n, err := conn.Read(buf)
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(buf[:n])), nil
}

func (d *Daemon) Run() {
	err := os.MkdirAll(d.config.StateDir, 0o755)
	if err != nil {
		slog.Error("failed to create state dir", "error", err)
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
		err := d.listenUnix()
		if err != nil {
			slog.Error("unix socket error", "error", err)
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
		d.autoManage()
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

		fmt.Println(resp)

		return
	}

	d := NewDaemon(cfg)
	d.Run()
}
