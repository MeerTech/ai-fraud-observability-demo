# AI Fraud Detection Observability - Architecture

```mermaid
graph TB
    Client[Client/Browser] --> OrderService[Order Service<br/>:8080/:8000]
    
    OrderService --> FraudDetector[Fraud Detector<br/>:5000/:8000]
    
    OrderService --> OTEL1[OpenTelemetry SDK]
    FraudDetector --> OTEL2[OpenTelemetry SDK]
    
    OTEL1 --> Collector[OTEL Collector<br/>:4317/:4318/:8889]
    OTEL2 --> Collector
    
    Collector --> Jaeger[Jaeger<br/>:16686]
    Collector --> Prometheus[Prometheus<br/>:9090]
    
    Prometheus --> Grafana[Grafana<br/>:3000]
    Jaeger --> Grafana
    
    style OrderService fill:#e1f5fe
    style FraudDetector fill:#f3e5f5
    style Collector fill:#e8f5e8
    style Jaeger fill:#fff3e0
    style Prometheus fill:#ffebee
    style Grafana fill:#e8f5e8
