Write-Host "?? AI Fraud Detection Observability Demo - One-Click Setup" -ForegroundColor Cyan
Write-Host "=========================================================="

# Check if Docker is running
try {
    docker ps > $null 2>&1
    Write-Host "? Docker is running" -ForegroundColor Green
} catch {
    Write-Host "? Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Start services
Write-Host "`nStarting observability stack..." -ForegroundColor Yellow
docker-compose up --build -d

Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Run health checks
Write-Host "`nRunning health checks..." -ForegroundColor Yellow
.\scripts\test-all.ps1

Write-Host "`n?? Setup Complete!" -ForegroundColor Green -BackgroundColor DarkBlue
Write-Host "`n?? Access URLs:" -ForegroundColor White
Write-Host "Grafana Dashboard: http://localhost:3000" -ForegroundColor Cyan
Write-Host "   Username: admin, Password: admin" -ForegroundColor Gray
Write-Host "Jaeger Tracing:    http://localhost:16686" -ForegroundColor Cyan
Write-Host "Prometheus Metrics: http://localhost:9090" -ForegroundColor Cyan
Write-Host "Order Service API:  http://localhost:8080/health" -ForegroundColor Cyan
Write-Host "Fraud Service API:  http://localhost:5000/health" -ForegroundColor Cyan

Write-Host "`n?? Generate demo traffic:" -ForegroundColor White
Write-Host ".\scripts\generate-traffic.ps1" -ForegroundColor Yellow

Write-Host "`n?? Documentation:" -ForegroundColor White
Write-Host "See README.md for detailed instructions" -ForegroundColor Gray


