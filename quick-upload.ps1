param(
    [string]$GitHubUsername = $(Read-Host "Enter your GitHub username")
)

Write-Host "?? Uploading AI Fraud Detection Demo to GitHub..." -ForegroundColor Cyan

# 1. Initialize Git if needed
if (-not (Test-Path ".git")) {
    git init
    Write-Host "Initialized Git repository" -ForegroundColor Green
}

# 2. Add all files
git add .

# 3. Create commit
$commitMessage = @"
AI Fraud Detection Observability Demo

Complete observability platform featuring:
- OpenTelemetry instrumentation
- Prometheus metrics collection  
- Grafana visualization
- Jaeger distributed tracing
- Docker Compose setup
- MIT Professional Education project
"@

git commit -m $commitMessage

# 4. Add remote repository
$repoUrl = "https://github.com/$GitHubUsername/ai-fraud-observability-demo.git"
git remote add origin $repoUrl

# 5. Push to GitHub
git branch -M main
git push -u origin main

Write-Host "`n? Successfully uploaded to GitHub!" -ForegroundColor Green
Write-Host "Repository: https://github.com/$GitHubUsername/ai-fraud-observability-demo" -ForegroundColor Cyan
