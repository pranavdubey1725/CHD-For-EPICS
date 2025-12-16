# Start All Services Now
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting All CHD-EPICS Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS"

# 1. Start MinIO
Write-Host "1. Starting MinIO..." -ForegroundColor Yellow
docker start minio 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0 -or $?) {
    Write-Host "   ✅ MinIO is running" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  MinIO might already be running" -ForegroundColor Yellow
}
Start-Sleep -Seconds 2

# 2. Start ML Service
Write-Host "2. Starting ML Service (port 8000)..." -ForegroundColor Yellow
$mlPath = Join-Path $projectPath "ml-service"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$mlPath'; Write-Host '=== ML Service Starting ===' -ForegroundColor Cyan; python main.py" -WindowStyle Normal
Write-Host "   ✅ ML Service starting in new window..." -ForegroundColor Green
Start-Sleep -Seconds 3

# 3. Start Backend
Write-Host "3. Starting Backend (port 8080)..." -ForegroundColor Yellow
$backendPath = Join-Path $projectPath "backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; Write-Host '=== Backend Starting ===' -ForegroundColor Cyan; .\mvnw.cmd spring-boot:run" -WindowStyle Normal
Write-Host "   ✅ Backend starting in new window..." -ForegroundColor Green
Write-Host "   ⏱️  This will take 30-60 seconds to start" -ForegroundColor Yellow
Start-Sleep -Seconds 3

# 4. Start Frontend
Write-Host "4. Starting Frontend (port 3000)..." -ForegroundColor Yellow
$frontendPath = Join-Path $projectPath "frontend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$frontendPath'; Write-Host '=== Frontend Starting ===' -ForegroundColor Cyan; python -m http.server 3000" -WindowStyle Normal
Write-Host "   ✅ Frontend starting in new window..." -ForegroundColor Green
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ All Services Starting!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You should see 3 new PowerShell windows:" -ForegroundColor Yellow
Write-Host "  • ML Service window" -ForegroundColor White
Write-Host "  • Backend window (wait 30-60 seconds)" -ForegroundColor White
Write-Host "  • Frontend window" -ForegroundColor White
Write-Host ""
Write-Host "Service URLs:" -ForegroundColor Cyan
Write-Host "  • Frontend: http://localhost:3000/main.html" -ForegroundColor White
Write-Host "  • Backend: http://localhost:8080/api/health" -ForegroundColor White
Write-Host "  • ML Service: http://localhost:8000/health" -ForegroundColor White
Write-Host "  • MinIO Console: http://localhost:9001" -ForegroundColor White
Write-Host ""
Write-Host "Wait for backend to show 'Started BackendApplication'" -ForegroundColor Yellow
Write-Host "Then refresh: http://localhost:3000/main.html" -ForegroundColor Yellow
Write-Host ""




