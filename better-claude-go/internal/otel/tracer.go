package otel

import (
	"context"
	"fmt"
	"os"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
	"go.opentelemetry.io/otel/trace"
)

var (
	tracer     trace.Tracer
	shutdownFn func(context.Context) error
)

// InitTracer initializes OpenTelemetry tracing
func InitTracer(serviceName, serviceVersion string) error {
	ctx := context.Background()

	// Create resource
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String(serviceName),
			semconv.ServiceVersionKey.String(serviceVersion),
		),
	)
	if err != nil {
		return fmt.Errorf("failed to create resource: %w", err)
	}

	// Create exporter
	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		endpoint = "http://localhost:4318" // Default to HTTP endpoint
	}

	exporter, err := otlptracehttp.New(ctx,
		otlptracehttp.WithEndpoint(endpoint),
		otlptracehttp.WithInsecure(),
	)
	if err != nil {
		return fmt.Errorf("failed to create trace exporter: %w", err)
	}

	// Create trace provider
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
		sdktrace.WithSampler(sdktrace.AlwaysSample()),
	)

	// Set global providers
	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.TraceContext{})

	// Create tracer
	tracer = otel.Tracer(serviceName)

	// Set shutdown function
	shutdownFn = func(ctx context.Context) error {
		shutdownCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
		defer cancel()
		return tp.Shutdown(shutdownCtx)
	}

	return nil
}

// GetTracer returns the initialized tracer
func GetTracer() trace.Tracer {
	return tracer
}

// Shutdown shuts down the tracer provider
func Shutdown(ctx context.Context) error {
	if shutdownFn != nil {
		return shutdownFn(ctx)
	}
	return nil
}

// StartSpan is a convenience function to start a span
func StartSpan(ctx context.Context, name string) (context.Context, trace.Span) {
	if tracer == nil {
		// Return a no-op span if tracer is not initialized
		noopTracer := trace.NewNoopTracerProvider().Tracer("noop")
		return noopTracer.Start(ctx, name)
	}
	return tracer.Start(ctx, name)
}
