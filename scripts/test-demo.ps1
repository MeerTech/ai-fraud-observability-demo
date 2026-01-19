Write-Host "ðŸš€ AI Fraud Detection Demo - Test Script" -ForegroundColor Cyan
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
    Write-Host "   âœ… Order Service: $($orderHealth.status)" -ForegroundColor Green
} else {
    Write-Host "   âŒ Order Service: Unavailable" -ForegroundColor Red
}

$fraudHealth = Test-Endpoint -Url "http://localhost:5000/health"
if ($fraudHealth) {
    Write-Host "   âœ… Fraud Detector: $($fraudHealth.status)" -ForegroundColor Green
} else {
    Write-Host "   âŒ Fraud Detector: Unavailable" -ForegroundColor Red
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
        Write-Host "     âœ… Order created: $($response.order_id)" -ForegroundColor Green
    } elseif ($response -and $response.error) {
        Write-Host "     âŒ Failed: $($response.error)" -ForegroundColor Red
    } else {
        Write-Host "     âš ï¸  No response from service" -ForegroundColor Yellow
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
Write-Host "âœ… Demo Test Complete!" -ForegroundColor Cyan

Write-Host "`nðŸ“Š Access URLs:" -ForegroundColor White
Write-Host "   Grafana Dashboard:    http://localhost:3000" -ForegroundColor Yellow
Write-Host "   Jaeger Tracing:       http://localhost:16686" -ForegroundColor Yellow
Write-Host "   Prometheus Metrics:   http://localhost:9090" -ForegroundColor Yellow
Write-Host "   Order Service API:    http://localhost:8080" -ForegroundColor Yellow
Write-Host "   Fraud Detector API:   http://localhost:5000" -ForegroundColor Yellow

Write-Host "`nðŸ”‘ Grafana Credentials:" -ForegroundColor White
Write-Host "   Username: admin" -ForegroundColor Yellow
Write-Host "   Password: admin" -ForegroundColor Yellow

Write-Host "`nðŸ’¡ Try these Prometheus queries:" -ForegroundColor White
Write-Host "   - up" -ForegroundColor Gray
Write-Host "   - fraud_predictions_total" -ForegroundColor Gray
Write-Host "   - rate(fraud_predictions_total[5m])" -ForegroundColor Gray
