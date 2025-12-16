# Start MinIO Server
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting MinIO Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$minioDir = "$PSScriptRoot\minio"
$minioExe = "$minioDir\minio.exe"
$dataDir = "$minioDir\data"

# Check if MinIO exists
if (-not (Test-Path $minioExe)) {
    Write-Host "ERROR: MinIO executable not found!" -ForegroundColor Red
    Write-Host "Please run: .\setup-minio.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Check if already running
$existingProcess = Get-NetTCPConnection -LocalPort 9000 -ErrorAction SilentlyContinue
if ($existingProcess) {
    Write-Host "MinIO is already running on port 9000" -ForegroundColor Yellow
    $pid = $existingProcess.OwningProcess
    Write-Host "Process ID: $pid" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To stop it, run: Stop-Process -Id $pid -Force" -ForegroundColor Yellow
    exit 0
}

# Set environment variables
$env:MINIO_ROOT_USER = "minio"
$env:MINIO_ROOT_PASSWORD = "minio12345"

Write-Host "MinIO Configuration:" -ForegroundColor Cyan
Write-Host "  Server: http://localhost:9000" -ForegroundColor Yellow
Write-Host "  Console: http://localhost:9001" -ForegroundColor Yellow
Write-Host "  Access Key: minio" -ForegroundColor Yellow
Write-Host "  Secret Key: minio12345" -ForegroundColor Yellow
Write-Host "  Data Directory: $dataDir" -ForegroundColor Yellow
Write-Host ""

Write-Host "Starting MinIO server..." -ForegroundColor Green
Write-Host "Keep this window open to run MinIO." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Gray
Write-Host ""

# Start MinIO
& $minioExe server $dataDir --console-address ":9001"





