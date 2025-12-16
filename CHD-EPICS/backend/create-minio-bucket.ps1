# Create MinIO Bucket Script
# This script creates the ecg-bucket in MinIO

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating MinIO Bucket" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if MinIO Client (mc) is available
$mcExe = "$PSScriptRoot\minio\mc.exe"

if (-not (Test-Path $mcExe)) {
    Write-Host "MinIO Client (mc.exe) not found." -ForegroundColor Yellow
    Write-Host "Please download from: https://dl.min.io/client/mc/release/windows-amd64/mc.exe" -ForegroundColor Yellow
    Write-Host "Place it at: $mcExe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Create bucket manually via MinIO Console:" -ForegroundColor Cyan
    Write-Host "  1. Open http://localhost:9001" -ForegroundColor Yellow
    Write-Host "  2. Login with minio / minio12345" -ForegroundColor Yellow
    Write-Host "  3. Click 'Buckets' -> 'Create Bucket'" -ForegroundColor Yellow
    Write-Host "  4. Bucket name: ecg-bucket" -ForegroundColor Yellow
    Write-Host ""
    
    $download = Read-Host "Do you want to download MinIO Client now? (Y/N)"
    if ($download -eq "Y" -or $download -eq "y") {
        try {
            Write-Host "Downloading MinIO Client..." -ForegroundColor Yellow
            $mcDir = Split-Path $mcExe
            if (-not (Test-Path $mcDir)) {
                New-Item -ItemType Directory -Path $mcDir | Out-Null
            }
            Invoke-WebRequest -Uri "https://dl.min.io/client/mc/release/windows-amd64/mc.exe" -OutFile $mcExe -UseBasicParsing
            Write-Host "Download complete!" -ForegroundColor Green
        } catch {
            Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Please create bucket manually via console" -ForegroundColor Yellow
            exit 1
        }
    } else {
        exit 0
    }
}

# Configure MinIO client
Write-Host "Configuring MinIO client..." -ForegroundColor Yellow
& $mcExe alias set local http://localhost:9000 minio minio12345 2>&1 | Out-Null

# Check if bucket exists
Write-Host "Checking if bucket exists..." -ForegroundColor Yellow
$bucketExists = & $mcExe ls local/ecg-bucket 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "Bucket 'ecg-bucket' already exists!" -ForegroundColor Green
} else {
    # Create bucket
    Write-Host "Creating bucket 'ecg-bucket'..." -ForegroundColor Yellow
    & $mcExe mb local/ecg-bucket
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Bucket 'ecg-bucket' created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to create bucket. Please create manually via console." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "MinIO is ready!" -ForegroundColor Green
Write-Host ""





