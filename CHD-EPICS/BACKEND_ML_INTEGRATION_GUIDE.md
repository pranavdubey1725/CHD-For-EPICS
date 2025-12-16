# Backend-ML Service Integration Guide

This guide explains how the Java Spring Boot backend integrates with the Python ML service for CHD (Congenital Heart Disease) predictions.

## Architecture Overview

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  Java Backend   │────────▶│   ML Service     │────────▶│  ConvNeXt Model │
│  (Spring Boot)  │  HTTP   │   (FastAPI)      │         │  (PyTorch)      │
│  Port: 8080     │  POST   │   Port: 8000     │         │  Local Files    │
└─────────────────┘         └──────────────────┘         └─────────────────┘
```

## Integration Flow

1. **Doctor requests prediction** via `/api/ml/predict/{scanId}`
2. **Backend downloads scan** from MinIO object storage
3. **Backend converts image** to base64 encoding
4. **Backend calls ML service** at `http://localhost:8000/predict`
5. **ML service processes image** using ConvNeXt model
6. **ML service returns** prediction with confidence scores
7. **Backend saves result** to database and returns to client

## Configuration

### Backend Configuration (`application.yml`)

```yaml
ml:
  service-url: http://localhost:8000
  predict-endpoint: /predict
  connect-timeout-seconds: 5
  read-timeout-seconds: 60
  max-retries: 3
  retry-delay-seconds: 2
  max-image-size-bytes: 10485760  # 10MB
```

### ML Service Configuration (`.env`)

```env
MODEL_PATH=./models/chd-classifier
```

## API Endpoints

### Backend Endpoint

**POST** `/api/ml/predict/{scanId}`

**Request Body (Optional):**
```json
{
  "modelVersion": "v1.0",
  "threshold": 0.5
}
```

**Response:**
```json
{
  "success": true,
  "message": "Prediction completed",
  "data": {
    "resultId": "uuid",
    "scanId": "uuid",
    "patientId": "uuid",
    "modelVersion": "v1.0",
    "predictedLabel": "ASD",
    "confidenceScore": 0.7816,
    "classProbabilities": {
      "Normal": 0.1234,
      "ASD": 0.7816,
      "VSD": 0.0950
    },
    "threshold": 0.5,
    "createdBy": "uuid",
    "createdAt": "2025-11-24T21:00:00Z"
  }
}
```

### ML Service Endpoint

**POST** `http://localhost:8000/predict`

**Request:**
```json
{
  "scan_id": "uuid-string",
  "image_data": "base64-encoded-image-string"
}
```

**Response:**
```json
{
  "scan_id": "uuid-string",
  "prediction": "ASD",
  "confidence_score": 0.7816,
  "class_probabilities": {
    "Normal": 0.1234,
    "ASD": 0.7816,
    "VSD": 0.0950
  },
  "status": "COMPLETED"
}
```

## Model Classes

The ConvNeXt model classifies images into **3 classes**:

1. **Normal** (Index: 0) - No congenital heart defect detected
2. **ASD** (Index: 1) - Atrial Septal Defect
3. **VSD** (Index: 2) - Ventricular Septal Defect

## Error Handling

### Backend Error Responses

- **404 Not Found**: Scan not found or no access
- **500 Internal Server Error**: ML service unavailable or error
- **503 Service Unavailable**: ML service timeout after retries

### ML Service Error Responses

- **400 Bad Request**: Invalid image data or missing fields
- **500 Internal Server Error**: Model not loaded or processing error

### Retry Logic

The backend implements automatic retry with exponential backoff:
- **Max retries**: 3 attempts
- **Base delay**: 2 seconds
- **Backoff**: Exponential (2s, 4s, 8s)
- **Retries on**: 5xx errors, timeouts, connection errors
- **No retry on**: 4xx client errors

## Testing the Integration

### 1. Start ML Service

```powershell
cd CHD-EPICS\ml-service
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Verify it's running:
```powershell
Invoke-RestMethod -Uri http://localhost:8000/ -Method Get
```

### 2. Start Backend

```powershell
cd CHD-EPICS\backend
./mvnw spring-boot:run
```

Or if using IDE, run the main Spring Boot application.

### 3. Test End-to-End

**Prerequisites:**
- Doctor registered and logged in
- Patient created
- Scan uploaded to MinIO

**Test Prediction:**

```powershell
# Get JWT token first (from login)
$token = "your-jwt-token"
$scanId = "your-scan-uuid"

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    modelVersion = "v1.0"
    threshold = 0.5
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/ml/predict/$scanId" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

## Troubleshooting

### ML Service Not Responding

**Symptoms:**
- Backend logs show "ML service unavailable"
- 503 Service Unavailable errors

**Solutions:**
1. Check ML service is running: `curl http://localhost:8000/`
2. Verify port 8000 is not blocked by firewall
3. Check ML service logs for errors
4. Verify model loaded correctly (check startup logs)

### Model Not Loading

**Symptoms:**
- ML service returns 500 error
- Logs show "ML model not loaded"

**Solutions:**
1. Check `.env` file exists and `MODEL_PATH` is correct
2. Verify model files exist:
   - `config.json`
   - `model.safetensors`
   - `preprocessor_config.json`
3. Check Python dependencies: `pip install -r requirements.txt`
4. Review ML service startup logs

### Wrong Predictions

**Symptoms:**
- Predictions don't match expected classes
- Confidence scores seem incorrect

**Solutions:**
1. Verify model is trained on correct dataset
2. Check `config.json` has correct `id2label` mapping
3. Ensure image preprocessing matches training
4. Verify image format (should be same as training data)

### Image Size Errors

**Symptoms:**
- "Image size exceeds maximum" error

**Solutions:**
1. Check `max-image-size-bytes` in `application.yml`
2. Compress or resize images before upload
3. Adjust limit if needed (default: 10MB)

## Monitoring

### Backend Logs

Check for:
- `Calling ML service for scan {scanId}`
- `ML prediction completed for scan {scanId}: {label} (confidence: {score})`
- `ML service call attempt {attempt}/{maxRetries}`

### ML Service Logs

Check for:
- `--- Loading model from: ...`
- `--- Model loaded successfully!`
- `--- Prediction complete ---`
- `--- Predicted class: {label} (index: {idx}) ---`

## Performance Considerations

- **Model Loading**: Happens once at startup (~30-60 seconds)
- **Prediction Time**: ~1-3 seconds per image (depends on hardware)
- **Image Size**: Larger images take longer to process
- **Concurrent Requests**: ML service handles multiple requests sequentially

## Security Considerations

1. **Authentication**: Backend requires JWT token
2. **Authorization**: Doctor must have access to patient's scans
3. **Image Validation**: Size limits prevent DoS attacks
4. **Network**: ML service should be on internal network (not exposed publicly)

## Next Steps

1. ✅ ML service integrated with ConvNeXt model
2. ✅ Backend updated to handle 3 classes (Normal, ASD, VSD)
3. ✅ Class probabilities returned for all classes
4. ⏭️ Add model versioning support
5. ⏭️ Add prediction explanation/visualization
6. ⏭️ Add batch prediction support
7. ⏭️ Add prediction history and analytics






