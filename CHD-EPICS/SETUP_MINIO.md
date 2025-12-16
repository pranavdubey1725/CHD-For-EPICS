# MinIO Setup Guide

## Why MinIO?

MinIO is used as object storage for ECG scan images. The backend stores uploaded images in MinIO and retrieves them when calling the ML service for predictions.

## Quick Setup (Docker - Recommended)

### 1. Start MinIO with Docker

```powershell
docker run -d -p 9000:9000 -p 9001:9001 `
  --name minio `
  -e "MINIO_ROOT_USER=minio" `
  -e "MINIO_ROOT_PASSWORD=minio12345" `
  quay.io/minio/minio server /data --console-address ":9001"
```

### 2. Access MinIO Console

- URL: http://localhost:9001
- Username: `minio`
- Password: `minio12345`

### 3. Create Bucket

1. Log into MinIO Console
2. Click "Buckets" → "Create Bucket"
3. Bucket Name: `ecg-bucket`
4. Click "Create Bucket"

## Manual Setup

### 1. Download MinIO

Download from: https://min.io/download

### 2. Start MinIO Server

```powershell
# Windows
minio.exe server C:\minio-data --console-address ":9001"

# Or use the executable directly
.\minio.exe server ./data --console-address ":9001"
```

### 3. Configure Access

- Access Key: `minio` (or set via environment variable `MINIO_ROOT_USER`)
- Secret Key: `minio12345` (or set via environment variable `MINIO_ROOT_PASSWORD`)

### 4. Create Bucket

Access console at http://localhost:9001 and create bucket `ecg-bucket`

## Verify Setup

### Check MinIO is Running

```powershell
# Test connection
Invoke-WebRequest -Uri "http://localhost:9000/minio/health/live" -Method GET
```

### Update Backend Configuration

The backend is already configured in `application.yml`:
```yaml
minio:
  endpoint: http://localhost:9000
  accessKey: minio
  secretKey: minio12345
  bucket: ecg-bucket
```

## Testing After Setup

Once MinIO is running, you can test the complete flow:

```powershell
# Run full integration test
.\backend\test-ml-integration.ps1
```

This will:
1. Register a doctor
2. Login
3. Create a patient
4. Upload an ECG scan (now works with MinIO)
5. Request ML prediction
6. Verify result is saved

## Troubleshooting

### Connection Refused
- Ensure MinIO is running on port 9000
- Check firewall settings
- Verify endpoint in `application.yml`

### Bucket Not Found
- Create bucket `ecg-bucket` via MinIO console
- Ensure bucket name matches configuration

### Access Denied
- Verify access key and secret key
- Check MinIO user permissions

---

**Once MinIO is set up, the complete integration will work end-to-end!**





