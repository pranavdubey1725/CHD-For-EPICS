# MinIO Setup Complete ✅

## Summary

✅ **Test Image Created**: `CHD-EPICS\ml-service\test_image.jpg` (3.21 KB)

## MinIO Setup

### Option 1: Using Docker (Recommended)

**Prerequisites:**
- Docker Desktop installed and running

**Steps:**
1. Ensure Docker Desktop is running (check system tray for whale icon)
2. Run the setup script:
   ```powershell
   cd CHD-EPICS
   .\start-minio-docker.ps1
   ```

**What it does:**
- Creates MinIO container named `minio`
- Exposes ports:
  - 9000: API endpoint
  - 9001: Web console
- Uses credentials: `minio` / `minio12345`
- Creates data directory: `backend\minio-data`

### Option 2: Manual Docker Command

If the script doesn't work, run manually:

```powershell
cd CHD-EPICS\backend
docker run -d --name minio `
  -p 9000:9000 -p 9001:9001 `
  -e "MINIO_ROOT_USER=minio" `
  -e "MINIO_ROOT_PASSWORD=minio12345" `
  -v "${PWD}\minio-data:/data" `
  minio/minio server /data --console-address ":9001"
```

### Option 3: Standalone MinIO (if Docker not available)

1. Download MinIO from: https://min.io/download
2. Extract to a folder (e.g., `CHD-EPICS\backend\minio`)
3. Create data directory: `CHD-EPICS\backend\minio\data`
4. Run:
   ```powershell
   cd CHD-EPICS\backend\minio
   $env:MINIO_ROOT_USER="minio"
   $env:MINIO_ROOT_PASSWORD="minio12345"
   .\minio.exe server .\data --console-address ":9001"
   ```

## Verification

After starting MinIO, verify it's running:

```powershell
# Check health
Invoke-WebRequest -Uri "http://localhost:9000/minio/health/live"

# Check console
Start-Process "http://localhost:9001"
```

**Login to console:**
- Access Key: `minio`
- Secret Key: `minio12345`

## Configuration

The backend is already configured in `application.yml`:
```yaml
minio:
  endpoint: http://localhost:9000
  accessKey: minio
  secretKey: minio12345
  bucket: ecg-bucket
```

**Note:** The `ecg-bucket` will be created automatically by the backend on first startup.

## Test Image

✅ Test image available at: `CHD-EPICS\ml-service\test_image.jpg`

You can also use any JPG/PNG image file for testing.

## Next Steps

Once MinIO is running:

1. ✅ MinIO running on port 9000
2. ✅ Test image ready
3. ✅ Backend configured
4. ✅ ML Service ready

**Run the complete test:**
```powershell
cd CHD-EPICS
.\test-prediction-complete.ps1
```

## Troubleshooting

### Docker not starting
- Ensure Docker Desktop is fully started (whale icon in system tray)
- Check Docker Desktop logs
- Try restarting Docker Desktop

### Port 9000 already in use
- Check what's using the port: `netstat -ano | findstr :9000`
- Stop the process or use different ports

### MinIO container fails to start
- Check Docker logs: `docker logs minio`
- Ensure data directory has proper permissions
- Try removing and recreating: `docker rm minio` then run script again

### Backend can't connect to MinIO
- Verify MinIO is running: `docker ps | findstr minio`
- Check MinIO health: `http://localhost:9000/minio/health/live`
- Verify credentials match in `application.yml`






