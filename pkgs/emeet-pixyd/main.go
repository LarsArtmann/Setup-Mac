package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"
)

const (
	stateDir    = "/run/user/emeet-pixyd"
	stateFile   = stateDir + "/state.json"
	socketPath  = stateDir + "/control.sock"
	pollInterval = 3 * time.Second

	videoDevice = "/dev/video0"
)

type CameraState string

const (
	StateIdle     CameraState = "idle"
	StateTracking CameraState = "tracking"
	StatePrivacy  CameraState = "privacy"
)

type AudioMode string

const (
	AudioNC       AudioMode = "nc"
	AudioLive     AudioMode = "live"
	AudioOriginal AudioMode = "original"
)

type State struct {
	Camera    CameraState `json:"camera"`
	Audio     AudioMode   `json:"audio"`
	Gesture   bool        `json:"gesture"`
	InCall    bool        `json:"in_call"`
	AutoMode  bool        `json:"auto_mode"`
}

type Daemon struct {
	state     State
	stateFile string
}

func NewDaemon() *Daemon {
	d := &Daemon{
		stateFile: stateFile,
		state: State{
			Camera:   StateIdle,
			Audio:    AudioNC,
			Gesture:  false,
			InCall:   false,
			AutoMode: true,
		},
	}
	d.loadState()
	return d
}

func (d *Daemon) loadState() {
	data, err := os.ReadFile(d.stateFile)
	if err != nil {
		return
	}
	json.Unmarshal(data, &d.state)
}

func (d *Daemon) saveState() error {
	os.MkdirAll(stateDir, 0755)
	data, err := json.Marshal(d.state)
	if err != nil {
		return err
	}
	return os.WriteFile(d.stateFile, data, 0644)
}

func findHIDRaw() (string, error) {
	entries, err := os.ReadDir("/sys/class/hidraw")
	if err != nil {
		return "", fmt.Errorf("no hidraw devices: %w", err)
	}
	for _, entry := range entries {
		ueventPath := filepath.Join("/sys/class/hidraw", entry.Name(), "device/uevent")
		data, err := os.ReadFile(ueventPath)
		if err != nil {
			continue
		}
		content := string(data)
		if strings.Contains(content, "EMEET") && strings.Contains(content, "PIXY") {
			return filepath.Join("/dev", entry.Name()), nil
		}
	}
	return "", fmt.Errorf("EMEET PIXY HID device not found")
}

func hidSend(report []byte) error {
	hidraw, err := findHIDRaw()
	if err != nil {
		return err
	}
	buf := make([]byte, 32)
	copy(buf, report)
	f, err := os.OpenFile(hidraw, os.O_WRONLY, 0)
	if err != nil {
		return fmt.Errorf("open hidraw: %w", err)
	}
	defer f.Close()
	_, err = f.Write(buf)
	return err
}

func v4l2Set(ctrl, value string) error {
	cmd := exec.Command("v4l2-ctl", "-d", videoDevice, "--set-ctrl="+ctrl+"="+value)
	return cmd.Run()
}

func v4l2Get(ctrl string) (string, error) {
	cmd := exec.Command("v4l2-ctl", "-d", videoDevice, "--get-ctrl="+ctrl)
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	parts := strings.Split(strings.TrimSpace(string(out)), ":")
	if len(parts) == 2 {
		return strings.TrimSpace(parts[1]), nil
	}
	return strings.TrimSpace(string(out)), nil
}

func (d *Daemon) setTracking(mode CameraState) error {
	var modeByte byte
	switch mode {
	case StateIdle:
		modeByte = 0x00
	case StateTracking:
		modeByte = 0x01
	case StatePrivacy:
		modeByte = 0x02
	default:
		modeByte = 0x00
	}
	if err := hidSend([]byte{0x09, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, modeByte}); err != nil {
		return err
	}
	time.Sleep(200 * time.Millisecond)
	if err := hidSend([]byte{0x09, 0x01, 0x01, 0x01}); err != nil {
		return err
	}
	d.state.Camera = mode
	d.saveState()
	return nil
}

func (d *Daemon) setAudio(mode AudioMode) error {
	var modeByte byte
	switch mode {
	case AudioNC:
		modeByte = 0x01
	case AudioLive:
		modeByte = 0x02
	case AudioOriginal:
		modeByte = 0x03
	default:
		modeByte = 0x01
	}
	if err := hidSend([]byte{0x09, 0x05, 0x00, 0x03, 0x00, 0x01, 0x00, 0x01, modeByte}); err != nil {
		return err
	}
	time.Sleep(200 * time.Millisecond)
	if err := hidSend([]byte{0x09, 0x05, 0x00, 0x04}); err != nil {
		return err
	}
	d.state.Audio = mode
	d.saveState()
	return nil
}

func (d *Daemon) setGesture(enabled bool) error {
	var modeByte byte
	if enabled {
		modeByte = 0x01
	}
	if err := hidSend([]byte{0x09, 0x04, 0x02, 0x00, 0x00, 0x02, 0x00, 0x02, 0x02, modeByte}); err != nil {
		return err
	}
	time.Sleep(200 * time.Millisecond)
	if err := hidSend([]byte{0x09, 0x04, 0x02, 0x01, 0x00, 0x01, 0x00, 0x01, 0x02}); err != nil {
		return err
	}
	d.state.Gesture = enabled
	d.saveState()
	return nil
}

func (d *Daemon) centerCamera() error {
	if err := v4l2Set("pan_absolute", "0"); err != nil {
		return err
	}
	if err := v4l2Set("tilt_absolute", "0"); err != nil {
		return err
	}
	if err := v4l2Set("zoom_absolute", "100"); err != nil {
		return err
	}
	return nil
}

func (d *Daemon) getStatus() string {
	pan, _ := v4l2Get("pan_absolute")
	tilt, _ := v4l2Get("tilt_absolute")
	zoom, _ := v4l2Get("zoom_absolute")

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

	return fmt.Sprintf("camera=%s audio=%s gesture=%v pan=%d tilt=%d zoom=%d in_call=%s auto=%s",
		d.state.Camera, d.state.Audio, d.state.Gesture, panDeg, tiltDeg, zoomVal, inCallStr, autoStr)
}

var callProcessPatterns = []*regexp.Regexp{
	regexp.MustCompile(`(?i)(zoom|teams|webex|skype|discord|google.meet|hangout|jitsi|slack.call|meet\.google|whereby|gather\.town)`),
}

var callURLPatterns = []*regexp.Regexp{
	regexp.MustCompile(`meet\.google\.com`),
	regexp.MustCompile(`zoom\.us/j/`),
	regexp.MustCompile(`teams\.microsoft\.com/l/meet`),
	regexp.MustCompile(`discord\.com/channels`),
	regexp.MustCompile(`app\.gather\.town`),
}

func (d *Daemon) detectVideoCall() bool {
	// Check active window title via niri
	cmd := exec.Command("niri", "msg", "focused-window")
	out, err := cmd.Output()
	if err != nil {
		return false
	}
	title := strings.ToLower(string(out))

	// Check window title for known call apps/URLs
	for _, p := range callProcessPatterns {
		if p.MatchString(title) {
			return true
		}
	}

	// Check for browser tabs with video call URLs
	for _, p := range callURLPatterns {
		if p.MatchString(title) {
			return true
		}
	}

	// Check pipewire for active video streams from the camera
	cmd = exec.Command("pw-cli", "dump", "short")
	out, err = cmd.Output()
	if err == nil {
		output := string(out)
		if strings.Contains(output, "EMEET") || strings.Contains(output, "emeet") {
			// If there are active links involving the device, a call is likely active
			if strings.Contains(output, "Video") || strings.Contains(output, "video") {
				return true
			}
		}
	}

	return false
}

func (d *Daemon) autoManage() {
	if !d.state.AutoMode {
		return
	}

	inCall := d.detectVideoCall()

	if inCall && !d.state.InCall {
		log.Println("Video call detected — activating tracking + noise cancellation")
		d.state.InCall = true
		if d.state.Camera == StatePrivacy {
			d.setTracking(StateTracking)
		} else if d.state.Camera == StateIdle {
			d.setTracking(StateTracking)
		}
		if d.state.Audio != AudioNC {
			d.setAudio(AudioNC)
		}
	} else if !inCall && d.state.InCall {
		log.Println("Video call ended — entering privacy mode")
		d.state.InCall = false
		d.setTracking(StatePrivacy)
	}

	d.saveState()
}

func (d *Daemon) handleCommand(cmd string) string {
	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		return d.getStatus()
	}

	switch parts[0] {
	case "status":
		return d.getStatus()

	case "track":
		if err := d.setTracking(StateTracking); err != nil {
			return "error: " + err.Error()
		}
		return "tracking on"

	case "idle":
		if err := d.setTracking(StateIdle); err != nil {
			return "error: " + err.Error()
		}
		return "tracking off"

	case "privacy":
		if err := d.setTracking(StatePrivacy); err != nil {
			return "error: " + err.Error()
		}
		return "privacy on"

	case "toggle-privacy":
		newState := StatePrivacy
		if d.state.Camera == StatePrivacy {
			newState = StateTracking
		}
		if err := d.setTracking(newState); err != nil {
			return "error: " + err.Error()
		}
		if newState == StatePrivacy {
			return "privacy on"
		}
		return "tracking on"

	case "audio":
		if len(parts) < 2 {
			return "usage: audio nc|live|org"
		}
		var mode AudioMode
		switch parts[1] {
		case "nc":
			mode = AudioNC
		case "live":
			mode = AudioLive
		case "org":
			mode = AudioOriginal
		default:
			return "usage: audio nc|live|org"
		}
		if err := d.setAudio(mode); err != nil {
			return "error: " + err.Error()
		}
		return "audio: " + string(mode)

	case "gesture-on":
		if err := d.setGesture(true); err != nil {
			return "error: " + err.Error()
		}
		return "gesture on"

	case "gesture-off":
		if err := d.setGesture(false); err != nil {
			return "error: " + err.Error()
		}
		return "gesture off"

	case "center":
		if err := d.centerCamera(); err != nil {
			return "error: " + err.Error()
		}
		return "centered"

	case "auto-on":
		d.state.AutoMode = true
		d.saveState()
		return "auto mode on"

	case "auto-off":
		d.state.AutoMode = false
		d.saveState()
		return "auto mode off"

	case "waybar":
		return d.waybarOutput()

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
		icon = "\U0001f4f7"
		class = "tracking"
		text = "CAM"
	case StatePrivacy:
		icon = "\U0001f6ab"
		class = "privacy"
		text = "OFF"
	case StateIdle:
		icon = "\U0001f4f9"
		class = "idle"
		text = "IDLE"
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
	data, _ := json.Marshal(out)
	return string(data)
}

func (d *Daemon) listenUnix() error {
	os.Remove(socketPath)
	os.MkdirAll(stateDir, 0755)

	listener, err := syscall.Socket(syscall.AF_UNIX, syscall.SOCK_STREAM, 0)
	if err != nil {
		return err
	}
	defer syscall.Close(listener)

	addr := &syscall.SockaddrUnix{Name: socketPath}
	if err := syscall.Bind(listener, addr); err != nil {
		return err
	}
	os.Chmod(socketPath, 0666)
	syscall.Listen(listener, 5)

	buf := make([]byte, 256)
	for {
		nfd, _, err := syscall.Accept(listener)
		if err != nil {
			continue
		}
		n, _, err := syscall.Recvfrom(nfd, buf, 0)
		if err == nil && n > 0 {
			cmd := strings.TrimSpace(string(buf[:n]))
			response := d.handleCommand(cmd) + "\n"
			syscall.Write(nfd, []byte(response))
		}
		syscall.Close(nfd)
	}
}

func sendCommand(cmd string) (string, error) {
	fd, err := syscall.Socket(syscall.AF_UNIX, syscall.SOCK_STREAM, 0)
	if err != nil {
		return "", err
	}
	defer syscall.Close(fd)

	addr := &syscall.SockaddrUnix{Name: socketPath}
	if err := syscall.Connect(fd, addr); err != nil {
		return "", err
	}
	syscall.Write(fd, []byte(cmd))

	buf := make([]byte, 4096)
	n, err := syscall.Read(fd, buf)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(buf[:n])), nil
}

func (d *Daemon) Run() {
	os.MkdirAll(stateDir, 0755)

	// Clean up on exit
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		os.Remove(socketPath)
		os.Remove(stateFile)
		os.Exit(0)
	}()

	// Start unix socket listener in background
	go func() {
		if err := d.listenUnix(); err != nil {
			log.Printf("Unix socket error: %v", err)
		}
	}()

	log.Println("EMEET PIXY daemon started")
	log.Printf("State: camera=%s audio=%s auto=%v", d.state.Camera, d.state.Audio, d.state.AutoMode)

	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	for range ticker.C {
		d.autoManage()
	}
}

func main() {
	if len(os.Args) > 1 {
		// Client mode: send command to running daemon
		cmd := strings.Join(os.Args[1:], " ")
		resp, err := sendCommand(cmd)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\nIs emeet-pixyd running?\n", err)
			os.Exit(1)
		}
		fmt.Println(resp)
		return
	}

	// Daemon mode
	d := NewDaemon()
	d.Run()
}
