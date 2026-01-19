# setup.ps1 - Windows setup script for AI Fraud Detection Observability Demo

Write-Host "?? Setting up AI Fraud Detection Observability Demo" -ForegroundColor Cyan
Write-Host "=================================================="

# Check if Docker is running
try {
    docker info > $null 2>&1
    Write-Host "? Docker is running" -ForegroundColor Green
} catch {
    Write-Host "? Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Start services
Write-Host "`nStarting services..." -ForegroundColor Yellow
docker-compose up --build -d

Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "`nRunning health checks..." -ForegroundColor Yellow
.\scripts\test-all.ps1

Write-Host "`n? Setup complete!" -ForegroundColor Green
Write-Host "`n?? Access URLs:" -ForegroundColor White
Write-Host "  Grafana:     http://localhost:3000 (admin/admin)" -ForegroundColor Gray
Write-Host "  Jaeger:      http://localhost:16686" -ForegroundColor Gray
Write-Host "  Prometheus:  http://localhost:9090" -ForegroundColor Gray
Write-Host "  Order API:   http://localhost:8080" -ForegroundColor Gray
Write-Host "  Fraud API:   http://localhost:5000" -ForegroundColor Gray
