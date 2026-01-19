Write-Host "Generating Demo Traffic..." -ForegroundColor Cyan
Write-Host "========================="

# Generate 10 test transactions
$transactions = @(
    @{user_id="user1"; amount=100; country="US"},
    @{user_id="user2"; amount=250; country="CA"},
    @{user_id="user3"; amount=6000; country="US"},  # High amount
    @{user_id="user4"; amount=300; country="RU"},   # Risky country
    @{user_id="user5"; amount=8000; country="CN"},  # Both risky
    @{user_id="user6"; amount=150; country="UK"},
    @{user_id="user7"; amount=4500; country="US"},
    @{user_id="user8"; amount=200; country="NG"},   # Risky country
    @{user_id="user9"; amount=12000; country="US"}, # Very high amount
    @{user_id="user10"; amount=75; country="DE"}
)

foreach ($tx in $transactions) {
    Write-Host "Processing: User $($tx.user_id), Amount: `$$($tx.amount), Country: $($tx.country)" -ForegroundColor Gray
    
    try {
        $body = $tx | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "http://localhost:8080/order" `
            -Method Post `
            -Body $body `
            -ContentType "application/json" `
            -TimeoutSec 5
        
        if ($response.order_id) {
            Write-Host "  ? Order created: $($response.order_id)" -ForegroundColor Green
        } elseif ($response.error) {
            Write-Host "  ??  $($response.error)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ? Error: $_" -ForegroundColor Red
    }
    
    # Wait between requests
    Start-Sleep -Seconds 2
}

Write-Host "`n========================="
Write-Host "Traffic generation complete!" -ForegroundColor Cyan

# Check metrics
Write-Host "`nChecking Prometheus metrics..." -ForegroundColor Yellow
try {
    $metrics = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/query?query=orders_total"
    Write-Host "Orders processed:" -ForegroundColor Green
    $metrics.data.result | ForEach-Object {
        Write-Host "  $($_.metric.status): $($_.value[1])" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not fetch metrics" -ForegroundColor Red
}

Write-Host "`nDashboard URLs:" -ForegroundColor White
Write-Host "Grafana:    http://localhost:3000/d/fraud-dashboard" -ForegroundColor Yellow
Write-Host "Prometheus: http://localhost:9090" -ForegroundColor Yellow
Write-Host "Jaeger:     http://localhost:16686" -ForegroundColor Yellow
