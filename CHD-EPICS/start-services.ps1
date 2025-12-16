# Start Both Services Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting CHD-EPICS Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is available
Write-Host "Checking Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "   Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Python not found!" -ForegroundColor Red
    Write-Host "   Please install Python to run the ML service" -ForegroundColor Red
    exit 1
}

# Check if Java is available
Write-Host "Checking Java..." -ForegroundColor Yellow
try {
    $javaVersion = java -version 2>&1 | Select-Object -First 1
    Write-Host "   Java: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "   ERROR: Java not found!" -ForegroundColor Red
    Write-Host "   Please install Java 21 to run the backend" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Start ML Service
Write-Host "Starting ML Service (port 8000)..." -ForegroundColor Yellow
$mlServicePath = "E:\Pranav new laptop (kisikimummi)\JavaSpringbootBackend\CHD-EPICS\ml-service"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$mlServicePath'; Write-Host 'Starting ML Service...' -ForegroundColor Cyan; python -m uvicorn main:app --host 0.0.0.0 --port 8000" -WindowStyle Normal
Write-Host "   ML Service starting in new window..." -ForegroundColor Green
Start-Sleep -Seconds 5
Write-Host ""

# Start Backend
Write-Host "Starting Backend (port 8080)..." -ForegroundColor Yellow
$backendPath = "E:\Pranav new laptop (kisikimummi)\JavaSpringbootBackend\CHD-EPICS\backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; Write-Host 'Starting Backend...' -ForegroundColor Cyan; .\mvnw.cmd spring-boot:run" -WindowStyle Normal
Write-Host "   Backend starting in new window..." -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Services Starting..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ML Service: http://localhost:8000" -ForegroundColor Yellow
Write-Host "Backend API: http://localhost:8080/api" -ForegroundColor Yellow
Write-Host ""
Write-Host "Wait for both services to start, then run:" -ForegroundColor Cyan
Write-Host "  .\ml-service\test-ml-service.ps1" -ForegroundColor Green
Write-Host "  .\backend\test-ml-integration.ps1" -ForegroundColor Green
Write-Host ""





