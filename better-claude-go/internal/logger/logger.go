package logger

import (
	"context"
	"log/slog"
	"os"

	"github.com/fatih/color"
	"go.opentelemetry.io/otel/trace"
)

// Logger interface for colored output with OTEL support
type Logger interface {
	Info(message string)
	InfoCtx(ctx context.Context, message string)
	Success(message string)
	SuccessCtx(ctx context.Context, message string)
	Warning(message string)
	WarningCtx(ctx context.Context, message string)
	Error(message string)
	ErrorCtx(ctx context.Context, message string)
}

// ColorLogger implements Logger with colored output and structured logging
type ColorLogger struct {
	info    *color.Color
	success *color.Color
	warning *color.Color
	error   *color.Color
	slogger *slog.Logger
}

func NewColorLogger() *ColorLogger {
	return &ColorLogger{
		info:    color.New(color.FgBlue, color.Bold),
		success: color.New(color.FgGreen, color.Bold),
		warning: color.New(color.FgYellow, color.Bold),
		error:   color.New(color.FgRed, color.Bold),
		slogger: slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
			Level: slog.LevelInfo,
		})),
	}
}

func (l *ColorLogger) Info(message string) {
	l.info.Printf("[INFO] %s\n", message)
	l.slogger.Info(message)
}

func (l *ColorLogger) InfoCtx(ctx context.Context, message string) {
	l.info.Printf("[INFO] %s\n", message)

	// Add trace information if available
	span := trace.SpanFromContext(ctx)
	if span.IsRecording() {
		spanCtx := span.SpanContext()
		l.slogger.InfoContext(ctx, message,
			slog.String("trace_id", spanCtx.TraceID().String()),
			slog.String("span_id", spanCtx.SpanID().String()),
		)
	} else {
		l.slogger.InfoContext(ctx, message)
	}
}

func (l *ColorLogger) Success(message string) {
	l.success.Printf("[SUCCESS] %s\n", message)
	l.slogger.Info(message, slog.String("level", "success"))
}

func (l *ColorLogger) SuccessCtx(ctx context.Context, message string) {
	l.success.Printf("[SUCCESS] %s\n", message)

	span := trace.SpanFromContext(ctx)
	if span.IsRecording() {
		spanCtx := span.SpanContext()
		l.slogger.InfoContext(ctx, message,
			slog.String("level", "success"),
			slog.String("trace_id", spanCtx.TraceID().String()),
			slog.String("span_id", spanCtx.SpanID().String()),
		)
	} else {
		l.slogger.InfoContext(ctx, message, slog.String("level", "success"))
	}
}

func (l *ColorLogger) Warning(message string) {
	l.warning.Printf("[WARNING] %s\n", message)
	l.slogger.Warn(message)
}

func (l *ColorLogger) WarningCtx(ctx context.Context, message string) {
	l.warning.Printf("[WARNING] %s\n", message)

	span := trace.SpanFromContext(ctx)
	if span.IsRecording() {
		spanCtx := span.SpanContext()
		l.slogger.WarnContext(ctx, message,
			slog.String("trace_id", spanCtx.TraceID().String()),
			slog.String("span_id", spanCtx.SpanID().String()),
		)
	} else {
		l.slogger.WarnContext(ctx, message)
	}
}

func (l *ColorLogger) Error(message string) {
	l.error.Printf("[ERROR] %s\n", message)
	l.slogger.Error(message)
}

func (l *ColorLogger) ErrorCtx(ctx context.Context, message string) {
	l.error.Printf("[ERROR] %s\n", message)

	span := trace.SpanFromContext(ctx)
	if span.IsRecording() {
		spanCtx := span.SpanContext()
		l.slogger.ErrorContext(ctx, message,
			slog.String("trace_id", spanCtx.TraceID().String()),
			slog.String("span_id", spanCtx.SpanID().String()),
		)
	} else {
		l.slogger.ErrorContext(ctx, message)
	}
}
