package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"os"
)

func main() {
	socketPath := "/run/emeet-pixyd/control.sock"
	addr := "127.0.0.1:8090"

	if envSocket := os.Getenv("PIXYD_SOCKET"); envSocket != "" {
		socketPath = envSocket
	}

	if envAddr := os.Getenv("PIXYD_WEB_ADDR"); envAddr != "" {
		addr = envAddr
	}

	srv := newServer(socketPath)

	mux := http.NewServeMux()

	mux.HandleFunc("GET /", srv.handleIndex)
	mux.HandleFunc("GET /panel", srv.handleStatusPanel)

	mux.HandleFunc("POST /api/track", srv.action("track"))
	mux.HandleFunc("POST /api/idle", srv.action("idle"))
	mux.HandleFunc("POST /api/privacy", srv.action("privacy"))
	mux.HandleFunc("POST /api/toggle-privacy", srv.action("toggle-privacy"))
	mux.HandleFunc("POST /api/audio", srv.handleAudio)
	mux.HandleFunc("POST /api/gesture", srv.handleGestureToggle)
	mux.HandleFunc("POST /api/auto", srv.handleAutoToggle)
	mux.HandleFunc("POST /api/center", srv.action("center"))
	mux.HandleFunc("POST /api/sync", srv.action("sync"))
	mux.HandleFunc("POST /api/probe", srv.action("probe"))
	mux.HandleFunc("POST /api/ptz/{axis}", srv.handlePTZ)
	mux.HandleFunc("GET /api/snapshot", srv.handleSnapshot)
	mux.HandleFunc("GET /api/stream", srv.handleStream)

	slog.Info("EMEET PIXY web UI starting", "addr", addr, "socket", socketPath)

	err := http.ListenAndServe(addr, mux)
	if err != nil {
		fmt.Fprintf(os.Stderr, "server error: %v\n", err)
		os.Exit(1)
	}
}
