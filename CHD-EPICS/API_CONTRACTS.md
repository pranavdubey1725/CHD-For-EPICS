# CHD-EPICS: API Contracts Documentation

This document defines all REST API contracts for the CHD-EPICS system.

**Base URL**: `http://localhost:8080/api` (Spring Boot Backend)  
**ML Service URL**: `http://localhost:8000` (FastAPI ML Service)

**Authentication**: All endpoints (except auth endpoints) require JWT Bearer token in Authorization header.

---

## Table of Contents
1. [Authentication APIs](#authentication-apis)
2. [Patient Management APIs](#patient-management-apis)
3. [ECG Scan APIs](#ecg-scan-apis)
4. [ML Prediction APIs](#ml-prediction-apis)
5. [Access Management APIs](#access-management-apis)
6. [Draft Management APIs](#draft-management-apis)
7. [ML Service APIs](#ml-service-apis)
8. [Error Responses](#error-responses)
9. [Data Models](#data-models)

---

## Authentication APIs

### 1. Register Doctor

**Endpoint**: `POST /api/auth/register`

**Description**: Register a new doctor account. Creates doctor profile, authentication credentials, and cryptographic keys.

**Request Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "email": "doctor@example.com",
  "password": "SecurePassword123!",
  "fullName": "Dr. John Smith",
  "phone": "+1234567890"
}
```

**Request Schema**:
```json
{
  "type": "object",
  "required": ["email", "password", "fullName"],
  "properties": {
    "email": {
      "type": "string",
      "format": "email",
      "description": "Doctor's email address (case-insensitive, unique)"
    },
    "password": {
      "type": "string",
      "minLength": 8,
      "description": "Password (will be hashed with Argon2)"
    },
    "fullName": {
      "type": "string",
      "minLength": 1,
      "maxLength": 255,
      "description": "Doctor's full name"
    },
    "phone": {
      "type": "string",
      "description": "Doctor's phone number (optional)"
    }
  }
}
```

**Response**: `201 Created`
```json
{
  "status": "success",
  "message": "Doctor registered successfully",
  "data": {
    "doctorId": "550e8400-e29b-41d4-a716-446655440000",
    "email": "doctor@example.com",
    "fullName": "Dr. John Smith"
  }
}
```

**Error Responses**:
- `400 Bad Request`: Invalid input data
- `409 Conflict`: Email already exists

---

### 2. Login

**Endpoint**: `POST /api/auth/login`

**Description**: Authenticate doctor and receive JWT tokens.

**Request Body**:
```json
{
  "email": "doctor@example.com",
  "password": "SecurePassword123!"
}
```

**Request Schema**:
```json
{
  "type": "object",
  "required": ["email", "password"],
  "properties": {
    "email": {
      "type": "string",
      "format": "email"
    },
    "password": {
      "type": "string"
    }
  }
}
```

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 900,
    "tokenType": "Bearer",
    "sessionId": "660e8400-e29b-41d4-a716-446655440000"
  }
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid credentials
- `403 Forbidden`: Account inactive

---

### 3. Refresh Token

**Endpoint**: `POST /api/auth/refresh`

**Description**: Get new access token using refresh token.

**Request Body**:
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 900,
    "tokenType": "Bearer"
  }
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid or expired refresh token

---

### 4. Logout

**Endpoint**: `POST /api/auth/logout`

**Description**: Logout current session and invalidate tokens.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Logged out successfully"
}
```

---

### 5. Get Current User

**Endpoint**: `GET /api/auth/me`

**Description**: Get current authenticated doctor's profile.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "doctorId": "550e8400-e29b-41d4-a716-446655440000",
    "email": "doctor@example.com",
    "fullName": "Dr. John Smith",
    "phone": "+1234567890",
    "isActive": true,
    "mfaEnabled": false,
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

---

## Patient Management APIs

### 1. Create Patient

**Endpoint**: `POST /api/patients`

**Description**: Create a new patient record with encrypted data.

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "patientData": {
    "name": "Jane Doe",
    "age": 45,
    "gender": "F",
    "dateOfBirth": "1979-05-20",
    "medicalHistory": "Hypertension, Diabetes",
    "diagnosis": "Suspected CHD",
    "notes": "Patient requires further examination"
  }
}
```

**Request Schema**:
```json
{
  "type": "object",
  "required": ["patientData"],
  "properties": {
    "patientData": {
      "type": "object",
      "description": "Patient information (will be encrypted)",
      "properties": {
        "name": {"type": "string"},
        "age": {"type": "integer"},
        "gender": {"type": "string", "enum": ["M", "F", "Other"]},
        "dateOfBirth": {"type": "string", "format": "date"},
        "medicalHistory": {"type": "string"},
        "diagnosis": {"type": "string"},
        "notes": {"type": "string"}
      }
    }
  }
}
```

**Response**: `201 Created`
```json
{
  "status": "success",
  "message": "Patient created successfully",
  "data": {
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "anonymizedCode": "PAT-2024-001234",
    "createdAt": "2024-01-15T10:35:00Z"
  }
}
```

---

### 2. Get Patient

**Endpoint**: `GET /api/patients/{patientId}`

**Description**: Retrieve patient data (decrypted). Requires appropriate access permission.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "anonymizedCode": "PAT-2024-001234",
    "patientData": {
      "name": "Jane Doe",
      "age": 45,
      "gender": "F",
      "dateOfBirth": "1979-05-20",
      "medicalHistory": "Hypertension, Diabetes",
      "diagnosis": "Suspected CHD",
      "notes": "Patient requires further examination"
    },
    "accessRole": "owner",
    "createdAt": "2024-01-15T10:35:00Z",
    "updatedAt": "2024-01-15T10:35:00Z"
  }
}
```

**Error Responses**:
- `403 Forbidden`: Insufficient access permissions
- `404 Not Found`: Patient not found

---

### 3. Update Patient

**Endpoint**: `PUT /api/patients/{patientId}`

**Description**: Update patient data. Requires 'owner' or 'editor' role.

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier

**Request Body**:
```json
{
  "patientData": {
    "name": "Jane Doe",
    "age": 46,
    "gender": "F",
    "dateOfBirth": "1979-05-20",
    "medicalHistory": "Hypertension, Diabetes, Asthma",
    "diagnosis": "Confirmed CHD - ASD",
    "notes": "Updated diagnosis after ML analysis"
  }
}
```

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Patient updated successfully",
  "data": {
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "updatedAt": "2024-01-15T11:00:00Z"
  }
}
```

**Error Responses**:
- `403 Forbidden`: Insufficient permissions (requires 'owner' or 'editor')
- `404 Not Found`: Patient not found

---

### 4. List Patients

**Endpoint**: `GET /api/patients`

**Description**: Get list of patients accessible by the current doctor.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Query Parameters**:
- `page` (integer, optional): Page number (default: 0)
- `size` (integer, optional): Page size (default: 20, max: 100)
- `sort` (string, optional): Sort field (default: "createdAt")
- `order` (string, optional): Sort order - "asc" or "desc" (default: "desc")

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "patients": [
      {
        "patientId": "770e8400-e29b-41d4-a716-446655440000",
        "anonymizedCode": "PAT-2024-001234",
        "accessRole": "owner",
        "createdAt": "2024-01-15T10:35:00Z",
        "updatedAt": "2024-01-15T11:00:00Z"
      }
    ],
    "pagination": {
      "page": 0,
      "size": 20,
      "totalElements": 1,
      "totalPages": 1
    }
  }
}
```

---

### 5. Delete Patient

**Endpoint**: `DELETE /api/patients/{patientId}`

**Description**: Delete patient record. Requires 'owner' role.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Patient deleted successfully"
}
```

**Error Responses**:
- `403 Forbidden`: Insufficient permissions (requires 'owner')
- `404 Not Found`: Patient not found

---

## ECG Scan APIs

### 1. Upload ECG Scan

**Endpoint**: `POST /api/scans/upload`

**Description**: Upload an ECG scan image for a patient.

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Request Body** (multipart/form-data):
- `file` (file, required): ECG scan image (JPEG, PNG)
- `patientId` (UUID, required): Patient identifier
- `metadata` (JSON string, optional): Additional metadata

**Request Example**:
```
POST /api/scans/upload
Content-Type: multipart/form-data

file: [binary image data]
patientId: 770e8400-e29b-41d4-a716-446655440000
metadata: {"notes": "ECG taken during routine checkup", "device": "ECG-Device-123"}
```

**Response**: `201 Created`
```json
{
  "status": "success",
  "message": "Scan uploaded successfully",
  "data": {
    "scanId": "880e8400-e29b-41d4-a716-446655440000",
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "storageUri": "770e8400-e29b-41d4-a716-446655440000/880e8400-e29b-41d4-a716-446655440000/ecg_scan.jpg",
    "mimetype": "image/jpeg",
    "checksum": "sha256:abc123...",
    "uploadedAt": "2024-01-15T11:15:00Z"
  }
}
```

**Error Responses**:
- `400 Bad Request`: Invalid file format or size
- `403 Forbidden`: No access to patient
- `404 Not Found`: Patient not found

---

### 2. Get Scan

**Endpoint**: `GET /api/scans/{scanId}`

**Description**: Get scan metadata.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `scanId` (UUID, required): Scan identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "scanId": "880e8400-e29b-41d4-a716-446655440000",
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "storageUri": "770e8400-e29b-41d4-a716-446655440000/880e8400-e29b-41d4-a716-446655440000/ecg_scan.jpg",
    "mimetype": "image/jpeg",
    "checksum": "sha256:abc123...",
    "metadata": {
      "notes": "ECG taken during routine checkup",
      "device": "ECG-Device-123"
    },
    "uploadedBy": "550e8400-e29b-41d4-a716-446655440000",
    "uploadedAt": "2024-01-15T11:15:00Z"
  }
}
```

---

### 3. Download Scan

**Endpoint**: `GET /api/scans/{scanId}/download`

**Description**: Download scan image file.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `scanId` (UUID, required): Scan identifier

**Response**: `200 OK`
```
Content-Type: image/jpeg
Content-Disposition: attachment; filename="ecg_scan.jpg"

[binary image data]
```

**Error Responses**:
- `403 Forbidden`: No access to patient
- `404 Not Found`: Scan not found

---

### 4. List Patient Scans

**Endpoint**: `GET /api/patients/{patientId}/scans`

**Description**: Get all scans for a patient.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier

**Query Parameters**:
- `page` (integer, optional): Page number (default: 0)
- `size` (integer, optional): Page size (default: 20)

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "scans": [
      {
        "scanId": "880e8400-e29b-41d4-a716-446655440000",
        "mimetype": "image/jpeg",
        "uploadedAt": "2024-01-15T11:15:00Z"
      }
    ],
    "pagination": {
      "page": 0,
      "size": 20,
      "totalElements": 1,
      "totalPages": 1
    }
  }
}
```

---

### 5. Delete Scan

**Endpoint**: `DELETE /api/scans/{scanId}`

**Description**: Delete a scan. Requires appropriate access to patient.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `scanId` (UUID, required): Scan identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Scan deleted successfully"
}
```

---

## ML Prediction APIs

### 1. Predict from Scan

**Endpoint**: `POST /api/ml/predict/{scanId}`

**Description**: Trigger ML prediction for an ECG scan.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `scanId` (UUID, required): Scan identifier

**Request Body** (optional):
```json
{
  "modelVersion": "v1.0",
  "threshold": 0.5
}
```

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Prediction completed",
  "data": {
    "resultId": "990e8400-e29b-41d4-a716-446655440000",
    "scanId": "880e8400-e29b-41d4-a716-446655440000",
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "modelVersion": "v1.0",
    "predictedLabel": "ASD",
    "confidenceScore": 0.9234,
    "classProbabilities": {
      "ASD": 0.9234,
      "VSD": 0.0766
    },
    "threshold": 0.5,
    "explanationUri": "https://minio.example.com/explanations/990e8400...",
    "createdAt": "2024-01-15T11:20:00Z"
  }
}
```

**Error Responses**:
- `403 Forbidden`: No access to scan/patient
- `404 Not Found`: Scan not found
- `500 Internal Server Error`: ML service error

---

### 2. Get Prediction Result

**Endpoint**: `GET /api/ml/results/{resultId}`

**Description**: Get ML prediction result details.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `resultId` (UUID, required): Result identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "resultId": "990e8400-e29b-41d4-a716-446655440000",
    "scanId": "880e8400-e29b-41d4-a716-446655440000",
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "modelVersion": "v1.0",
    "predictedLabel": "ASD",
    "confidenceScore": 0.9234,
    "classProbabilities": {
      "ASD": 0.9234,
      "VSD": 0.0766
    },
    "threshold": 0.5,
    "explanationUri": "https://minio.example.com/explanations/990e8400...",
    "createdBy": "550e8400-e29b-41d4-a716-446655440000",
    "createdAt": "2024-01-15T11:20:00Z"
  }
}
```

---

### 3. List Patient Predictions

**Endpoint**: `GET /api/patients/{patientId}/predictions`

**Description**: Get all ML predictions for a patient.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier

**Query Parameters**:
- `page` (integer, optional): Page number (default: 0)
- `size` (integer, optional): Page size (default: 20)

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "predictions": [
      {
        "resultId": "990e8400-e29b-41d4-a716-446655440000",
        "scanId": "880e8400-e29b-41d4-a716-446655440000",
        "predictedLabel": "ASD",
        "confidenceScore": 0.9234,
        "createdAt": "2024-01-15T11:20:00Z"
      }
    ],
    "pagination": {
      "page": 0,
      "size": 20,
      "totalElements": 1,
      "totalPages": 1
    }
  }
}
```

---

## Access Management APIs

### 1. Share Patient Access

**Endpoint**: `POST /api/patients/{patientId}/share`

**Description**: Grant access to a patient record to another doctor. Requires 'owner' role.

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier

**Request Body**:
```json
{
  "recipientDoctorId": "aa0e8400-e29b-41d4-a716-446655440000",
  "role": "viewer"
}
```

**Request Schema**:
```json
{
  "type": "object",
  "required": ["recipientDoctorId", "role"],
  "properties": {
    "recipientDoctorId": {
      "type": "string",
      "format": "uuid",
      "description": "Doctor ID to grant access to"
    },
    "role": {
      "type": "string",
      "enum": ["owner", "editor", "viewer"],
      "description": "Access role"
    }
  }
}
```

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Access granted successfully",
  "data": {
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "recipientDoctorId": "aa0e8400-e29b-41d4-a716-446655440000",
    "role": "viewer",
    "grantedAt": "2024-01-15T11:30:00Z"
  }
}
```

**Error Responses**:
- `403 Forbidden`: Insufficient permissions (requires 'owner')
- `404 Not Found`: Patient or recipient doctor not found
- `409 Conflict`: Access already granted

---

### 2. Update Access Role

**Endpoint**: `PUT /api/patients/{patientId}/access/{doctorId}`

**Description**: Update access role for a doctor. Requires 'owner' role.

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier
- `doctorId` (UUID, required): Doctor identifier

**Request Body**:
```json
{
  "role": "editor"
}
```

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Access role updated successfully"
}
```

---

### 3. Revoke Access

**Endpoint**: `DELETE /api/patients/{patientId}/access/{doctorId}`

**Description**: Revoke access for a doctor. Requires 'owner' role.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier
- `doctorId` (UUID, required): Doctor identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Access revoked successfully"
}
```

---

### 4. List Patient Access

**Endpoint**: `GET /api/patients/{patientId}/access`

**Description**: Get list of doctors with access to a patient. Requires access to patient.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `patientId` (UUID, required): Patient identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "accessList": [
      {
        "doctorId": "550e8400-e29b-41d4-a716-446655440000",
        "doctorName": "Dr. John Smith",
        "doctorEmail": "doctor@example.com",
        "role": "owner",
        "grantedBy": null,
        "grantedAt": "2024-01-15T10:35:00Z"
      },
      {
        "doctorId": "aa0e8400-e29b-41d4-a716-446655440000",
        "doctorName": "Dr. Jane Doe",
        "doctorEmail": "jane@example.com",
        "role": "viewer",
        "grantedBy": "550e8400-e29b-41d4-a716-446655440000",
        "grantedAt": "2024-01-15T11:30:00Z"
      }
    ]
  }
}
```

---

## Draft Management APIs

### 1. Save Draft

**Endpoint**: `POST /api/drafts`

**Description**: Save a draft form (encrypted).

**Request Headers**:
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "patientId": "770e8400-e29b-41d4-a716-446655440000",
  "formType": "patient_form",
  "formData": {
    "field1": "value1",
    "field2": "value2"
  }
}
```

**Response**: `201 Created`
```json
{
  "status": "success",
  "message": "Draft saved successfully",
  "data": {
    "draftId": "bb0e8400-e29b-41d4-a716-446655440000",
    "updatedAt": "2024-01-15T11:40:00Z"
  }
}
```

---

### 2. Get Draft

**Endpoint**: `GET /api/drafts/{draftId}`

**Description**: Retrieve a draft.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `draftId` (UUID, required): Draft identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "data": {
    "draftId": "bb0e8400-e29b-41d4-a716-446655440000",
    "patientId": "770e8400-e29b-41d4-a716-446655440000",
    "formType": "patient_form",
    "formData": {
      "field1": "value1",
      "field2": "value2"
    },
    "updatedAt": "2024-01-15T11:40:00Z"
  }
}
```

---

### 3. Delete Draft

**Endpoint**: `DELETE /api/drafts/{draftId}`

**Description**: Delete a draft.

**Request Headers**:
```
Authorization: Bearer <access_token>
```

**Path Parameters**:
- `draftId` (UUID, required): Draft identifier

**Response**: `200 OK`
```json
{
  "status": "success",
  "message": "Draft deleted successfully"
}
```

---

## ML Service APIs

### 1. Health Check

**Endpoint**: `GET /`

**Description**: Check if ML service is running.

**Response**: `200 OK`
```json
{
  "message": "Hello! The ML Service is running."
}
```

---

### 2. Predict

**Endpoint**: `POST /predict`

**Description**: Predict CHD classification from ECG scan.

**Request Body**:
```json
{
  "mri_scan_id": 12345
}
```

**Request Schema**:
```json
{
  "type": "object",
  "required": ["mri_scan_id"],
  "properties": {
    "mri_scan_id": {
      "type": "integer",
      "description": "Scan identifier"
    }
  }
}
```

**Response**: `200 OK`
```json
{
  "mri_scan_id": 12345,
  "prediction": "ASD",
  "confidence_score": 0.9234,
  "status": "COMPLETED"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid request
- `500 Internal Server Error`: Model processing error

**Note**: Currently uses test image. Will be updated to download from MinIO.

---

## Error Responses

All error responses follow this format:

```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  },
  "timestamp": "2024-01-15T11:45:00Z",
  "path": "/api/patients/123"
}
```

### Common Error Codes

| HTTP Status | Error Code | Description |
|------------|------------|-------------|
| 400 | `BAD_REQUEST` | Invalid request data |
| 401 | `UNAUTHORIZED` | Missing or invalid authentication |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource conflict (e.g., duplicate email) |
| 422 | `VALIDATION_ERROR` | Validation failed |
| 500 | `INTERNAL_ERROR` | Server error |

---

## Data Models

### UUID Format
All IDs are UUIDs (v4) in the format: `550e8400-e29b-41d4-a716-446655440000`

### Timestamp Format
All timestamps are in ISO 8601 format with UTC timezone: `2024-01-15T11:45:00Z`

### Pagination
```json
{
  "page": 0,
  "size": 20,
  "totalElements": 100,
  "totalPages": 5
}
```

### Access Roles
- `owner`: Full control (create, read, update, delete, share)
- `editor`: Can modify patient data
- `viewer`: Read-only access

### CHD Prediction Labels
- `ASD`: Atrial Septal Defect
- `VSD`: Ventricular Septal Defect
- (Additional labels may be added)

---

## Authentication

### JWT Token Structure

**Access Token** (15 minutes TTL):
```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "doctor@example.com",
  "sessionId": "660e8400-e29b-41d4-a716-446655440000",
  "iat": 1705315200,
  "exp": 1705316100,
  "iss": "ecgcare"
}
```

**Refresh Token** (7 days TTL):
```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "sessionId": "660e8400-e29b-41d4-a716-446655440000",
  "iat": 1705315200,
  "exp": 1705920000,
  "iss": "ecgcare",
  "type": "refresh"
}
```

### Using Tokens

Include the access token in the Authorization header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Rate Limiting

(To be implemented)
- Authentication endpoints: 5 requests per minute
- Other endpoints: 100 requests per minute per user

---

## Versioning

Current API version: `v1` (implicit)

Future versions will be specified in the URL: `/api/v2/...`

---

## Notes

1. **Encryption**: All patient data is encrypted at rest. The API handles encryption/decryption transparently.

2. **File Upload Limits**: 
   - Max file size: 10 MB
   - Allowed formats: JPEG, PNG
   - Allowed MIME types: `image/jpeg`, `image/png`

3. **Session Management**: Sessions timeout after 30 minutes of inactivity.

4. **Audit Logging**: All operations are logged for compliance purposes.

---

## Implementation Status

⚠️ **Note**: These API contracts are based on the database schema and architecture design. The actual controller implementations are pending. This document serves as a specification for implementation.

**Status**:
- ✅ Database schema defined
- ✅ ML Service endpoint implemented
- ⏳ Spring Boot controllers (to be implemented)
- ⏳ Request/Response DTOs (to be implemented)
- ⏳ Service layer (to be implemented)










