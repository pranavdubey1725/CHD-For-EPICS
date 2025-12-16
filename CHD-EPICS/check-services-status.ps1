# Check Services Status Script
# This script checks if all CHD-EPICS services are running

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking CHD-EPICS Services Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allRunning = $true

# Check MinIO (Port 9000, 9001)
Write-Host "1. Checking MinIO (Port 9000, 9001)..." -ForegroundColor Yellow
try {
    $minioCheck = docker ps --filter "name=minio" --format "{{.Names}}" 2>&1
    if ($minioCheck -eq "minio") {
        Write-Host "   ✅ MinIO is RUNNING" -ForegroundColor Green
        Write-Host "      Console: http://localhost:9001" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ MinIO is NOT RUNNING" -ForegroundColor Red
        Write-Host "      Run: docker start minio" -ForegroundColor Gray
        $allRunning = $false
    }
} catch {
    Write-Host "   ❌ MinIO check failed - Docker might not be running" -ForegroundColor Red
    $allRunning = $false
}
Write-Host ""

# Check ML Service (Port 8000)
Write-Host "2. Checking ML Service (Port 8000)..." -ForegroundColor Yellow
try {
    $mlResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($mlResponse.StatusCode -eq 200) {
        Write-Host "   ✅ ML Service is RUNNING" -ForegroundColor Green
        Write-Host "      Health: http://localhost:8000/health" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ ML Service returned unexpected status" -ForegroundColor Red
        $allRunning = $false
    }
} catch {
    Write-Host "   ❌ ML Service is NOT RUNNING" -ForegroundColor Red
    Write-Host "      Start with: cd ml-service; python main.py" -ForegroundColor Gray
    $allRunning = $false
}
Write-Host ""

# Check Backend (Port 8080)
Write-Host "3. Checking Backend (Port 8080)..." -ForegroundColor Yellow
try {
    $backendResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($backendResponse.StatusCode -eq 200) {
        Write-Host "   ✅ Backend is RUNNING" -ForegroundColor Green
        Write-Host "      Health: http://localhost:8080/api/health" -ForegroundColor Gray
        
        # Try to get response body
        try {
            $healthData = $backendResponse.Content | ConvertFrom-Json
            Write-Host "      Status: $($healthData.status)" -ForegroundColor Gray
        } catch {
            Write-Host "      Status: OK" -ForegroundColor Gray
        }
    } else {
        Write-Host "   ❌ Backend returned unexpected status" -ForegroundColor Red
        $allRunning = $false
    }
} catch {
    Write-Host "   ❌ Backend is NOT RUNNING" -ForegroundColor Red
    Write-Host "      Start with: cd backend; .\mvnw.cmd spring-boot:run" -ForegroundColor Gray
    $allRunning = $false
}
Write-Host ""

# Check Frontend (Port 3000)
Write-Host "4. Checking Frontend (Port 3000)..." -ForegroundColor Yellow
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000/main.html" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "   ✅ Frontend is RUNNING" -ForegroundColor Green
        Write-Host "      URL: http://localhost:3000/main.html" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ Frontend returned unexpected status" -ForegroundColor Red
        $allRunning = $false
    }
} catch {
    Write-Host "   ❌ Frontend is NOT RUNNING" -ForegroundColor Red
    Write-Host "      Start with: cd frontend; python -m http.server 3000" -ForegroundColor Gray
    $allRunning = $false
}
Write-Host ""

# Check ports in use
Write-Host "5. Checking which processes are using required ports..." -ForegroundColor Yellow
$ports = @(8080, 8000, 3000, 9000, 9001)
foreach ($port in $ports) {
    try {
        $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($connections) {
            $process = Get-Process -Id $connections.OwningProcess -ErrorAction SilentlyContinue
            if ($process) {
                Write-Host "   Port $port : $($process.ProcessName) (PID: $($process.Id))" -ForegroundColor Gray
            } else {
                Write-Host "   Port $port : Unknown process" -ForegroundColor Gray
            }
        } else {
            Write-Host "   Port $port : NOT IN USE" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   Port $port : Could not check" -ForegroundColor Yellow
    }
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
if ($allRunning) {
    Write-Host "✅ ALL SERVICES ARE RUNNING!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now:" -ForegroundColor Cyan
    Write-Host "  • Open: http://localhost:3000/main.html" -ForegroundColor White
    Write-Host "  • Login or Sign Up" -ForegroundColor White
} else {
    Write-Host "❌ SOME SERVICES ARE NOT RUNNING" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the missing services:" -ForegroundColor Yellow
    Write-Host "  1. MinIO: docker start minio" -ForegroundColor White
    Write-Host "  2. ML Service: cd ml-service; python main.py" -ForegroundColor White
    Write-Host "  3. Backend: cd backend; .\mvnw.cmd spring-boot:run" -ForegroundColor White
    Write-Host "  4. Frontend: cd frontend; python -m http.server 3000" -ForegroundColor White
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""




