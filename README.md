>> ## ??? Architecture
>>
>> ```
>> +-----------------+     +------------------+
>> ¦   Order Service ¦----?¦ Fraud Detector   ¦
>> ¦   Python/Flask  ¦     ¦ Python/Flask+AI  ¦
>> ¦   :8080/:8000   ¦     ¦   :5000/:8000    ¦
>> +-----------------+     +------------------+
>>          ¦                       ¦
>>          ?                       ?
>> +-----------------------------------------+
>> ¦     OpenTelemetry Collector             ¦
>> ¦     (Receives/Processes/Exports)        ¦
>> ¦     :4317/:4318/:8889                   ¦
>> +-----------------------------------------+
>>                ¦                 ¦
>>                ?                 ?
>>       +--------------+   +--------------+
>>       ¦    Jaeger    ¦   ¦  Prometheus  ¦
>>       ¦  (Traces)    ¦   ¦  (Metrics)   ¦
>>       ¦   :16686     ¦   ¦   :9090      ¦
>>       +--------------+   +--------------+
>>                                 ¦
>>                                 ?
>>                         +--------------+
>>                         ¦   Grafana    ¦
>>                         ¦(Visualization)¦
>>                         ¦   :3000      ¦
>>                         +--------------+
>> ```
>>
>> ## ?? Quick Start
>>
>> ### Prerequisites
>> - Docker Desktop 20.10+
>> - Docker Compose 2.0+
>> - 4GB RAM available
>> - Git
>>
>> ### Installation & Running
>>
>> 1. **Clone the repository**
>>    ```bash
>>    git clone https://github.com/<your-username>/ai-fraud-observability-demo.git
>>    cd ai-fraud-observability-demo
>>    ```
>>
>> 2. **Start all services**
>>    ```powershell
>>    # On Windows PowerShell
>>    docker-compose up --build -d
>>    
>>    # Wait for services to initialize
>>    Start-Sleep -Seconds 30
>>    ```
>>
>> 3. **Generate test traffic**
>>    ```powershell
>>    scripts\generate-traffic.ps1
>>    ```
>>
>> 4. **Access the dashboards**
>>    - Grafana: http://localhost:3000 (admin/admin)
>>    - Jaeger UI: http://localhost:16686
>>    - Prometheus: http://localhost:9090
>>    - Order Service API: http://localhost:8080
>>    - Fraud Detector API: http://localhost:5000
>>
>> ## ?? Monitoring Capabilities
>>
>> ### Business Metrics
>> - Fraud detection rate and accuracy
>> - Transaction success/failure rates
>> - Order processing throughput
>> - Revenue impact analysis
>>
>> ### Technical Metrics
>> - Service latency (p50, p95, p99)
>> - Error rates and availability
>> - ML model inference performance
>> - Resource utilization
>>
>> ### Distributed Tracing
>> - End-to-end transaction flow
>> - Service dependency mapping
>> - Latency breakdown by service
>> - Error propagation analysis
>>
>> ## ?? Demo Scenarios
>>
>> ### Scenario 1: Fraud Detection in Action
>> ```bash
>> # Normal transaction (approved)
>> POST http://localhost:8080/order
>> {"user_id": "user1", "amount": 100, "country": "US"}
>>
>> # Fraudulent transaction (blocked)
>> POST http://localhost:8080/order
>> {"user_id": "user2", "amount": 8000, "country": "RU"}
>> ```
>>
>> ### Scenario 2: Performance Monitoring
>> 1. Generate load with the traffic script
>> 2. Monitor latency spikes in Grafana
>> 3. Trace slow requests in Jaeger
>> 4. Identify bottlenecks in the system
>>
>> ### Scenario 3: Incident Response
>> 1. Simulate service failure
>> 2. Monitor alert propagation
>> 3. Use traces to identify root cause
>> 4. Show recovery process
>>
>> ## ?? Configuration Details
>>
>> ### OpenTelemetry Collector
>> Located in `otel-collector/config.yaml`:
>> - Receives OTLP data on ports 4317 (gRPC) and 4318 (HTTP)
>> - Processes traces and metrics with batching
>> - Exports to Jaeger (traces) and Prometheus (metrics)
>>
>> ### Prometheus Configuration
>> Located in `prometheus/prometheus.yml`:
>> - Scrapes metrics from services every 15s
>> - Service discovery for dynamic environments
>> - Retention policies for metrics storage
>>
>> ### Grafana Dashboards
>> Located in `grafana/provisioning/dashboards/`:
>> - Pre-built dashboard for fraud detection monitoring
>> - Service health monitoring
>> - Business metrics visualization
>>
>> ## ?? Project Structure
>>
>> ```
>> ai-fraud-observability-demo/
>> +-- docker-compose.yml              # Main Docker Compose configuration
>> +-- README.md                       # This documentation
>> +-- LICENSE                         # MIT License
>> ¦
>> +-- otel-collector/
>> ¦   +-- config.yaml                 # OpenTelemetry Collector config
>> ¦
>> +-- prometheus/
>> ¦   +-- prometheus.yml              # Prometheus configuration
>> ¦
>> +-- grafana/
>> ¦   +-- provisioning/
>> ¦       +-- dashboards/             # Grafana dashboards
>> ¦       +-- datasources/            # Data source configurations
>> ¦
>> +-- demo-services/
>> ¦   +-- order-service/
>> ¦   ¦   +-- Dockerfile              # Order service container
>> ¦   ¦   +-- requirements.txt        # Python dependencies
>> ¦   ¦   +-- app.py                  # Flask application with OpenTelemetry
>> ¦   ¦
>> ¦   +-- fraud-detector/
>> ¦       +-- Dockerfile              # Fraud detector container
>> ¦       +-- requirements.txt        # Python dependencies
>> ¦       +-- app.py                  # ML fraud detection service
>> ¦
>> +-- scripts/
>> ¦   +-- generate-traffic.ps1        # Test traffic generator
>> ¦   +-- test-all.ps1                # Service health testing
>> ¦   +-- setup-demo.ps1              # Initial setup script
>> ¦
>> +-- docs/
>> ¦   +-- architecture.md             # Architecture documentation
>> ¦   +-- interview-demo-guide.md     # Interview presentation guide
>> ¦
>> +-- images/                         # Screenshots and diagrams
>> ```
>>
>> ## ?? Learning Outcomes
>>
>> This project demonstrates practical skills in:
>>
>> 1. **OpenTelemetry Implementation**
>>    - Automatic and manual instrumentation
>>    - Context propagation across services
>>    - Custom span attributes and events
>>
>> 2. **Observability Stack Deployment**
>>    - Containerized service deployment
>>    - Configuration management
>>    - Service mesh integration
>>
>> 3. **Production Monitoring**
>>    - SLO/SLI definition and tracking
>>    - Alerting and incident response
>>    - Performance optimization
>>
>> 4. **AI/ML Operations (MLOps)**
>>    - Model performance monitoring
>>    - Prediction explainability
>>    - Data drift detection
>>
>> ## ??? Development
>>
>> ### Adding New Services
>> 1. Add service to `docker-compose.yml`
>> 2. Instrument with OpenTelemetry
>> 3. Add Prometheus metrics endpoint
>> 4. Update Grafana dashboards
>>
>> ### Customizing Metrics
>> 1. Modify service code to add custom metrics
>> 2. Update Prometheus scrape configs
>> 3. Add new panels to Grafana dashboards
>>
>> ### Extending Tracing
>> 1. Add manual instrumentation for business logic
>> 2. Create custom span processors
>> 3. Implement sampling strategies
>>
>> ## ?? Performance Considerations
>>
>> ### Optimization Tips
>> - Use batch processors in production
>> - Implement sampling for high-volume services
>> - Configure appropriate retention periods
>> - Monitor collector resource usage
>>
>> ### Scalability
>> - Deploy collectors as sidecars or daemonsets
>> - Use persistent storage for Prometheus
>> - Implement federation for multi-cluster setups
>> - Consider using Thanos or Cortex for long-term storage
>>
>> ## ?? Security Best Practices
>>
>> 1. **Network Security**
>>    - Use internal Docker networks
>>    - Implement network policies
>>    - Secure service-to-service communication
>>
>> 2. **Data Protection**
>>    - Remove PII from traces
>>    - Use TLS for external endpoints
>>    - Implement access controls
>>
>> 3. **Authentication & Authorization**
>>    - Secure Grafana with proper RBAC
>>    - Use API keys for Prometheus
>>    - Implement audit logging
>>
>> ## ?? Troubleshooting
>>
>> ### Common Issues
>>
>> 1. **Port Conflicts**
>>    ```powershell
>>    # Check which process is using a port
>>    netstat -ano | findstr :3000
>>    ```
>>
>> 2. **Docker Container Issues**
>>    ```powershell
>>    # View container logs
>>    docker-compose logs <service-name>
>>    
>>    # Restart a specific service
>>    docker-compose restart <service-name>
>>    
>>    # Rebuild and restart everything
>>    docker-compose down -v
>>    docker-compose up --build -d
>>    ```
>>
>> 3. **Missing Metrics**
>>    - Verify Prometheus targets at http://localhost:9090/targets
>>    - Check service metrics endpoints
>>    - Verify network connectivity between services
>>
>> ### Debugging Commands
>> ```powershell
>> # Check service health
>> scripts\test-all.ps1
>>
>> # View OpenTelemetry logs
>> docker-compose logs otel-collector
>>
>> # Check Prometheus metrics
>> curl http://localhost:9090/api/v1/query?query=up
>>
>> # Test individual services
>> curl http://localhost:8080/health
>> curl http://localhost:5000/health
>> ```
>>
>> ## ?? Contributing
>>
>> 1. Fork the repository
>> 2. Create a feature branch
>> 3. Make your changes
>> 4. Add tests if applicable
>> 5. Submit a pull request
>>
>> ## ?? License
>>
>> This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
>>
>> ## ?? Acknowledgements
>>
>> - MIT Professional Education - No Code AI/ML program
>> - OpenTelemetry community
>> - CNCF (Cloud Native Computing Foundation)
>> - All open-source projects used in this demo
>>
>> ## ?? Contact
>>
>> Your Name - [@yourtwitter](https://twitter.com/yourtwitter) - email@example.com
>>
>> Project Link: [https://github.com/<your-username>/ai-fraud-observability-demo](https://github.com/<your-username>/ai-fraud-observability-demo)

