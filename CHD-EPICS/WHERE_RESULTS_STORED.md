# Where Prediction Results Are Stored

## Overview

Prediction results are stored in **two places**:
1. **Database** - Stores prediction metadata and results
2. **MinIO** - Stores the actual scan images

---

## 1. Database Storage (H2 Database)

### Location
```
CHD-EPICS/backend/data/ecgcare.mv.db
```

### Database Type
- **H2 Database** (file-based, embedded)
- **Mode**: PostgreSQL compatibility mode
- **File Format**: `.mv.db` (H2 database file)

### Table: `ml_result`

The prediction results are stored in the `ml_result` table with the following structure:

| Column | Type | Description |
|--------|------|-------------|
| `result_id` | UUID (VARCHAR) | Primary key - unique result identifier |
| `patient_id` | UUID (VARCHAR) | Foreign key to `patient` table |
| `scan_id` | UUID (VARCHAR) | Foreign key to `ecg_scan` table (nullable) |
| `model_version` | VARCHAR(50) | Model version used (e.g., "v1.0") |
| `predicted_label` | VARCHAR(50) | Prediction result (Normal, ASD, or VSD) |
| `class_probs` | JSONB/VARCHAR | JSON object with all class probabilities |
| `threshold` | DECIMAL(5,4) | Confidence threshold used |
| `created_by` | UUID (VARCHAR) | Foreign key to `doctor` table |
| `created_at` | TIMESTAMP | When the prediction was made |

### Example Stored Data

For your test result:
```json
{
  "result_id": "06bafd4c-3538-4732-9794-9fe7dafa10b2",
  "patient_id": "f256cd4e-364e-4d0d-b8b2-45c5461b5b81",
  "scan_id": "b23f6fa6-07fe-4cb9-8357-b05cde2c32bd",
  "model_version": "v1.0",
  "predicted_label": "ASD",
  "class_probs": {
    "Normal": 0.0486,
    "ASD": 0.7816,
    "VSD": 0.1698
  },
  "threshold": 0.5,
  "created_by": "doctor-uuid",
  "created_at": "2025-11-24T16:39:49.20251Z"
}
```

### Accessing the Database

**Via H2 Console:**
1. Backend must be running
2. Open browser: `http://localhost:8080/h2-console`
3. Connection settings:
   - JDBC URL: `jdbc:h2:file:./data/ecgcare`
   - Username: `sa`
   - Password: (empty)
4. Click "Connect"
5. Run SQL queries:
   ```sql
   SELECT * FROM ml_result;
   SELECT * FROM ml_result WHERE predicted_label = 'ASD';
   SELECT * FROM ml_result ORDER BY created_at DESC;
   ```

**Via API:**
- Get result: `GET /api/ml/results/{resultId}`
- List patient predictions: `GET /api/patients/{patientId}/predictions`

---

## 2. MinIO Object Storage (Scan Images)

### Location
- **Service**: MinIO running in Docker container
- **Data Directory**: `CHD-EPICS/backend/minio-data/`
- **Bucket**: `ecg-bucket`
- **Storage Path**: `{patient_id}/{scan_id}/{filename}`

### What's Stored
- Original scan images (JPG, PNG, etc.)
- Stored as objects in MinIO
- Referenced by `storage_uri` in `ecg_scan` table

### Accessing MinIO

**Via Web Console:**
1. Open: `http://localhost:9001`
2. Login:
   - Access Key: `minio`
   - Secret Key: `minio12345`
3. Browse bucket: `ecg-bucket`
4. View/download scan images

**Via API:**
- Download scan: `GET /api/scans/{scanId}/download`

---

## 3. Related Tables

### `ecg_scan` Table
Stores scan metadata:
- `scan_id` - Unique scan identifier
- `patient_id` - Patient who owns the scan
- `storage_uri` - Path in MinIO where image is stored
- `mimetype` - Image format (image/jpeg, image/png)
- `uploaded_by` - Doctor who uploaded
- `uploaded_at` - Upload timestamp

### `patient` Table
Stores patient information (encrypted)

### `doctor` Table
Stores doctor information

---

## Summary

### Your Test Result Storage:

**Database (H2):**
- File: `CHD-EPICS/backend/data/ecgcare.mv.db`
- Table: `ml_result`
- Result ID: `06bafd4c-3538-4732-9794-9fe7dafa10b2`

**MinIO (Object Storage):**
- Container: `minio` (Docker)
- Bucket: `ecg-bucket`
- Scan ID: `b23f6fa6-07fe-4cb9-8357-b05cde2c32bd`
- Image stored at: `{patient_id}/{scan_id}/test_image.jpg`

---

## Viewing Your Results

### Option 1: H2 Console (Recommended)
```
1. Ensure backend is running
2. Open: http://localhost:8080/h2-console
3. Connect with:
   - JDBC URL: jdbc:h2:file:./data/ecgcare
   - Username: sa
   - Password: (leave empty)
4. Run: SELECT * FROM ml_result;
```

### Option 2: API Endpoint
```powershell
# Get specific result
GET http://localhost:8080/api/ml/results/{resultId}

# List all predictions for a patient
GET http://localhost:8080/api/patients/{patientId}/predictions
```

### Option 3: MinIO Console
```
1. Open: http://localhost:9001
2. Login: minio / minio12345
3. Browse: ecg-bucket
4. View uploaded scan images
```

---

## Database File Location (Full Path)

**Windows:**
```
C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\backend\data\ecgcare.mv.db
```

**Relative to Backend:**
```
./data/ecgcare.mv.db
```

---

## Important Notes

1. **H2 Database** is file-based - the `.mv.db` file contains all data
2. **Backup**: Copy the `data` folder to backup the database
3. **MinIO Data**: Stored in `backend/minio-data/` directory
4. **Persistence**: Both database and MinIO data persist between restarts
5. **Production**: Consider migrating to PostgreSQL/MySQL for production use






