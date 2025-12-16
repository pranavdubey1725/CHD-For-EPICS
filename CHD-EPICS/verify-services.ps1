# Quick Service Verification
Write-Host "Checking services..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "`n1. MinIO..." -ForegroundColor Cyan
try {
    docker ps --filter "name=minio" --format "{{.Names}}" | Out-Null
    Write-Host "   ✅ Running" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Not running" -ForegroundColor Red
}

Write-Host "`n2. ML Service (port 8000)..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Running" -ForegroundColor Green
    } else {
        Write-Host "   ⏳ Starting..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⏳ Starting (wait 10-30 seconds for model to load)..." -ForegroundColor Yellow
}

Write-Host "`n3. Backend (port 8080)..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Running" -ForegroundColor Green
    } else {
        Write-Host "   ⏳ Starting (wait 30-60 seconds)..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⏳ Starting (wait 30-60 seconds)..." -ForegroundColor Yellow
}

Write-Host "`n4. Frontend (port 3000)..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/main.html" -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Running" -ForegroundColor Green
    } else {
        Write-Host "   ⏳ Starting..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⏳ Starting..." -ForegroundColor Yellow
}

Write-Host "`n" -ForegroundColor White




