package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"

	"github.com/vishen/go-chromecast"
)

const (
	nestIP       = "192.168.1.150"
	streamPort   = 9000
	streamPath   = "/stream.mp3"
	streamPathFS  = "/stream.mp3"
)

func main() {
	// Get local IP
	localIP := getLocalIP()
	if localIP == "" {
		log.Fatal("Could not determine local IP")
	}

	streamURL := fmt.Sprintf("http://%s:%d%s", localIP, streamPort, streamPath)

	fmt.Println("🎵 System Audio Streamer → Nest Audio")
	fmt.Println("========================================")
	fmt.Printf("Nest Audio: %s\n", nestIP)
	fmt.Printf("Stream URL: %s\n", streamURL)
	fmt.Println()
	fmt.Println("Starting in 3 seconds... (Ctrl+C to stop)")
	time.Sleep(3 * time.Second)

	// Create FIFO for streaming audio
	fifoPath := "/tmp/audio-stream.fifo"
	if err := createFIFO(fifoPath); err != nil {
		log.Fatalf("Failed to create FIFO: %v", err)
	}
	defer os.Remove(fifoPath)

	// Start ffmpeg to capture and encode audio
	ffmpegCmd := startFFMPEG(fifoPath)
	defer func() {
		if ffmpegCmd.Process != nil {
			ffmpegCmd.Process.Kill()
		}
	}()

	// Give ffmpeg time to start
	time.Sleep(2 * time.Second)

	// Start HTTP server
	http.HandleFunc(streamPath, streamHandler(fifoPath))
	go func() {
		fmt.Printf("🌐 HTTP server on port %d\n", streamPort)
		log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", streamPort), nil))
	}()

	time.Sleep(2 * time.Second)

	// Cast to Nest Audio
	fmt.Println("📻 Casting to Nest Audio...")
	fmt.Println("   Play something to hear it on the speaker")
	fmt.Println()

	if err := castToNestAudio(streamURL); err != nil {
		log.Printf("Casting failed: %v", err)
	} else {
		fmt.Println("✓ Successfully casting!")
	}

	// Wait for interrupt
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan
	fmt.Println("\n🛑 Stopping...")
}

func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return ""
	}
	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return ""
}

func createFIFO(path string) error {
	if err := exec.Command("mkfifo", path).Run(); err != nil {
		return err
	}
	return nil
}

func startFFMPEG(fifoPath string) *exec.Cmd {
	cmd := exec.Command("ffmpeg",
		"-hide_banner",
		"-loglevel", "error",
		"-f", "s16le",
		"-ar", "44100",
		"-ac", "2",
		"-i", "-", // Read from stdin
		"-codec:a", "libmp3lame",
		"-b:a", "128k",
		"-f", "mp3",
		"-flush_packets", "1",
		fifoPath,
	)

	// Pipe PipeWire audio into ffmpeg
	pwCmd := exec.Command("pw-record",
		"--format=s16le",
		"--rate=44100",
		"--channels=2",
		"--raw", "-",
	)

	pipe, err := pwCmd.StdoutPipe()
	if err != nil {
		log.Fatalf("Failed to create pipe: %v", err)
	}

	ffmpegCmd := cmd
	ffmpegCmd.Stdin = pipe

	if err := pwCmd.Start(); err != nil {
		log.Fatalf("Failed to start pw-record: %v", err)
	}
	if err := ffmpegCmd.Start(); err != nil {
		log.Fatalf("Failed to start ffmpeg: %v", err)
	}

	return ffmpegCmd
}

func streamHandler(fifoPath string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "audio/mpeg")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("Connection", "close")

		f, err := os.Open(fifoPath)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer f.Close()

		io.Copy(w, f)
	}
}

func castToNestAudio(streamURL string) error {
	ctx := context.Background()

	// Discover Chromecast devices
	chromecasts, err := chromecast.Discover(ctx)
	if err != nil {
		return fmt.Errorf("failed to discover devices: %w", err)
	}

	if len(chromecasts) == 0 {
		// Try direct connection
		return castDirectly(ctx, streamURL)
	}

	// Find Nest Audio
	var target *chromecast.Chromecast
	for _, cc := range chromecasts {
		fmt.Printf("Found device: %s at %s\n", cc.Name(), cc.Addr())
		if cc.Addr().String() == nestIP+":8008" {
			target = cc
		}
	}

	if target == nil {
		fmt.Println("Nest Audio not found via mDNS, trying direct connection...")
		return castDirectly(ctx, streamURL)
	}

	// Connect and cast
	if err := target.Connect(ctx); err != nil {
		return fmt.Errorf("failed to connect: %w", err)
	}
	defer target.Close()

	if err := target.Load(ctx, streamURL, "audio/mpeg"); err != nil {
		return fmt.Errorf("failed to load media: %w", err)
	}

	return nil
}

func castDirectly(ctx context.Context, streamURL string) error {
	// Direct connection to known IP
	cc, err := chromecast.NewChromecast(ctx, nestIP+":8008")
	if err != nil {
		return fmt.Errorf("failed to connect to %s: %w", nestIP, err)
	}
	defer cc.Close()

	if err := cc.Load(ctx, streamURL, "audio/mpeg"); err != nil {
		return fmt.Errorf("failed to load media: %w", err)
	}

	return nil
}
