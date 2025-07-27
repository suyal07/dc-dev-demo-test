Write-Host "Starting local HTTP server on port 8000..." -ForegroundColor Green
Write-Host "Keep this window open during deployment testing" -ForegroundColor Yellow
Write-Host ""
python -m http.server 8000
