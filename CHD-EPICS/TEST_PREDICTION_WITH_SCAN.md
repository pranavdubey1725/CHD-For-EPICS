# Testing Prediction with Real Scan - Step by Step Guide

## Overview

Scans are **uploaded via API** (not to a file location). The backend stores them in MinIO object storage, then you can request predictions on the uploaded scan.

## Test Flow

```
1. Login/Register Doctor
2. Create Patient
3. Upload Scan Image (via API)
4. Request Prediction (backend calls ML service)
5. View Results
```

## Step-by-Step Test

### Prerequisites

- ✅ Backend running on `http://localhost:8080`
- ✅ ML Service running on `http://localhost:8000`
- ✅ MinIO running (for scan storage) - **IMPORTANT**
- Image file ready (JPG, PNG, etc.)

### Step 1: Prepare Your Test Image

You can use:
- The existing `test_image.jpg` from `CHD-EPICS/ml-service/test_image.jpg`
- Any ECG/medical scan image you have
- Any image file for testing (JPG, PNG format)

**Location doesn't matter** - you'll upload it via API.

### Step 2: Run the Test Script

I'll create a PowerShell script that does everything automatically.

### Manual Testing (if preferred)

**1. Login/Register:**
```powershell
$loginBody = '{"email":"test@example.com","password":"Test123!"}'
$loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" `
    -Method POST -Body $loginBody -ContentType "application/json"
$token = $loginResponse.data.accessToken
```

**2. Create Patient:**
```powershell
$headers = @{"Authorization" = "Bearer $token"}
$patientBody = '{"patientData":{"name":"Test Patient","age":50,"gender":"M"}}'
$patientResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/patients" `
    -Method POST -Body $patientBody -ContentType "application/json" -Headers $headers
$patientId = $patientResponse.data.patientId
```

**3. Upload Scan:**
```powershell
$imagePath = "C:\path\to\your\image.jpg"  # Your image file
$boundary = [System.Guid]::NewGuid().ToString()
$fileBytes = [System.IO.File]::ReadAllBytes($imagePath)

# Build multipart form data
$bodyBuilder = New-Object System.Text.StringBuilder
$bodyBuilder.Append("--$boundary`r`n") | Out-Null
$bodyBuilder.Append("Content-Disposition: form-data; name=`"file`"; filename=`"image.jpg`"`r`n") | Out-Null
$bodyBuilder.Append("Content-Type: image/jpeg`r`n`r`n") | Out-Null
$bodyBuilder.Append([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($fileBytes)) | Out-Null
$bodyBuilder.Append("`r`n--$boundary--`r`n") | Out-Null

$bodyBytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($bodyBuilder.ToString())
$headers["Content-Type"] = "multipart/form-data; boundary=$boundary"

$uploadResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/scans/upload?patientId=$patientId" `
    -Method POST -Body $bodyBytes -Headers $headers
$scanId = $uploadResponse.data.scanId
```

**4. Request Prediction:**
```powershell
$predictBody = '{"modelVersion":"v1.0","threshold":0.5}'
$predictResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/ml/predict/$scanId" `
    -Method POST -Body $predictBody -ContentType "application/json" -Headers $headers

Write-Host "Prediction: $($predictResponse.data.predictedLabel)"
Write-Host "Confidence: $($predictResponse.data.confidenceScore)"
Write-Host "Class Probabilities:"
$predictResponse.data.classProbabilities | ConvertTo-Json
```

## Important Notes

### MinIO Requirement

**The backend requires MinIO to be running** for scan uploads. MinIO is the object storage service.

**To start MinIO:**
```powershell
# Using Docker
docker run -p 9000:9000 -p 9001:9001 `
  -e "MINIO_ROOT_USER=minio" `
  -e "MINIO_ROOT_PASSWORD=minio12345" `
  minio/minio server /data --console-address ":9001"
```

**Or download MinIO:**
- Download from https://min.io/download
- Run: `minio server .\data --console-address ":9001"`

**MinIO Configuration** (in `application.yml`):
```yaml
minio:
  endpoint: http://localhost:9000
  accessKey: minio
  secretKey: minio12345
  bucket: ecg-bucket
```

### Image Requirements

- **Format**: JPG, PNG, or any image format
- **Size**: Max 10MB (configurable)
- **Content**: Any image (for testing, real ECG scans for production)

## Quick Test Script

I'll create a complete test script that handles all steps automatically.






