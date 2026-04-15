package main

import (
	"encoding/json"
	"fmt"
	"log"
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
	stateDir     = "/run/emeet-pixyd"
	stateFile    = stateDir + "/state.json"
	socketPath   = stateDir + "/control.sock"
	pollInterval  = 2 * time.Second
	debounceCount = 3

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

type AudioMode string

const (
	AudioNC       AudioMode = "nc"
	AudioLive     AudioMode = "live"
	AudioOriginal AudioMode = "original"
)

type State struct {
	Camera   CameraState `json:"camera"`
	Audio    AudioMode   `json:"audio"`
	Gesture  bool        `json:"gesture"`
	InCall   bool        `json:"in_call"`
	AutoMode bool        `json:"auto_mode"`
}

type Daemon struct {
	mu        sync.Mutex
	state     State
	stateFile string
	videoDev  string
	hidrawDev string

	debounceInUse int
	debounceIdle  int
}

func NewDaemon() *Daemon {
	d := &Daemon{
		stateFile: stateFile,
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
		log.Printf("Found PIXY: video=%s hidraw=%s", d.videoDev, d.hidrawDev)
	} else {
		d.state.Camera = StateOffline
		log.Println("PIXY not found — will retry on next probe")
	}
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

func (d *Daemon) isDevicePresent() bool {
	return d.videoDev != ""
}

func hidSend(hidrawDev string, report []byte) error {
	if hidrawDev == "" {
		return fmt.Errorf("PIXY HID device not available")
	}
	buf := make([]byte, 32)
	copy(buf, report)
	f, err := os.OpenFile(hidrawDev, os.O_WRONLY, 0)
	if err != nil {
		return fmt.Errorf("open hidraw: %w", err)
	}
	defer f.Close()
	_, err = f.Write(buf)
	return err
}

func v4l2Set(dev, ctrl, value string) error {
	cmd := exec.Command("v4l2-ctl", "-d", dev, "--set-ctrl="+ctrl+"="+value)
	return cmd.Run()
}

func v4l2Get(dev, ctrl string) (string, error) {
	cmd := exec.Command("v4l2-ctl", "-d", dev, "--get-ctrl="+ctrl)
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
	if !d.isDevicePresent() {
		return fmt.Errorf("PIXY not connected")
	}
	var modeByte byte
	switch mode {
	case StateTracking:
		modeByte = 0x01
	case StatePrivacy:
		modeByte = 0x02
	case StateIdle:
		modeByte = 0x00
	default:
		modeByte = 0x00
	}
	if err := hidSend(d.hidrawDev, []byte{0x09, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, modeByte}); err != nil {
		d.probeDevices()
		return err
	}
	time.Sleep(200 * time.Millisecond)
	if err := hidSend(d.hidrawDev, []byte{0x09, 0x01, 0x01, 0x01}); err != nil {
		return err
	}
	d.state.Camera = mode
	d.saveState()
	return nil
}

func (d *Daemon) setAudio(mode AudioMode) error {
	if !d.isDevicePresent() {
		return fmt.Errorf("PIXY not connected")
	}
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
	if err := hidSend(d.hidrawDev, []byte{0x09, 0x05, 0x00, 0x03, 0x00, 0x01, 0x00, 0x01, modeByte}); err != nil {
		d.probeDevices()
		return err
	}
	time.Sleep(200 * time.Millisecond)
	if err := hidSend(d.hidrawDev, []byte{0x09, 0x05, 0x00, 0x04}); err != nil {
		return err
	}
	d.state.Audio = mode
	d.saveState()
	return nil
}

func (d *Daemon) setGesture(enabled bool) error {
	if !d.isDevicePresent() {
		return fmt.Errorf("PIXY not connected")
	}
	var modeByte byte
	if enabled {
		modeByte = 0x01
	}
	if err := hidSend(d.hidrawDev, []byte{0x09, 0x04, 0x02, 0x00, 0x00, 0x02, 0x00, 0x02, 0x02, modeByte}); err != nil {
		d.probeDevices()
		return err
	}
	time.Sleep(200 * time.Millisecond)
	if err := hidSend(d.hidrawDev, []byte{0x09, 0x04, 0x02, 0x01, 0x00, 0x01, 0x00, 0x01, 0x02}); err != nil {
		return err
	}
	d.state.Gesture = enabled
	d.saveState()
	return nil
}

func (d *Daemon) centerCamera() error {
	if !d.isDevicePresent() {
		return fmt.Errorf("PIXY not connected")
	}
	if err := v4l2Set(d.videoDev, "pan_absolute", "0"); err != nil {
		return err
	}
	if err := v4l2Set(d.videoDev, "tilt_absolute", "0"); err != nil {
		return err
	}
	return v4l2Set(d.videoDev, "zoom_absolute", "100")
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
	cmd := exec.Command("wpctl", "status")
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	lines := strings.Split(string(out), "\n")
	for _, line := range lines {
		if strings.Contains(line, "EMEET") || strings.Contains(line, "Pixy") || strings.Contains(line, "PIXY") {
			fields := strings.Fields(line)
			for _, f := range fields {
				f = strings.TrimSuffix(f, ".")
				if _, err := strconv.Atoi(f); err == nil {
					return f, nil
				}
			}
		}
	}
	return "", fmt.Errorf("PIXY audio source not found")
}

func setDefaultSource(sourceID string) {
	exec.Command("wpctl", "set-default", sourceID).Run()
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

	if inUse && !d.state.InCall && d.debounceInUse >= debounceCount {
		log.Println("Camera in use (confirmed) — activating tracking + noise cancellation")
		d.state.InCall = true
		if d.state.Camera == StatePrivacy || d.state.Camera == StateIdle {
			d.setTracking(StateTracking)
		}
		if d.state.Audio != AudioNC {
			d.setAudio(AudioNC)
		}
		if src, err := findPixySource(); err == nil {
			setDefaultSource(src)
			log.Printf("Set PipeWire default source to PIXY (id=%s)", src)
		}
	} else if !inUse && d.state.InCall && d.debounceIdle >= debounceCount {
		log.Println("Camera released (confirmed) — entering privacy mode")
		d.state.InCall = false
		d.setTracking(StatePrivacy)
	}

	d.saveState()
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

	return fmt.Sprintf("camera=%s audio=%s gesture=%v pan=%d tilt=%d zoom=%d in_call=%s auto=%s",
		d.state.Camera, d.state.Audio, d.state.Gesture, panDeg, tiltDeg, zoomVal, inCallStr, autoStr)
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
	data, _ := json.Marshal(out)
	return string(data)
}

func (d *Daemon) listenUnix() error {
	os.Remove(socketPath)
	os.MkdirAll(stateDir, 0755)

	l, err := net.Listen("unix", socketPath)
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	defer l.Close()
	os.Chmod(socketPath, 0666)

	for {
		conn, err := l.Accept()
		if err != nil {
			log.Printf("Accept error: %v", err)
			continue
		}
		buf := make([]byte, 256)
		n, err := conn.Read(buf)
		if err == nil && n > 0 {
			cmd := strings.TrimSpace(string(buf[:n]))
			response := d.handleCommand(cmd) + "\n"
			conn.Write([]byte(response))
		}
		conn.Close()
	}
}

func sendCommand(cmd string) (string, error) {
	conn, err := net.DialTimeout("unix", socketPath, 2*time.Second)
	if err != nil {
		return "", err
	}
	defer conn.Close()
	conn.SetDeadline(time.Now().Add(2 * time.Second))
	conn.Write([]byte(cmd))

	buf := make([]byte, 4096)
	n, err := conn.Read(buf)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(buf[:n])), nil
}

func (d *Daemon) Run() {
	os.MkdirAll(stateDir, 0755)

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		os.Remove(socketPath)
		os.Remove(stateFile)
		os.Exit(0)
	}()

	go func() {
		if err := d.listenUnix(); err != nil {
			log.Fatalf("Unix socket error: %v", err)
		}
	}()

	log.Println("EMEET PIXY daemon started")
	d.mu.Lock()
	log.Printf("State: camera=%s audio=%s auto=%v", d.state.Camera, d.state.Audio, d.state.AutoMode)
	d.mu.Unlock()

	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	for range ticker.C {
		d.autoManage()
	}
}

func main() {
	if len(os.Args) > 1 {
		cmd := strings.Join(os.Args[1:], " ")
		resp, err := sendCommand(cmd)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\nIs emeet-pixyd running?\n", err)
			os.Exit(1)
		}
		fmt.Println(resp)
		return
	}

	d := NewDaemon()
	d.Run()
}
