Write-Host "?? GitHub Repository Upload Script" -ForegroundColor Cyan
Write-Host "=================================="

# Check Git status
Write-Host "`nChecking Git status..." -ForegroundColor Yellow
git status

# Add all files
Write-Host "`nAdding all files to Git..." -ForegroundColor Yellow
git add .

# Create commit
$commitMessage = @"
Initial commit: AI Fraud Detection Observability Demo

Complete observability platform featuring:
- OpenTelemetry instrumentation for microservices
- Prometheus metrics collection with custom business metrics
- Grafana visualization with pre-built dashboards
- Jaeger distributed tracing
- Docker Compose deployment
- Production-ready configuration patterns

Demo Services:
- Order Service (Python/Flask) with transaction processing
- Fraud Detection Service with AI/ML model simulation
- Complete observability stack with collector configuration

Includes:
- Comprehensive documentation and architecture diagrams
- Test scripts for traffic generation and health checks
- GitHub workflows for CI/CD
- MIT License and contribution guidelines

This project demonstrates practical implementation of observability
patterns learned through MIT Professional Education No-Code AI/ML program.
"@

git commit -m $commitMessage

Write-Host "`n? Commit created!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Create repository on GitHub:" -ForegroundColor Yellow
Write-Host "   Go to: https://github.com/new" -ForegroundColor White
Write-Host "   Name: ai-fraud-observability-demo" -ForegroundColor White
Write-Host "   Description: Complete observability demo for AI fraud detection" -ForegroundColor White
Write-Host "   DO NOT initialize with README, .gitignore, or license" -ForegroundColor Red
Write-Host "`n2. After creating repository, run these commands:" -ForegroundColor Yellow
Write-Host '   git remote add origin https://github.com/<YOUR_USERNAME>/ai-fraud-observability-demo.git' -ForegroundColor White
Write-Host "   git branch -M main" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor White
Write-Host "`n3. Create release tag:" -ForegroundColor Yellow
Write-Host "   git tag -a v1.0 -m 'Initial release'" -ForegroundColor White
Write-Host "   git push origin v1.0" -ForegroundColor White
