# Save this as setup-demo.ps1 and run it
$scriptPath = $PSScriptRoot
if (-not $scriptPath) { $scriptPath = Get-Location }

Write-Host "🚀 Setting up AI Fraud Detection Demo..." -ForegroundColor Cyan
Write-Host "========================================="

# 1. Create all directories first
Write-Host "Creating directory structure..." -ForegroundColor Yellow
$directories = @(
    "otel-collector",
    "grafana/provisioning/dashboards",
    "grafana/provisioning/datasources", 
    "prometheus",
    "demo-services/order-service",
    "demo-services/fraud-detector",
    "screenshots"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path -Path $scriptPath -ChildPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    }
}

# 2. Create docker-compose.yml
Write-Host "`nCreating docker-compose.yml..." -ForegroundColor Yellow
@'
version: '3.8'
services:
  # Observability Stack
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ["--config=/etc/otel-collector-config.yaml"]
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "8889:8889"  # Prometheus metrics endpoint
    volumes:
      - ./otel-collector/config.yaml:/etc/otel-collector-config.yaml:ro
    networks:
      - observability-net
  
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - observability-net
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - grafana_data:/var/lib/grafana
    networks:
      - observability-net
  
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"  # UI
      - "14268:14268"  # HTTP collector
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    networks:
      - observability-net
  
  # Demo Services
  order-service:
    build: ./demo-services/order-service
    ports:
      - "8080:8080"
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - OTEL_SERVICE_NAME=order-service
      - OTEL_TRACES_SAMPLER=always_on
      - FRAUD_SERVICE_URL=http://fraud-detector:5000
    depends_on:
      - otel-collector
    networks:
      - observability-net
  
  fraud-detector:
    build: ./demo-services/fraud-detector
    ports:
      - "5000:5000"
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - OTEL_SERVICE_NAME=fraud-detector
      - OTEL_TRACES_SAMPLER=always_on
    depends_on:
      - otel-collector
    networks:
      - observability-net

volumes:
  prometheus_data:
    driver: local
  grafana_data:
    driver: local

networks:
  observability-net:
    driver: bridge
'@ | Set-Content -Path (Join-Path $scriptPath "docker-compose.yml")

# 3. Create OpenTelemetry Collector config
Write-Host "Creating OpenTelemetry Collector config..." -ForegroundColor Yellow
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
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug, jaeger]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
'@ | Set-Content -Path (Join-Path $scriptPath "otel-collector/config.yaml")

# 4. Create Prometheus config
Write-Host "Creating Prometheus config..." -ForegroundColor Yellow
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
'@ | Set-Content -Path (Join-Path $scriptPath "prometheus/prometheus.yml")

# 5. Create Grafana datasources
Write-Host "Creating Grafana datasources..." -ForegroundColor Yellow
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
'@ | Set-Content -Path (Join-Path $scriptPath "grafana/provisioning/datasources/datasources.yml")

# 6. Create Grafana dashboards config
Write-Host "Creating Grafana dashboards config..." -ForegroundColor Yellow
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
'@ | Set-Content -Path (Join-Path $scriptPath "grafana/provisioning/dashboards/dashboards.yml")

# 7. Create simple Grafana dashboard
Write-Host "Creating Grafana dashboard..." -ForegroundColor Yellow
@'
{
  "dashboard": {
    "title": "AI Fraud Detection Demo",
    "panels": [
      {
        "title": "Services Status",
        "type": "stat",
        "targets": [{
          "expr": "up",
          "legendFormat": "{{instance}}"
        }]
      }
    ]
  }
}
'@ | Set-Content -Path (Join-Path $scriptPath "grafana/provisioning/dashboards/demo-dashboard.json") -Encoding UTF8

# 8. Create Order Service
Write-Host "Creating Order Service..." -ForegroundColor Yellow

# Dockerfile
@'
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
'@ | Set-Content -Path (Join-Path $scriptPath "demo-services/order-service/Dockerfile")

# Requirements
@'
flask==2.3.2
requests==2.31.0
opentelemetry-api==1.20.0
opentelemetry-sdk==1.20.0
opentelemetry-exporter-otlp==1.20.0
opentelemetry-instrumentation-flask==0.41b0
opentelemetry-instrumentation-requests==0.41b0
'@ | Set-Content -Path (Join-Path $scriptPath "demo-services/order-service/requirements.txt")

# Application with OpenTelemetry
@'
from flask import Flask, request, jsonify
import requests
import random
import time
import os
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

# Initialize OpenTelemetry
trace.set_tracer_provider(TracerProvider())
tracer_provider = trace.get_tracer_provider()

# Check if OTLP endpoint is configured
otlp_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
if otlp_endpoint:
    tracer_provider.add_span_processor(
        BatchSpanProcessor(OTLPSpanExporter())
    )

app = Flask(__name__)

# Auto-instrument Flask and Requests
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()

tracer = trace.get_tracer(__name__)

orders_db = {}
fraud_service_url = os.getenv("FRAUD_SERVICE_URL", "http://fraud-detector:5000")

@app.route('/health', methods=['GET'])
def health():
    return {"status": "healthy", "service": "order-service"}, 200

@app.route('/order', methods=['POST'])
def create_order():
    with tracer.start_as_current_span("create-order") as span:
        try:
            data = request.json
            user_id = data.get('user_id')
            amount = data.get('amount', 0)
            country = data.get('country', 'US')
            
            # Add span attributes
            span.set_attributes({
                "order.user_id": user_id,
                "order.amount": amount,
                "order.country": country
            })
            
            # Validate
            if not user_id or amount <= 0:
                span.set_attribute("order.error", "invalid_data")
                return {"error": "Invalid order data"}, 400
            
            # Check fraud
            with tracer.start_as_current_span("fraud-check") as fraud_span:
                fraud_check = {
                    "user_id": user_id, 
                    "amount": amount, 
                    "country": country
                }
                
                try:
                    response = requests.post(
                        f"{fraud_service_url}/predict",
                        json=fraud_check,
                        timeout=3
                    )
                    fraud_result = response.json()
                    
                    fraud_span.set_attributes({
                        "fraud.score": fraud_result.get('risk_score', 0),
                        "fraud.is_fraud": fraud_result.get('is_fraud', False)
                    })
                    
                    if fraud_result.get('is_fraud', False):
                        fraud_span.add_event("fraud-detected", {
                            "risk_score": fraud_result.get('risk_score')
                        })
                        return {
                            "error": "Fraud detected",
                            "details": fraud_result
                        }, 403
                        
                except Exception as e:
                    fraud_span.record_exception(e)
                    fraud_span.set_attribute("fraud.check.error", "service_unavailable")
                    # Continue without fraud check for demo
            
            # Process payment
            with tracer.start_as_current_span("process-payment"):
                time.sleep(0.1)
                if random.random() < 0.1:  # 10% failure
                    span.add_event("payment-failed")
                    return {"error": "Payment failed"}, 402
            
            # Create order
            order_id = f"ord_{int(time.time())}_{random.randint(1000, 9999)}"
            orders_db[order_id] = {
                "user_id": user_id,
                "amount": amount,
                "country": country,
                "status": "completed"
            }
            
            span.set_attributes({
                "order.id": order_id,
                "order.status": "completed"
            })
            
            span.add_event("order-created", {
                "order_id": order_id,
                "amount": amount
            })
            
            return {
                "order_id": order_id,
                "status": "completed",
                "amount": amount
            }, 201
            
        except Exception as e:
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            return {"error": str(e)}, 500

@app.route('/orders', methods=['GET'])
def list_orders():
    return {"orders": list(orders_db.keys()), "count": len(orders_db)}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
'@ | Set-Content -Path (Join-Path $scriptPath "demo-services/order-service/app.py")

# 9. Create Fraud Detector Service
Write-Host "Creating Fraud Detector Service..." -ForegroundColor Yellow

# Dockerfile
@'
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
'@ | Set-Content -Path (Join-Path $scriptPath "demo-services/fraud-detector/Dockerfile")

# Requirements
@'
flask==2.3.2
opentelemetry-api==1.20.0
opentelemetry-sdk==1.20.0
opentelemetry-exporter-otlp==1.20.0
opentelemetry-instrumentation-flask==0.41b0
'@ | Set-Content -Path (Join-Path $scriptPath "demo-services/fraud-detector/requirements.txt")

# Application
@'
from flask import Flask, request, jsonify
import random
import time
import os
from opentelemetry import trace, metrics
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter

# Initialize OpenTelemetry Tracing
trace.set_tracer_provider(TracerProvider())
tracer_provider = trace.get_tracer_provider()

# Initialize OpenTelemetry Metrics
reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(),
    export_interval_millis=5000
)
meter_provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(meter_provider)

# Check if OTLP endpoint is configured
otlp_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
if otlp_endpoint:
    tracer_provider.add_span_processor(
        BatchSpanProcessor(OTLPSpanExporter())
    )

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)

tracer = trace.get_tracer(__name__)
meter = metrics.get_meter(__name__)

# Create metrics
fraud_predictions_counter = meter.create_counter(
    name="fraud_predictions_total",
    description="Total fraud predictions",
    unit="1"
)

fraud_score_gauge = meter.create_histogram(
    name="fraud_prediction_score",
    description="Fraud prediction scores",
    unit="1"
)

@app.route('/health', methods=['GET'])
def health():
    return {"status": "healthy", "model": "fraud-v2.1"}, 200

@app.route('/predict', methods=['POST'])
def predict():
    start_time = time.time()
    
    with tracer.start_as_current_span("fraud-prediction") as span:
        try:
            data = request.json
            user_id = data.get('user_id', 'unknown')
            amount = data.get('amount', 0)
            country = data.get('country', 'US')
            
            span.set_attributes({
                "user.id": user_id,
                "transaction.amount": amount,
                "transaction.country": country,
                "model.version": "fraud-v2.1"
            })
            
            # Simulate feature engineering
            with tracer.start_as_current_span("feature-engineering"):
                time.sleep(0.05)
                features = {
                    'amount_normalized': min(amount / 1000, 1.0),
                    'is_high_risk_country': 1 if country in ['RU', 'CN', 'NG'] else 0,
                    'is_large_amount': 1 if amount > 5000 else 0
                }
                
            # Simulate ML model inference
            with tracer.start_as_current_span("model-inference"):
                time.sleep(0.1)
                
                # Calculate risk score
                risk_score = 0.0
                if amount > 5000:
                    risk_score += 0.6
                if country in ['RU', 'CN', 'NG']:
                    risk_score += 0.4
                risk_score += random.uniform(-0.1, 0.1)
                risk_score = max(0, min(1, risk_score))
                
                span.set_attributes({
                    "prediction.score": risk_score,
                    "prediction.threshold": 0.7
                })
                
                if risk_score > 0.8:
                    span.add_event("high-risk-detected", {
                        "risk_score": risk_score,
                        "reason": "multiple_risk_factors"
                    })
            
            # Determine fraud status
            is_fraud = risk_score > 0.7
            
            span.set_attributes({
                "prediction.is_fraud": is_fraud,
                "prediction.confidence": abs(risk_score - 0.7)
            })
            
            # Record metrics
            fraud_predictions_counter.add(1, {
                "is_fraud": str(is_fraud),
                "country": country
            })
            fraud_score_gauge.record(risk_score, {
                "country": country
            })
            
            return {
                "risk_score": round(risk_score, 3),
                "is_fraud": is_fraud,
                "threshold": 0.7,
                "reason": "high_amount" if amount > 5000 else "risk_country",
                "model_version": "fraud-v2.1",
                "processing_time_ms": round((time.time() - start_time) * 1000, 2)
            }, 200
            
        except Exception as e:
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            return {"error": str(e)}, 500

@app.route('/metrics', methods=['GET'])
def metrics_endpoint():
    return {
        "model": "fraud-v2.1",
        "threshold": 0.7,
        "endpoints": ["/predict", "/health"]
    }, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
'@ | Set-Content -Path (Join-Path $scriptPath "demo-services/fraud-detector/app.py")

# 10. Create test script
Write-Host "Creating test script..." -ForegroundColor Yellow
@'
Write-Host "🚀 AI Fraud Detection Demo - Test Script" -ForegroundColor Cyan
Write-Host "========================================="

# Function to test endpoint
function Test-Endpoint {
    param($Url, $Method = "GET", $Body = $null)
    
    try {
        if ($Method -eq "GET") {
            $response = Invoke-RestMethod -Uri $Url -Method $Method
        } else {
            $response = Invoke-RestMethod -Uri $Url -Method $Method -Body ($Body | ConvertTo-Json) -ContentType "application/json"
        }
        return $response
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Wait for services to start
Write-Host "`n1. Waiting for services to initialize (15 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Test health endpoints
Write-Host "`n2. Testing service health:" -ForegroundColor Green

$orderHealth = Test-Endpoint -Url "http://localhost:8080/health"
if ($orderHealth) {
    Write-Host "   ✅ Order Service: $($orderHealth.status)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Order Service: Unavailable" -ForegroundColor Red
}

$fraudHealth = Test-Endpoint -Url "http://localhost:5000/health"
if ($fraudHealth) {
    Write-Host "   ✅ Fraud Detector: $($fraudHealth.status)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Fraud Detector: Unavailable" -ForegroundColor Red
}

# Generate test transactions
Write-Host "`n3. Generating test transactions:" -ForegroundColor Green

$testTransactions = @(
    @{user_id="user_normal_1"; amount=100; country="US"},
    @{user_id="user_normal_2"; amount=250; country="CA"},
    @{user_id="user_suspicious_1"; amount=6000; country="US"},
    @{user_id="user_suspicious_2"; amount=300; country="RU"},
    @{user_id="user_fraud_1"; amount=8000; country="CN"}
)

foreach ($tx in $testTransactions) {
    Write-Host "`n   Transaction: User $($tx.user_id)" -ForegroundColor Yellow
    Write-Host "     Amount: `$$($tx.amount), Country: $($tx.country)" -ForegroundColor Gray
    
    $response = Test-Endpoint -Url "http://localhost:8080/order" -Method "POST" -Body $tx
    
    if ($response -and $response.order_id) {
        Write-Host "     ✅ Order created: $($response.order_id)" -ForegroundColor Green
    } elseif ($response -and $response.error) {
        Write-Host "     ❌ Failed: $($response.error)" -ForegroundColor Red
    } else {
        Write-Host "     ⚠️  No response from service" -ForegroundColor Yellow
    }
    
    Start-Sleep -Seconds 2
}

# List all orders
Write-Host "`n4. Listing all orders:" -ForegroundColor Green
$orders = Test-Endpoint -Url "http://localhost:8080/orders"
if ($orders) {
    Write-Host "   Total orders created: $($orders.count)" -ForegroundColor Green
    foreach ($order in $orders.orders) {
        Write-Host "   - $order" -ForegroundColor Gray
    }
}

Write-Host "`n========================================="
Write-Host "✅ Demo Test Complete!" -ForegroundColor Cyan

Write-Host "`n📊 Access URLs:" -ForegroundColor White
Write-Host "   Grafana Dashboard:    http://localhost:3000" -ForegroundColor Yellow
Write-Host "   Jaeger Tracing:       http://localhost:16686" -ForegroundColor Yellow
Write-Host "   Prometheus Metrics:   http://localhost:9090" -ForegroundColor Yellow
Write-Host "   Order Service API:    http://localhost:8080" -ForegroundColor Yellow
Write-Host "   Fraud Detector API:   http://localhost:5000" -ForegroundColor Yellow

Write-Host "`n🔑 Grafana Credentials:" -ForegroundColor White
Write-Host "   Username: admin" -ForegroundColor Yellow
Write-Host "   Password: admin" -ForegroundColor Yellow

Write-Host "`n💡 Try these Prometheus queries:" -ForegroundColor White
Write-Host "   - up" -ForegroundColor Gray
Write-Host "   - fraud_predictions_total" -ForegroundColor Gray
Write-Host "   - rate(fraud_predictions_total[5m])" -ForegroundColor Gray
'@ | Set-Content -Path (Join-Path $scriptPath "test-demo.ps1") -Encoding UTF8
