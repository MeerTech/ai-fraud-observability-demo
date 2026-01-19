$scriptPath = $PSScriptRoot
if (-not $scriptPath) { $scriptPath = Get-Location }

# 1. Create otel-collector config
@'
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 256

exporters:
  debug:
    verbosity: detailed
  prometheus:
    endpoint: "0.0.0.0:8889"
    namespace: ai_observability
    const_labels:
      environment: "demo"
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true

service:
  telemetry:
    logs:
      level: info
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [debug, jaeger]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
'@ | Set-Content -Path "$scriptPath/otel-collector/config.yaml"

# 2. Create Prometheus config
@'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "otel-collector"
    static_configs:
      - targets: ["otel-collector:8889"]
    scrape_interval: 10s

  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
'@ | Set-Content -Path "$scriptPath/prometheus/prometheus.yml"

# 3. Create Grafana datasources
@'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
  
  - name: Jaeger
    type: jaeger
    access: proxy
    url: http://jaeger:16686
    editable: true
'@ | Set-Content -Path "$scriptPath/grafana/provisioning/datasources/datasources.yml"

# 4. Create Grafana dashboards config
@'
apiVersion: 1

providers:
  - name: "default"
    orgId: 1
    folder: ""
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /etc/grafana/provisioning/dashboards
'@ | Set-Content -Path "$scriptPath/grafana/provisioning/dashboards/dashboards.yml"

Write-Host "✅ Configuration files created successfully!" -ForegroundColor Green