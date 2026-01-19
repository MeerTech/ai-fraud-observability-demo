# Save this as test-all.ps1
Write-Host "Testing All Services..." -ForegroundColor Cyan
Write-Host "========================="

# 1. Test Order Service
Write-Host "`n1. Testing Order Service (Port 8080):" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5
    Write-Host "   ✅ Order Service: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Order Service: Failed - $_" -ForegroundColor Red
}

# 2. Test Fraud Detector
Write-Host "`n2. Testing Fraud Detector (Port 5000):" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/health" -TimeoutSec 5
    Write-Host "   ✅ Fraud Detector: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Fraud Detector: Failed - $_" -ForegroundColor Red
}

# 3. Test Jaeger
Write-Host "`n3. Testing Jaeger (Port 16686):" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:16686" -TimeoutSec 5
    Write-Host "   ✅ Jaeger UI: Accessible" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Jaeger UI: Failed - $_" -ForegroundColor Red
}

# 4. Test Prometheus
Write-Host "`n4. Testing Prometheus (Port 9090):" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/query?query=up" -TimeoutSec 5
    Write-Host "   ✅ Prometheus: Query successful" -ForegroundColor Green
    Write-Host "   Metrics found:" -ForegroundColor Gray
    $response.data.result | ForEach-Object {
        Write-Host "   - $($_.metric.instance)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Prometheus: Failed - $_" -ForegroundColor Red
}

# 5. Test Grafana
Write-Host "`n5. Testing Grafana (Port 3000):" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 5
    Write-Host "   ✅ Grafana: Accessible" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Grafana: Failed - $_" -ForegroundColor Red
}

# 6. Create a test transaction
Write-Host "`n6. Testing Transaction Flow:" -ForegroundColor Yellow
try {
    $body = @{
        user_id = "test_user"
        amount = 100
        country = "US"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "http://localhost:8080/order" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10
    Write-Host "   ✅ Transaction successful:" -ForegroundColor Green
    Write-Host "   Order ID: $($response.order_id)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Transaction failed: $_" -ForegroundColor Red
}

Write-Host "`n========================="
Write-Host "Test Complete!" -ForegroundColor Cyan

Write-Host "`nAccess URLs:" -ForegroundColor White
Write-Host "Grafana:     http://localhost:3000 (admin/admin)" -ForegroundColor Yellow
Write-Host "Jaeger:      http://localhost:16686" -ForegroundColor Yellow
Write-Host "Prometheus:  http://localhost:9090" -ForegroundColor Yellow
Write-Host "Order API:   http://localhost:8080/health" -ForegroundColor Yellow
Write-Host "Fraud API:   http://localhost:5000/health" -ForegroundColor Yellow