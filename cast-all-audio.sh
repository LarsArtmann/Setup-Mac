#!/usr/bin/env bash
# Stream system audio to Google Nest Audio
# Usage: ./cast-all-audio.sh <nest-ip>

set -e

NEST_IP="${1:-192.168.1.150}"
LOCAL_IP=$(hostname -I | awk '{print $1}')
STREAM_PORT=9000
STREAM_URL="http://${LOCAL_IP}:${STREAM_PORT}/stream.mp3"

echo "🎵 System Audio Streamer → Nest Audio (${NEST_IP})"
echo "=================================================="
echo "Stream URL: ${STREAM_URL}"
echo ""
echo "Starting in 3 seconds... (Ctrl+C to stop)"
sleep 3

# Cleanup
cleanup() {
    echo ""
    echo "🛑 Stopping..."
    kill ${FFMPEG_PID} 2>/dev/null || true
    kill ${SERVER_PID} 2>/dev/null || true
    rm -f "${FIFO}"
    exit 0
}
trap cleanup SIGINT SIGTERM

# Create FIFO
FIFO=$(mktemp -u)
mkfifo "${FIFO}"

# Start HTTP server (serves the FIFO as MP3 stream)
echo "🌐 Starting HTTP server on port ${STREAM_PORT}..."
( cd "$(dirname "${FIFO}")" && python3 -m http.server "${STREAM_PORT}" ) &
SERVER_PID=$!

sleep 2

# Start ffmpeg to capture and encode audio
echo "🎙️  Capturing system audio (PipeWire → MP3)..."
echo "   Play something on your system to hear it on Nest Audio"

# PipeWire capture → ffmpeg MP3 encoding → FIFO
pw-record --format=s16le --rate=44100 --channels=2 --raw - 2>/dev/null | \
ffmpeg -hide_banner -loglevel error \
    -f s16le -ar 44100 -ac 2 -i - \
    -codec:a libmp3lame -b:a 128k \
    -f mp3 \
    -flush_packets 1 \
    "${FIFO}" 2>/dev/null &

FFMPEG_PID=$!

sleep 2

# Cast to Nest Audio using castnow
echo "📻 Casting to Nest Audio..."
echo "   Press Ctrl+C to stop"
echo ""

# Use castnow with the HTTP stream URL
castnow --address "${NEST_IP}" --quiet "${STREAM_URL}"

cleanup
