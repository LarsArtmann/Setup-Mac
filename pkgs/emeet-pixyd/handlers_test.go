//go:build linux

package main

import (
	"bufio"
	"bytes"
	"testing"
	"time"
)

func TestExtractJPEGFrame_MinimalFrame(t *testing.T) {
	t.Parallel()

	data := []byte{0xFF, 0xD8, 0xFF, 0xD9}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := &bytes.Buffer{}

	frame, err := extractJPEGFrame(br, buf)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(frame) != 4 {
		t.Fatalf("expected 4 bytes, got %d", len(frame))
	}
	if frame[0] != 0xFF || frame[1] != 0xD8 {
		t.Errorf("missing SOI marker")
	}
	if frame[2] != 0xFF || frame[3] != 0xD9 {
		t.Errorf("missing EOI marker")
	}
}

func TestExtractJPEGFrame_FrameWithPayload(t *testing.T) {
	t.Parallel()

	data := []byte{0xFF, 0xD8, 0x42, 0x43, 0x44, 0xFF, 0xD9}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := &bytes.Buffer{}

	frame, err := extractJPEGFrame(br, buf)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if string(frame) != string(data) {
		t.Errorf("expected %x, got %x", data, frame)
	}
}

func TestExtractJPEGFrame_GarbageBeforeSOI(t *testing.T) {
	t.Parallel()

	data := []byte{0x00, 0x01, 0x02, 0xFF, 0xD8, 0xAA, 0xFF, 0xD9}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := &bytes.Buffer{}

	frame, err := extractJPEGFrame(br, buf)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := []byte{0xFF, 0xD8, 0xAA, 0xFF, 0xD9}
	if string(frame) != string(expected) {
		t.Errorf("expected %x, got %x", expected, frame)
	}
}

func TestExtractJPEGFrame_DoubleFFBeforeD8(t *testing.T) {
	t.Parallel()

	data := []byte{0xFF, 0xFF, 0xD8, 0x42, 0xFF, 0xD9}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := &bytes.Buffer{}

	frame, err := extractJPEGFrame(br, buf)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expected := []byte{0xFF, 0xD8, 0x42, 0xFF, 0xD9}
	if string(frame) != string(expected) {
		t.Errorf("expected %x, got %x", expected, frame)
	}
}

func TestExtractJPEGFrame_EmptyInput(t *testing.T) {
	t.Parallel()

	br := bufio.NewReader(bytes.NewReader(nil))
	buf := &bytes.Buffer{}

	_, err := extractJPEGFrame(br, buf)
	if err == nil {
		t.Fatal("expected error for empty input")
	}
}

func TestExtractJPEGFrame_NoEOI(t *testing.T) {
	t.Parallel()

	data := []byte{0xFF, 0xD8, 0x42, 0x43}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := &bytes.Buffer{}

	_, err := extractJPEGFrame(br, buf)
	if err == nil {
		t.Fatal("expected error when no EOI found")
	}
}

func TestExtractJPEGFrame_NoSOI(t *testing.T) {
	t.Parallel()

	data := []byte{0x42, 0x43, 0x44}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := &bytes.Buffer{}

	_, err := extractJPEGFrame(br, buf)
	if err == nil {
		t.Fatal("expected error when no SOI found")
	}
}

func TestExtractJPEGFrame_FFInsidePayload(t *testing.T) {
	t.Parallel()

	data := []byte{0xFF, 0xD8, 0xFF, 0x00, 0xFF, 0xD9}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := &bytes.Buffer{}

	frame, err := extractJPEGFrame(br, buf)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if frame[0] != 0xFF || frame[1] != 0xD8 {
		t.Errorf("missing SOI")
	}
	if frame[len(frame)-2] != 0xFF || frame[len(frame)-1] != 0xD9 {
		t.Errorf("missing EOI")
	}
}

func TestExtractJPEGFrame_BufferReset(t *testing.T) {
	t.Parallel()

	data := []byte{0xFF, 0xD8, 0xFF, 0xD9}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := bytes.NewBuffer(make([]byte, maxStreamBufferSize+100))

	frame, err := extractJPEGFrame(br, buf)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(frame) != 4 {
		t.Fatalf("expected 4 bytes, got %d", len(frame))
	}
}

func TestExtractJPEGFrame_FFThenEOF(t *testing.T) {
	t.Parallel()

	data := []byte{0xFF}
	br := bufio.NewReader(bytes.NewReader(data))
	buf := &bytes.Buffer{}

	_, err := extractJPEGFrame(br, buf)
	if err == nil {
		t.Fatal("expected error for truncated input")
	}
}

func TestClampInt(t *testing.T) {
	t.Parallel()

	tests := []struct {
		v, lo, hi, want int
	}{
		{5, 0, 10, 5},
		{-5, 0, 10, 0},
		{15, 0, 10, 10},
		{0, -170, 170, 0},
		{-200, -170, 170, -170},
		{200, -170, 170, 170},
		{100, 100, 400, 100},
		{250, 100, 400, 250},
		{500, 100, 400, 400},
	}

	for _, tc := range tests {
		got := clampInt(tc.v, tc.lo, tc.hi)
		if got != tc.want {
			t.Errorf("clampInt(%d, %d, %d) = %d, want %d", tc.v, tc.lo, tc.hi, got, tc.want)
		}
	}
}

func TestPTZLimits(t *testing.T) {
	t.Parallel()

	lo, hi := ptzLimits(axisPan)
	if lo != panMin || hi != panMax {
		t.Errorf("pan limits: got %d,%d, want %d,%d", lo, hi, panMin, panMax)
	}

	lo, hi = ptzLimits(axisTilt)
	if lo != tiltMin || hi != tiltMax {
		t.Errorf("tilt limits: got %d,%d, want %d,%d", lo, hi, tiltMin, tiltMax)
	}

	lo, hi = ptzLimits(axisZoom)
	if lo != zoomMin || hi != zoomMax {
		t.Errorf("zoom limits: got %d,%d, want %d,%d", lo, hi, zoomMin, zoomMax)
	}

	lo, hi = ptzLimits("unknown")
	if lo != 0 || hi != 0 {
		t.Errorf("unknown axis: got %d,%d, want 0,0", lo, hi)
	}
}

func TestPTZAxisValid(t *testing.T) {
	t.Parallel()

	if !ptzAxisValid(axisPan) {
		t.Error("pan should be valid")
	}
	if !ptzAxisValid(axisTilt) {
		t.Error("tilt should be valid")
	}
	if !ptzAxisValid(axisZoom) {
		t.Error("zoom should be valid")
	}
	if ptzAxisValid("unknown") {
		t.Error("unknown should be invalid")
	}
}

func TestFormatLastSynced(t *testing.T) {
	t.Parallel()

	if result := formatLastSynced(time.Time{}); result != "" {
		t.Errorf("zero time should return empty, got %q", result)
	}

	if result := formatLastSynced(time.Now()); result != "just now" {
		t.Errorf("recent time should return 'just now', got %q", result)
	}

	if result := formatLastSynced(time.Now().Add(-2 * time.Minute)); result != "2m ago" {
		t.Errorf("2 min ago should return '2m ago', got %q", result)
	}

	old := time.Date(2025, 6, 15, 14, 30, 0, 0, time.UTC)
	result := formatLastSynced(old)
	if len(result) != 5 {
		t.Errorf("old time should return HH:MM format, got %q", result)
	}
}
