#!/bin/bash
# setup.sh - Setup script for AI Fraud Detection Observability Demo

echo "🚀 Setting up AI Fraud Detection Observability Demo"
echo "=================================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Start services
echo "Starting services..."
docker-compose up --build -d

echo "Waiting for services to initialize..."
sleep 30

echo "Running health checks..."
# Note: test-all.ps1 is a PowerShell script, may need adjustment for bash
echo "Health checks would run here (see setup.ps1 for Windows)"

echo "✅ Setup complete!"
echo ""
echo "📊 Access URLs:"
echo "  Grafana:     http://localhost:3000 (admin/admin)"
echo "  Jaeger:      http://localhost:16686"
echo "  Prometheus:  http://localhost:9090"
echo "  Order API:   http://localhost:8080"
echo "  Fraud API:   http://localhost:5000"
