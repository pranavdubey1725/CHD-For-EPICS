# MinIO Setup Script for Windows
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MinIO Setup for CHD-EPICS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$minioDir = "$PSScriptRoot\minio"
$minioExe = "$minioDir\minio.exe"
$dataDir = "$minioDir\data"

# Create directories
if (-not (Test-Path $minioDir)) {
    New-Item -ItemType Directory -Path $minioDir | Out-Null
    Write-Host "Created MinIO directory: $minioDir" -ForegroundColor Green
}

if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
    Write-Host "Created data directory: $dataDir" -ForegroundColor Green
}

# Check if MinIO already exists
if (Test-Path $minioExe) {
    Write-Host "MinIO executable found: $minioExe" -ForegroundColor Green
}
else {
    Write-Host "MinIO executable not found. Downloading..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Downloading MinIO..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "https://dl.min.io/server/minio/release/windows-amd64/minio.exe" -OutFile $minioExe -UseBasicParsing -ErrorAction Stop
        Write-Host "Download complete!" -ForegroundColor Green
    }
    catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please download MinIO manually from:" -ForegroundColor Yellow
        Write-Host "  https://dl.min.io/server/minio/release/windows-amd64/minio.exe" -ForegroundColor Cyan
        Write-Host "Place it at: $minioExe" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "MinIO setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "To start MinIO, run:" -ForegroundColor Cyan
Write-Host "  .\start-minio.ps1" -ForegroundColor Yellow
Write-Host ""

