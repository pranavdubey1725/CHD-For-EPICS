# Quick Start Guide - All Services

## Prerequisites Check

Run this to verify all services:
```powershell
# Check services status
Write-Host "Checking services..." -ForegroundColor Cyan
try { Invoke-RestMethod -Uri "http://localhost:8080/api/health" | Out-Null; Write-Host "✅ Backend: RUNNING" -ForegroundColor Green } catch { Write-Host "❌ Backend: NOT RUNNING" -ForegroundColor Red }
try { Invoke-RestMethod -Uri "http://localhost:8000/" | Out-Null; Write-Host "✅ ML Service: RUNNING" -ForegroundColor Green } catch { Write-Host "❌ ML Service: NOT RUNNING" -ForegroundColor Red }
try { Invoke-WebRequest -Uri "http://localhost:9000/minio/health/live" | Out-Null; Write-Host "✅ MinIO: RUNNING" -ForegroundColor Green } catch { Write-Host "❌ MinIO: NOT RUNNING" -ForegroundColor Red }
```

## Starting All Services

### 1. Start Backend (Spring Boot)
```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

### 2. Start ML Service (FastAPI)
```powershell
cd ml-service
python -m uvicorn main:app --host 127.0.0.1 --port 8000
```

### 3. Start MinIO
```powershell
cd backend
.\start-minio.ps1
```

### 4. Create MinIO Bucket (if not exists)
```powershell
cd backend
.\create-minio-bucket.ps1
```

Or manually:
1. Open http://localhost:9001
2. Login: `minio` / `minio12345`
3. Create bucket: `ecg-bucket`

## Running Tests

### Test Backend
```powershell
cd backend
.\test-health.ps1
```

### Test ML Service
```powershell
cd ml-service
.\test-ml-service.ps1
```

### Full Integration Test
```powershell
cd backend
.\test-ml-integration.ps1
```

## Service URLs

- **Backend API**: http://localhost:8080/api
- **ML Service**: http://localhost:8000
- **MinIO Server**: http://localhost:9000
- **MinIO Console**: http://localhost:9001

## Default Credentials

### MinIO
- Access Key: `minio`
- Secret Key: `minio12345`
- Bucket: `ecg-bucket`

## Troubleshooting

### Port Already in Use
```powershell
# Check what's using the port
Get-NetTCPConnection -LocalPort 8000  # ML Service
Get-NetTCPConnection -LocalPort 8080  # Backend
Get-NetTCPConnection -LocalPort 9000  # MinIO

# Kill process
Stop-Process -Id <PID> -Force
```

### MinIO Bucket Missing
- Create via console at http://localhost:9001
- Or run: `.\create-minio-bucket.ps1`

### ML Service Model Loading
- First run downloads model (~400MB)
- Takes 1-2 minutes to load
- Check window for "Model loaded successfully!" message





