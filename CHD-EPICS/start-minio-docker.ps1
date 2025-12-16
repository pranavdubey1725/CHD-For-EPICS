# Start MinIO using Docker
# This script starts MinIO in a Docker container

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting MinIO with Docker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker ps 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker is not running!" -ForegroundColor Red
        Write-Host "Please start Docker Desktop first" -ForegroundColor Yellow
        Write-Host "Then run this script again" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not available!" -ForegroundColor Red
    Write-Host "Please install Docker Desktop or start it" -ForegroundColor Yellow
    exit 1
}

# Check if MinIO container already exists
$existingContainer = docker ps -a --filter "name=minio" --format "{{.Names}}" 2>&1
if ($existingContainer -and $existingContainer -eq "minio") {
    Write-Host "`nMinIO container exists. Checking if running..." -ForegroundColor Yellow
    $running = docker ps --filter "name=minio" --format "{{.Names}}" 2>&1
    if ($running -eq "minio") {
        Write-Host "✅ MinIO is already running!" -ForegroundColor Green
        Write-Host ""
        Write-Host "MinIO Configuration:" -ForegroundColor Cyan
        Write-Host "  API: http://localhost:9000" -ForegroundColor White
        Write-Host "  Console: http://localhost:9001" -ForegroundColor White
        Write-Host "  Access Key: minio" -ForegroundColor White
        Write-Host "  Secret Key: minio12345" -ForegroundColor White
        exit 0
    } else {
        Write-Host "Starting existing container..." -ForegroundColor Yellow
        docker start minio 2>&1 | Out-Host
        Start-Sleep -Seconds 3
    }
} else {
    Write-Host "Creating MinIO container..." -ForegroundColor Yellow
    
    # Create data directory
    $dataDir = "$PSScriptRoot\backend\minio-data"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
        Write-Host "Created data directory: $dataDir" -ForegroundColor Gray
    }
    
    # Convert to Docker path format
    $dockerDataPath = $dataDir -replace '\\', '/'
    if ($dockerDataPath -match '^[A-Z]:') {
        # Windows absolute path - Docker needs /c/ format
        $drive = $dockerDataPath.Substring(0, 1).ToLower()
        $dockerDataPath = "/$drive" + $dockerDataPath.Substring(2) -replace '\\', '/'
    }
    
    Write-Host "Starting MinIO container..." -ForegroundColor Yellow
    docker run -d `
        --name minio `
        -p 9000:9000 `
        -p 9001:9001 `
        -e "MINIO_ROOT_USER=minio" `
        -e "MINIO_ROOT_PASSWORD=minio12345" `
        -v "${dataDir}:/data" `
        minio/minio server /data --console-address ":9001" 2>&1 | Out-Host
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ MinIO container created and started!" -ForegroundColor Green
        Start-Sleep -Seconds 3
    } else {
        Write-Host "❌ Failed to start MinIO container" -ForegroundColor Red
        exit 1
    }
}

# Verify MinIO is running
Write-Host "`nVerifying MinIO is running..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$maxAttempts = 6
for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9000/minio/health/live" -Method Get -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ MinIO is running and healthy!" -ForegroundColor Green
            break
        }
    } catch {
        if ($i -eq $maxAttempts) {
            Write-Host "⚠️  MinIO may still be starting. Check manually:" -ForegroundColor Yellow
            Write-Host "   http://localhost:9000/minio/health/live" -ForegroundColor Gray
        } else {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds 2
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MinIO Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoint: http://localhost:9000" -ForegroundColor White
Write-Host "Web Console:  http://localhost:9001" -ForegroundColor White
Write-Host ""
Write-Host "Credentials:" -ForegroundColor Yellow
Write-Host "  Access Key: minio" -ForegroundColor White
Write-Host "  Secret Key: minio12345" -ForegroundColor White
Write-Host ""
Write-Host "Bucket: ecg-bucket (will be created automatically by backend)" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ MinIO is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "To stop MinIO, run: docker stop minio" -ForegroundColor Gray
Write-Host "To remove MinIO, run: docker rm minio" -ForegroundColor Gray






