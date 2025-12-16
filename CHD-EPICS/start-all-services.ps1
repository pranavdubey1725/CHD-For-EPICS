# Start All Services Script
# Starts Backend, ML Service, and MinIO

Write-Host "=== Starting All Services ===" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running (for MinIO)
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Start MinIO
Write-Host "`n1. Starting MinIO..." -ForegroundColor Yellow
$minioProcess = Start-Process -FilePath "docker" -ArgumentList "run -d --name minio -p 9000:9000 -p 9001:9001 -v `"${PWD}\backend\minio-data:/data`" -e `"MINIO_ROOT_USER=minio`" -e `"MINIO_ROOT_PASSWORD=minio12345`" minio/minio server /data --console-address `":9001`"" -PassThru -NoNewWindow
Start-Sleep -Seconds 3
Write-Host "   MinIO starting on ports 9000 and 9001" -ForegroundColor Gray
Write-Host "   Console: http://localhost:9001 (minio/minio12345)" -ForegroundColor Gray

# Start ML Service
Write-Host "`n2. Starting ML Service..." -ForegroundColor Yellow
$mlServicePath = Join-Path $PWD "ml-service"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$mlServicePath'; Write-Host 'Starting ML Service...' -ForegroundColor Cyan; python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload" -WindowStyle Normal
Start-Sleep -Seconds 2
Write-Host "   ML Service starting on port 8000" -ForegroundColor Gray
Write-Host "   Health: http://localhost:8000/health" -ForegroundColor Gray

# Start Backend
Write-Host "`n3. Starting Spring Boot Backend..." -ForegroundColor Yellow
$backendPath = Join-Path $PWD "backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; Write-Host 'Starting Backend...' -ForegroundColor Cyan; .\mvnw.cmd spring-boot:run" -WindowStyle Normal
Start-Sleep -Seconds 2
Write-Host "   Backend starting on port 8080" -ForegroundColor Gray
Write-Host "   Health: http://localhost:8080/api/health" -ForegroundColor Gray

Write-Host "`n=== Services Starting ===" -ForegroundColor Cyan
Write-Host "`nAll services are starting in separate windows." -ForegroundColor Yellow
Write-Host "Please wait 30-60 seconds for all services to fully start." -ForegroundColor Yellow
Write-Host "`nTo verify services are running, run:" -ForegroundColor Yellow
Write-Host "  .\test-integration.ps1" -ForegroundColor White
Write-Host "`nOnce services are ready:" -ForegroundColor Yellow
Write-Host "  1. Start frontend: cd frontend; python -m http.server 3000" -ForegroundColor White
Write-Host "  2. Open: http://localhost:3000/login.html" -ForegroundColor White
Write-Host ""






