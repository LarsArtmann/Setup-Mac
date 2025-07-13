bun update -g
claude config set -g theme dark-daltonized
claude config set -g parallelTasksCount 20
claude config set -g preferredNotifChannel iterm2_with_bell
claude config set -g messageIdleNotifThresholdMs 1000
claude config set -g autoUpdates false
claude config set -g diffTool bat

# OTEL_METRIC_EXPORT_INTERVAL = for debugging (faster export intervals)
claude config set -g env '{"EDITOR":"nano", "CLAUDE_CODE_ENABLE_TELEMETRY":"1", "OTEL_METRICS_EXPORTER":"otlp", "OTEL_LOGS_EXPORTER":"otlp", "OTEL_EXPORTER_OTLP_PROTOCOL":"grpc", "OTEL_EXPORTER_OTLP_ENDPOINT":"http://localhost:4317", "OTEL_METRIC_EXPORT_INTERVAL":"10000", "OTEL_LOGS_EXPORT_INTERVAL":"5000"}'

# DISABLED, because it fucking deleted the env's (#stupid)!: claude config ls -g
claude config ls

