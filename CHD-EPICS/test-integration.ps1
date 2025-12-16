# Integration Test Script
# Tests if all services are running and accessible

Write-Host "=== Integration Test ===" -ForegroundColor Cyan
Write-Host ""

$allServicesOk = $true

# Test Backend
Write-Host "1. Testing Backend (http://localhost:8080)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Backend is running" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Backend returned status: $($response.StatusCode)" -ForegroundColor Red
        $allServicesOk = $false
    }
} catch {
    Write-Host "   ❌ Backend is not accessible" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
    $allServicesOk = $false
}

# Test ML Service
Write-Host "`n2. Testing ML Service (http://localhost:8000)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ ML Service is running" -ForegroundColor Green
    } else {
        Write-Host "   ❌ ML Service returned status: $($response.StatusCode)" -ForegroundColor Red
        $allServicesOk = $false
    }
} catch {
    Write-Host "   ❌ ML Service is not accessible" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
    $allServicesOk = $false
}

# Test MinIO
Write-Host "`n3. Testing MinIO (http://localhost:9001)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9001" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ MinIO is running" -ForegroundColor Green
    } else {
        Write-Host "   ❌ MinIO returned status: $($response.StatusCode)" -ForegroundColor Red
        $allServicesOk = $false
    }
} catch {
    Write-Host "   ❌ MinIO is not accessible" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor Gray
    $allServicesOk = $false
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
if ($allServicesOk) {
    Write-Host "✅ All services are running!" -ForegroundColor Green
    Write-Host "`nYou can now:" -ForegroundColor Yellow
    Write-Host "  1. Start frontend: cd frontend; python -m http.server 3000" -ForegroundColor White
    Write-Host "  2. Open: http://localhost:3000/login.html" -ForegroundColor White
    Write-Host "  3. Register a new doctor account" -ForegroundColor White
    Write-Host "  4. Login and test the integration" -ForegroundColor White
} else {
    Write-Host "❌ Some services are not running" -ForegroundColor Red
    Write-Host "`nPlease start the missing services:" -ForegroundColor Yellow
    Write-Host "  - Backend: cd backend; .\mvnw.cmd spring-boot:run" -ForegroundColor White
    Write-Host "  - ML Service: cd ml-service; python -m uvicorn main:app --host 0.0.0.0 --port 8000" -ForegroundColor White
    Write-Host "  - MinIO: .\start-minio-docker.ps1" -ForegroundColor White
}

Write-Host ""






