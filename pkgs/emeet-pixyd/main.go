//go:build linux

package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/coreos/go-systemd/v22/daemon"
	"github.com/larsartmann/systemnix/emeet-pixyd/internal/pixy"
)

const (
	pixyVendorID  = "328f"
	pixyProductID = "00c0"
)

var errDeadline = errors.New("deadline error")

type Daemon struct {
	mu        sync.RWMutex
	state     pixy.State
	config    pixy.Config
	videoDev  string
	hidrawDev string

	debounceInUse int
	debounceIdle  int
	lastSyncedAt  time.Time
}

func NewDaemon(cfg pixy.Config) *Daemon {
	d := &Daemon{
		mu:            sync.RWMutex{},
		config:        cfg,
		state:         pixy.DefaultState(),
		videoDev:      "",
		hidrawDev:     "",
		debounceInUse: 0,
		debounceIdle:  0,
	}
	d.loadState()
	d.probeDevices()

	return d
}

func probeVideo4linux(sysfsPath string) string {
	entries, err := os.ReadDir(sysfsPath)
	if err != nil {
		return ""
	}

	for _, entry := range entries {
		name := entry.Name()

		videoPath := fmt.Sprintf("/dev/%s", name)

		vendorFile := fmt.Sprintf("%s/%s/device/id/vendor", sysfsPath, name)
		productFile := fmt.Sprintf("%s/%s/device/id/product", sysfsPath, name)

		vendorData, vErr := os.ReadFile(vendorFile)
		if vErr != nil {
			continue
		}

		productData, pErr := os.ReadFile(productFile)
		if pErr != nil {
			continue
		}

		vendor := strings.TrimSpace(string(vendorData))
		product := strings.TrimSpace(string(productData))

		if vendor == pixyVendorID && product == pixyProductID {
			return videoPath
		}
	}

	return ""
}

func probeHidraw(sysfsPath string) string {
	entries, err := os.ReadDir(sysfsPath)
	if err != nil {
		return ""
	}

	for _, entry := range entries {
		name := entry.Name()

		hidrawPath := fmt.Sprintf("/dev/%s", name)

		ueventFile := fmt.Sprintf("%s/%s/device/uevent", sysfsPath, name)

		ueventData, uErr := os.ReadFile(ueventFile)
		if uErr != nil {
			continue
		}

		for line := range strings.SplitSeq(string(ueventData), "\n") {
			if strings.HasPrefix(line, "HID_NAME=") {
				hidName := strings.TrimPrefix(line, "HID_NAME=")

				if strings.Contains(hidName, "EMEET") || strings.Contains(hidName, "Pixy") ||
					strings.Contains(hidName, "PIXY") {
					return hidrawPath
				}
			}
		}
	}

	return ""
}

func (d *Daemon) probeDevices() {
	d.videoDev = probeVideo4linux("/sys/class/video4linux")
	d.hidrawDev = probeHidraw("/sys/class/hidraw")

	if d.videoDev != "" && d.hidrawDev != "" {
		slog.Info("found PIXY device", "video", d.videoDev, "hidraw", d.hidrawDev)

		if d.state.Camera == pixy.StateOffline {
			d.state.Camera = pixy.StatePrivacy
		}
	} else {
		d.state.Camera = pixy.StateOffline
	}
}

func (d *Daemon) loadState() {
	data, err := os.ReadFile(d.config.StateFile())
	if err != nil {
		return
	}

	var loaded pixy.State

	if jsonErr := json.Unmarshal(data, &loaded); jsonErr != nil {
		slog.Warn("failed to parse state file, using defaults", "path", d.config.StateFile(), "error", jsonErr)

		return
	}

	d.state = loaded
}

func (d *Daemon) ensureStateDir() error {
	return os.MkdirAll(d.config.StateDir, pixy.PermissionStateDir)
}

func (d *Daemon) saveState() error {
	if err := d.ensureStateDir(); err != nil {
		return err
	}

	data, err := json.Marshal(d.state)
	if err != nil {
		return fmt.Errorf("marshal state: %w", err)
	}

	return os.WriteFile(d.config.StateFile(), data, pixy.PermissionStateFile)
}

func (d *Daemon) isDevicePresent() bool {
	return d.videoDev != ""
}

type stateSetter func(d *Daemon)

func (d *Daemon) requireDevice(context string) error {
	if !d.isDevicePresent() {
		return fmt.Errorf("%s: %w", context, pixy.ErrPIXYNotConnected)
	}

	return nil
}

func (d *Daemon) setDeviceState(configBytes, commitBytes []byte, setter stateSetter) error {
	if err := d.requireDevice("setDeviceState"); err != nil {
		return err
	}

	err := hidSend(d.hidrawDev, configBytes)
	if err != nil {
		d.probeDevices()

		return fmt.Errorf("setDeviceState send config: %w", err)
	}

	time.Sleep(hidCommandSleepMs * time.Millisecond)

	err = hidSend(d.hidrawDev, commitBytes)
	if err != nil {
		return fmt.Errorf("setDeviceState send commit: %w", err)
	}

	setter(d)

	saveErr := d.saveState()
	if saveErr != nil {
		slog.Error("failed to save state", "error", saveErr)
	}

	return nil
}

func (d *Daemon) setTracking(mode pixy.CameraState) error {
	return d.setDeviceState(
		pixyConfig(hidInterfaceTracking, cameraHIDByte(mode)),
		pixyCommit(hidInterfaceTracking),
		func(d *Daemon) { d.state.Camera = mode },
	)
}

func (d *Daemon) setAudio(mode pixy.AudioMode) error {
	return d.setDeviceState(
		pixyConfig(hidInterfaceAudio, audioHIDByte(mode)),
		pixyCommit(hidInterfaceAudio),
		func(d *Daemon) { d.state.Audio = mode },
	)
}

func (d *Daemon) setGesture(enabled bool) error {
	var mark byte = hidByteIdle
	if enabled {
		mark = gestureEnabledByte
	}

	return d.setDeviceState(
		pixyConfig(hidInterfaceGesture, mark),
		pixyCommit(hidInterfaceGesture),
		func(d *Daemon) { d.state.Gesture = enabled },
	)
}

func (d *Daemon) centerCamera(ctx context.Context) error {
	if err := d.requireDevice("centerCamera"); err != nil {
		return err
	}

	if err := v4l2Set(ctx, d.videoDev, "pan_absolute", "0"); err != nil {
		return fmt.Errorf("centerCamera pan: %w", err)
	}

	if err := v4l2Set(ctx, d.videoDev, "tilt_absolute", "0"); err != nil {
		return fmt.Errorf("centerCamera tilt: %w", err)
	}

	err := v4l2Set(ctx, d.videoDev, "zoom_absolute", "100")
	if err != nil {
		return fmt.Errorf("centerCamera zoom: %w", err)
	}

	return nil
}

func (d *Daemon) queryTracking(ctx context.Context) (pixy.CameraState, error) {
	return queryHIDState(
		ctx,
		d.hidrawDev,
		[]byte{cameraConfigPrefix, hidInterfaceTracking, 0x01, 0x01},
		func(p hidResponse) pixy.CameraState { return p.Tracking },
	)
}

func (d *Daemon) queryAudio(ctx context.Context) (pixy.AudioMode, error) {
	return queryHIDState(
		ctx,
		d.hidrawDev,
		[]byte{cameraConfigPrefix, hidInterfaceAudio, audioConfigMarker, 0x04},
		func(p hidResponse) pixy.AudioMode { return p.Audio },
	)
}

func (d *Daemon) queryGesture(ctx context.Context) (bool, error) {
	return queryHIDState(
		ctx,
		d.hidrawDev,
		[]byte{
			cameraConfigPrefix, hidInterfaceGesture,
			gestureConfigMark1, gestureConfigMark2,
			0x00, cameraConfigMarker,
			0x00, cameraConfigMarker,
			gestureConfigMark3,
		},
		func(p hidResponse) bool { return p.Gesture },
	)
}

func (d *Daemon) syncState(ctx context.Context) string {
	if !d.isDevicePresent() {
		return "error: PIXY not connected"
	}

	changed := false

	tracking, trackingErr := d.queryTracking(ctx)
	if trackingErr == nil && tracking.Valid() && tracking != pixy.StateOffline {
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
	} else {
		slog.Debug("gesture query failed", "error", gestureErr)
	}

	if changed {
		saveErr := d.saveState()
		if saveErr != nil {
			slog.Error("failed to save synced state", "error", saveErr)
		}

		d.lastSyncedAt = time.Now()

		return "synced (state updated from camera)"
	}

	d.lastSyncedAt = time.Now()

	return "synced (no changes)"
}

func boolStr(b bool, ifTrue, ifFalse string) string {
	if b {
		return ifTrue
	}
	return ifFalse
}

func sdNotify(state string) {
	sent, err := daemon.SdNotify(false, state)
	if err != nil {
		slog.Debug("sd_notify failed", "error", err)
	} else if !sent {
		slog.Debug("sd_notify not sent (no NOTIFY_SOCKET)")
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
		if d.state.Camera == pixy.StatePrivacy || d.state.Camera == pixy.StateIdle {
			trackErr := d.setTracking(pixy.StateTracking)
			if trackErr != nil {
				slog.Error("failed to activate tracking", "error", trackErr)
			}
		}

		if d.state.Audio != pixy.AudioNC {
			audioErr := d.setAudio(pixy.AudioNC)
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

		privacyErr := d.setTracking(pixy.StatePrivacy)
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
		return fmt.Sprintf(
			"camera=%s audio=%s gesture=%v pan=%d tilt=%d zoom=%d in_call=%s auto=%s device=",
			pixy.StateOffline,
			d.state.Audio,
			d.state.Gesture,
			0,
			0,
			0,
			boolStr(d.state.InCall, "yes", "no"),
			boolStr(d.state.AutoMode, "on", "off"),
		)
	}

	ptz := parsePTZValues(ctx, d.videoDev)

	return fmt.Sprintf(
		"camera=%s audio=%s gesture=%v pan=%d tilt=%d zoom=%d in_call=%s auto=%s device=%s",
		d.state.Camera,
		d.state.Audio,
		d.state.Gesture,
		ptz.Pan,
		ptz.Tilt,
		ptz.Zoom,
		boolStr(d.state.InCall, "yes", "no"),
		boolStr(d.state.AutoMode, "on", "off"),
		d.videoDev,
	)
}

func (d *Daemon) waybarOutput() string {
	icon := ""
	class := ""
	text := ""

	switch d.state.Camera {
	case pixy.StateTracking:
		icon = "\uf030"
		class = "tracking"
		text = "CAM"
	case pixy.StatePrivacy:
		icon = "\uf011"
		class = "privacy"
		text = "OFF"
	case pixy.StateIdle:
		icon = "\uf03d"
		class = "idle"
		text = "IDLE"
	case pixy.StateOffline:
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

	createErr := os.MkdirAll(d.config.StateDir, pixy.PermissionStateDir)
	if createErr != nil {
		return fmt.Errorf("create state dir: %w", createErr)
	}

	lc := net.ListenConfig{}

	listener, err := lc.Listen(ctx, "unix", socketPath)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}

	defer func() {
		closeErr := listener.Close()
		if closeErr != nil {
			slog.Debug("listener close error", "error", closeErr)
		}
	}()

	chmodErr := os.Chmod(socketPath, pixy.PermissionSocket)
	if chmodErr != nil {
		slog.Error("failed to set socket permissions", "error", chmodErr)
	}

	for {
		conn, err := listener.Accept()
		if err != nil {
			select {
			case <-ctx.Done():
				return nil
			default:
			}
			slog.Error("socket accept error", "error", err)

			continue
		}

		buf := make([]byte, pixy.SocketBufSize)

		n, readErr := conn.Read(buf)
		if readErr == nil && n > 0 {
			cmd := strings.TrimSpace(string(buf[:n]))

			response := d.handleCommand(ctx, cmd) + "\n"

			_, writeErr := conn.Write([]byte(response))
			if writeErr != nil {
				slog.Debug("socket write error", "error", writeErr)
			}
		}

		closeErr := conn.Close()
		if closeErr != nil {
			slog.Debug("conn close error", "error", closeErr)
		}
	}
}

func sendCommand(cfg pixy.Config, cmd string) (string, error) {
	resp, err := pixy.SendCommand(context.Background(), cfg.SocketPath(), cmd)
	if err != nil {
		return "", fmt.Errorf("sendCommand %q: %w", cmd, err)
	}

	return resp, nil
}

func (d *Daemon) Run() {
	createErr := os.MkdirAll(d.config.StateDir, pixy.PermissionStateDir)
	if createErr != nil {
		slog.Error("failed to create state dir", "error", createErr)
	}

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		listenErr := d.listenUnix(ctx)
		if listenErr != nil {
			slog.Error("unix socket error", "error", listenErr)
		}
	}()

	var httpSrv *http.Server
	if d.config.WebAddr != "" {
		webSrv := &webServer{daemon: d}
		mux := newWebMux(webSrv)
		httpSrv = &http.Server{
			Addr:              d.config.WebAddr,
			Handler:           mux,
			ReadHeaderTimeout: 5 * time.Second,
			ReadTimeout:       10 * time.Second,
			WriteTimeout:      30 * time.Second,
			IdleTimeout:       60 * time.Second,
			MaxHeaderBytes:    1 << 20,
		}

		go func() {
			slog.Info("web UI starting", "addr", d.config.WebAddr)
			listenErr := httpSrv.ListenAndServe()
			if listenErr != nil && listenErr != http.ErrServerClosed {
				slog.Error("web server error", "error", listenErr)
			}
		}()
	}

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

	for {
		select {
		case <-sigs:
			sdNotify("STOPPING=1")
			slog.Info("shutting down")
			d.mu.Lock()
			if saveErr := d.saveState(); saveErr != nil {
				slog.Error("failed to save state on shutdown", "error", saveErr)
			}
			d.mu.Unlock()
			cancel()
			_ = os.Remove(d.config.SocketPath())
			if httpSrv != nil {
				shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
				_ = httpSrv.Shutdown(shutdownCtx)
				cancel()
			}
			return
		case <-ticker.C:
			d.autoManage(context.Background())
			sdNotify("WATCHDOG=1")
		}
	}
}

func exitWithDaemonError(err error) {
	if err != nil {
		_, dieErr := fmt.Fprintf(os.Stderr, "Error: %v\nIs emeet-pixyd running?\n", err)
		_ = dieErr
		os.Exit(1)
	}
}

func main() {
	cfg := pixy.DefaultConfig()

	if len(os.Args) > 1 {
		cmd := strings.Join(os.Args[1:], " ")

		resp, err := sendCommand(cfg, cmd)
		exitWithDaemonError(err)

		_, printErr := fmt.Fprintln(os.Stdout, resp)
		if printErr != nil {
			slog.Debug("failed to print response", "error", printErr)
		}

		return
	}

	d := NewDaemon(cfg)
	d.Run()
}
