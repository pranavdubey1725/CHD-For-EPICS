# Frontend-Backend Integration Guide

## Overview
This guide explains how to connect your CHD-EPICS frontend with the Spring Boot backend.

## Prerequisites

1. **Backend Running**: Ensure Spring Boot backend is running on `http://localhost:8080`
2. **API Module**: Include `api.js` in your HTML files
3. **CORS Enabled**: Backend should allow requests from your frontend origin

---

## Quick Start

### 1. Include API Module in HTML

Add this to your HTML files (before your page scripts):

```html
<script src="api.js"></script>
```

### 2. Check Authentication Status

```javascript
// Check if user is logged in
const token = API.getAccessToken();
if (!token) {
    window.location.href = 'login.html';
}
```

### 3. Load Current User

```javascript
async function loadUserProfile() {
    try {
        const user = await API.getCurrentUser();
        document.getElementById('docNameDisplay').textContent = user.fullName;
        sessionStorage.setItem('user', JSON.stringify(user));
    } catch (error) {
        console.error('Failed to load user:', error);
        window.location.href = 'login.html';
    }
}
```

---

## Backend Endpoints

### Base URL
```
http://localhost:8080
```

---

## 1. Authentication Endpoints

### Register Doctor
**Endpoint:** `POST /api/auth/register`

**Request:**
```javascript
{
  "email": "doctor@example.com",
  "password": "SecurePassword123!",
  "fullName": "Dr. John Smith",
  "phone": "+1234567890"  // optional
}
```

**Response (201 Created):**
```javascript
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

**Frontend Usage:**
```javascript
// In signup.html
async function handleSignup(e) {
    e.preventDefault();
    
    try {
        const result = await API.register({
            email: document.getElementById('email').value,
            password: document.getElementById('password').value,
            fullName: document.getElementById('name').value,
            phone: document.getElementById('phone-number').value
        });
        
        showSuccess('Account created successfully!');
        setTimeout(() => window.location.href = 'login.html', 1500);
    } catch (error) {
        showError(error.message);
    }
}
```

---

### Login
**Endpoint:** `POST /api/auth/login`

**Request:**
```javascript
{
  "email": "doctor@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200 OK):**
```javascript
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

**Frontend Usage:**
```javascript
// In login.html
async function handleLogin(e) {
    e.preventDefault();
    
    try {
        const result = await API.login({
            email: document.getElementById('email').value,
            password: document.getElementById('password').value
        });
        
        // Tokens are automatically stored by API module
        showSuccess('Login successful!');
        setTimeout(() => window.location.href = 'main.html', 1000);
    } catch (error) {
        showError(error.message);
    }
}
```

---

### Logout
**Endpoint:** `POST /api/auth/logout`

**Headers:** `Authorization: Bearer <token>`

**Frontend Usage:**
```javascript
async function logout() {
    if (confirm('Are you sure you want to logout?')) {
        await API.logout(); // Automatically clears tokens and redirects
    }
}
```

---

### Get Current User
**Endpoint:** `GET /api/auth/me`

**Headers:** `Authorization: Bearer <token>`

**Response:**
```javascript
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

## 2. Patient Management Endpoints

### Create Patient
**Endpoint:** `POST /api/patients`

**Request:**
```javascript
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

**Response (201 Created):**
```javascript
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

**Frontend Usage:**
```javascript
async function addNewPatient() {
    try {
        const result = await API.createPatient({
            name: document.getElementById('newPatientName').value,
            age: parseInt(document.getElementById('newPatientAge').value),
            gender: document.getElementById('newPatientGender').value,
            dateOfBirth: document.getElementById('newPatientDOB').value,
            medicalHistory: document.getElementById('newPatientHistory').value,
            diagnosis: document.getElementById('newPatientDiagnosis').value,
            notes: document.getElementById('newPatientNotes').value
        });
        
        showSuccess('Patient added successfully!');
        closeModal();
        await loadPatients(); // Refresh patient list
    } catch (error) {
        showError(error.message);
    }
}
```

---

### List Patients
**Endpoint:** `GET /api/patients?page=0&size=20&sort=createdAt&order=desc`

**Response:**
```javascript
{
  "status": "success",
  "data": {
    "content": [
      {
        "patientId": "770e8400-e29b-41d4-a716-446655440000",
        "anonymizedCode": "PAT-2024-001234",
        "patientData": {
          "name": "Jane Doe",
          "age": 45,
          "gender": "F",
          // ... other fields
        },
        "accessRole": "owner",
        "createdAt": "2024-01-15T10:35:00Z",
        "updatedAt": "2024-01-15T10:35:00Z"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1,
    "totalPages": 1
  }
}
```

**Frontend Usage:**
```javascript
async function loadPatients() {
    try {
        const result = await API.listPatients({ page: 0, size: 20 });
        renderPatients(result.content);
        updatePagination(result);
    } catch (error) {
        showError('Failed to load patients: ' + error.message);
    }
}

function renderPatients(patients) {
    const container = document.getElementById('patient-list-container');
    container.innerHTML = '';
    
    patients.forEach(patient => {
        const card = document.createElement('div');
        card.className = 'patient-card';
        card.innerHTML = `
            <div class="patient-info">
                <h3>${patient.patientData.name}</h3>
                <small>Age: ${patient.patientData.age} | Gender: ${patient.patientData.gender}</small>
                <small>Code: ${patient.anonymizedCode}</small>
            </div>
            <div class="patient-actions">
                <button onclick="viewPatient('${patient.patientId}')">View</button>
                <button onclick="editPatient('${patient.patientId}')">Edit</button>
            </div>
        `;
        container.appendChild(card);
    });
}
```

---

### Get Patient Details
**Endpoint:** `GET /api/patients/{patientId}`

**Frontend Usage:**
```javascript
async function viewPatient(patientId) {
    try {
        const patient = await API.getPatient(patientId);
        
        // Display patient details
        document.getElementById('detailName').textContent = patient.patientData.name;
        document.getElementById('detailAge').textContent = patient.patientData.age;
        document.getElementById('detailGender').textContent = patient.patientData.gender;
        document.getElementById('detailHistory').textContent = patient.patientData.medicalHistory;
        
        // Show modal
        document.getElementById('viewPatientModal').style.display = 'flex';
    } catch (error) {
        showError('Failed to load patient: ' + error.message);
    }
}
```

---

### Update Patient
**Endpoint:** `PUT /api/patients/{patientId}`

**Frontend Usage:**
```javascript
async function updatePatient(patientId) {
    try {
        const result = await API.updatePatient(patientId, {
            name: document.getElementById('editPatientName').value,
            age: parseInt(document.getElementById('editPatientAge').value),
            gender: document.getElementById('editPatientGender').value,
            medicalHistory: document.getElementById('editPatientHistory').value,
            diagnosis: document.getElementById('editPatientDiagnosis').value,
            notes: document.getElementById('editPatientNotes').value
        });
        
        showSuccess('Patient updated successfully!');
        closeModal();
        await loadPatients();
    } catch (error) {
        showError(error.message);
    }
}
```

---

### Delete Patient
**Endpoint:** `DELETE /api/patients/{patientId}`

**Frontend Usage:**
```javascript
async function deletePatient(patientId) {
    if (!confirm('Are you sure you want to delete this patient?')) {
        return;
    }
    
    try {
        await API.deletePatient(patientId);
        showSuccess('Patient deleted successfully!');
        await loadPatients();
    } catch (error) {
        showError(error.message);
    }
}
```

---

## 3. ECG Scan Endpoints

### Upload Scan
**Endpoint:** `POST /api/scans/upload`

**Content-Type:** `multipart/form-data`

**Frontend Usage:**
```javascript
async function uploadECGScan(patientId) {
    const fileInput = document.getElementById('ecgUpload');
    const file = fileInput.files[0];
    
    if (!file) {
        showError('Please select a file');
        return;
    }
    
    try {
        showLoading('Uploading scan...');
        
        const result = await API.uploadScan(file, patientId, JSON.stringify({
            notes: 'ECG taken during routine checkup',
            device: 'ECG-Device-123'
        }));
        
        showSuccess('Scan uploaded successfully!');
        
        // Optionally trigger ML prediction
        await triggerPrediction(result.scanId);
        
    } catch (error) {
        showError('Upload failed: ' + error.message);
    } finally {
        hideLoading();
    }
}
```

---

### Get Patient Scans
**Endpoint:** `GET /api/patients/{patientId}/scans`

**Frontend Usage:**
```javascript
async function loadPatientScans(patientId) {
    try {
        const result = await API.getPatientScans(patientId);
        renderScans(result.content);
    } catch (error) {
        showError('Failed to load scans: ' + error.message);
    }
}

function renderScans(scans) {
    const container = document.getElementById('scans-container');
    container.innerHTML = '';
    
    scans.forEach(scan => {
        const scanCard = document.createElement('div');
        scanCard.className = 'scan-card';
        scanCard.innerHTML = `
            <img src="${API.getScanDownloadUrl(scan.scanId)}" 
                 alt="ECG Scan" 
                 onclick="viewScanFullscreen('${scan.scanId}')">
            <small>Uploaded: ${new Date(scan.uploadedAt).toLocaleDateString()}</small>
            <button onclick="downloadScanFile('${scan.scanId}')">Download</button>
            <button onclick="predictFromScan('${scan.scanId}')">Analyze</button>
        `;
        container.appendChild(scanCard);
    });
}
```

---

### Download Scan
**Endpoint:** `GET /api/scans/{scanId}/download`

**Frontend Usage:**
```javascript
async function downloadScanFile(scanId) {
    try {
        const blob = await API.downloadScan(scanId);
        
        // Create download link
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `ecg_scan_${scanId}.jpg`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
        
    } catch (error) {
        showError('Download failed: ' + error.message);
    }
}
```

---

## 4. ML Prediction Endpoints

### Trigger Prediction
**Endpoint:** `POST /api/ml/predict/{scanId}`

**Frontend Usage:**
```javascript
async function predictFromScan(scanId) {
    try {
        showLoading('Analyzing ECG scan...');
        
        const result = await API.predictFromScan(scanId, {
            modelVersion: 'v1.0',
            threshold: 0.5
        });
        
        displayPredictionResult(result);
        
    } catch (error) {
        showError('Prediction failed: ' + error.message);
    } finally {
        hideLoading();
    }
}

function displayPredictionResult(result) {
    const modal = document.getElementById('predictionResultModal');
    
    document.getElementById('predictedLabel').textContent = result.predictedLabel;
    document.getElementById('confidenceScore').textContent = 
        (result.confidenceScore * 100).toFixed(2) + '%';
    
    // Display class probabilities
    const probsContainer = document.getElementById('classProbabilities');
    probsContainer.innerHTML = '';
    
    for (const [label, prob] of Object.entries(result.classProbabilities)) {
        const probBar = document.createElement('div');
        probBar.className = 'probability-bar';
        probBar.innerHTML = `
            <span>${label}</span>
            <div class="bar">
                <div class="fill" style="width: ${prob * 100}%"></div>
            </div>
            <span>${(prob * 100).toFixed(2)}%</span>
        `;
        probsContainer.appendChild(probBar);
    }
    
    modal.style.display = 'flex';
}
```

---

### Get Patient Predictions
**Endpoint:** `GET /api/patients/{patientId}/predictions`

**Frontend Usage:**
```javascript
async function loadPatientPredictions(patientId) {
    try {
        const result = await API.getPatientPredictions(patientId);
        renderPredictions(result.content);
    } catch (error) {
        showError('Failed to load predictions: ' + error.message);
    }
}

function renderPredictions(predictions) {
    const container = document.getElementById('predictions-container');
    container.innerHTML = '';
    
    predictions.forEach(pred => {
        const card = document.createElement('div');
        card.className = 'prediction-card';
        card.innerHTML = `
            <h4>${pred.predictedLabel}</h4>
            <p>Confidence: ${(pred.confidenceScore * 100).toFixed(2)}%</p>
            <small>${new Date(pred.createdAt).toLocaleString()}</small>
            <button onclick="viewPredictionDetails('${pred.resultId}')">View Details</button>
        `;
        container.appendChild(card);
    });
}
```

---

## 5. Complete Integration Examples

### Example 1: Complete Patient Workflow

```javascript
// 1. Create patient
const patient = await API.createPatient({
    name: "John Doe",
    age: 45,
    gender: "M",
    dateOfBirth: "1979-01-15",
    medicalHistory: "Hypertension",
    diagnosis: "Suspected CHD",
    notes: "Requires ECG analysis"
});

// 2. Upload ECG scan
const scan = await API.uploadScan(
    fileInput.files[0], 
    patient.patientId,
    JSON.stringify({ notes: "Initial scan" })
);

// 3. Trigger ML prediction
const prediction = await API.predictFromScan(scan.scanId);

// 4. Display results
console.log(`Diagnosis: ${prediction.predictedLabel}`);
console.log(`Confidence: ${prediction.confidenceScore * 100}%`);
```

---

### Example 2: Patient Dashboard Page

```javascript
// main.html - Complete integration
document.addEventListener('DOMContentLoaded', async () => {
    // Check authentication
    if (!API.getAccessToken()) {
        window.location.href = 'login.html';
        return;
    }
    
    try {
        // Load current user
        const user = await API.getCurrentUser();
        document.getElementById('docNameDisplay').textContent = user.fullName;
        
        // Load patients
        await loadPatients();
        
    } catch (error) {
        console.error('Initialization error:', error);
        showError('Failed to load dashboard');
    }
});

async function loadPatients() {
    try {
        const result = await API.listPatients({ page: 0, size: 20 });
        
        document.getElementById('totalPatientsCount').textContent = result.totalElements;
        
        renderPatients(result.content);
        
    } catch (error) {
        showError('Failed to load patients: ' + error.message);
    }
}
```

---

## 6. Error Handling

### Standard Error Response Format

```javascript
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
| 500 | `INTERNAL_ERROR` | Server error |

### Error Handling Example

```javascript
async function handleAPICall() {
    try {
        const result = await API.createPatient(patientData);
        showSuccess('Patient created successfully!');
    } catch (error) {
        // Error is already formatted by API module
        if (error.message.includes('duplicate')) {
            showError('A patient with this information already exists');
        } else if (error.message.includes('unauthorized')) {
            showError('Your session has expired. Please login again.');
            window.location.href = 'login.html';
        } else {
            showError(error.message);
        }
    }
}
```

---

## 7. Security Best Practices

### Token Management

```javascript
// Tokens are automatically managed by api.js
// Access token: 15 minutes TTL
// Refresh token: 7 days TTL

// Automatic token refresh on 401 errors
// Manual refresh if needed:
const refreshed = await API.refreshAccessToken();
if (!refreshed) {
    // Redirect to login
    window.location.href = 'login.html';
}
```

### Secure Image Display

```javascript
// For displaying scan images with authentication
async function displayScanImage(scanId) {
    try {
        const blob = await API.downloadScan(scanId);
        const url = URL.createObjectURL(blob);
        
        const img = document.getElementById('scanImage');
        img.src = url;
        
        // Clean up when done
        img.onload = () => URL.revokeObjectURL(url);
    } catch (error) {
        showError('Failed to load image');
    }
}
```

---

## 8. Testing the Integration

### Step 1: Start Backend

```bash
cd JavaSpringbootBackend/CHD-EPICS/backend
./mvnw spring-boot:run
```

### Step 2: Verify Backend is Running

Open browser: `http://localhost:8080/api/health`

Expected response:
```javascript
{
  "status": "UP",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

### Step 3: Test Frontend

1. Open `login.html` in browser
2. Register a new doctor account
3. Login with credentials
4. Add a patient
5. Upload ECG scan
6. Trigger ML prediction

---

## 9. Troubleshooting

### CORS Issues

If you see CORS errors in browser console, ensure backend has CORS configured:

```java
// SecurityConfig.java should have:
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.addAllowedOrigin("*");
    configuration.addAllowedMethod("*");
    configuration.addAllowedHeader("*");
    return source;
}
```

### Token Expiration

If you get frequent 401 errors:
- Check token expiration time in backend config
- Ensure refresh token logic is working
- Clear sessionStorage and login again

### File Upload Issues

If scan upload fails:
- Check file size (max 10MB)
- Verify file format (JPEG/PNG only)
- Check backend logs for detailed error

---

## 10. Next Steps

1. **Update HTML files** to use `api.js` module
2. **Remove mock data** from frontend
3. **Test all workflows** end-to-end
4. **Add loading indicators** for async operations
5. **Implement proper error messages**
6. **Add form validation**
7. **Test with real ECG images**

---

## Support

For issues or questions:
- Check backend logs: `backend/app.log`
- Check browser console for frontend errors
- Review API contracts: `API_CONTRACTS.md`
- Review architecture: `ARCHITECTURE_AND_LLD.md`