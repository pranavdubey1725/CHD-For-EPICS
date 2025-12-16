# API Quick Reference Card

## Authentication

```javascript
// Register
await API.register({ email, password, fullName, phone });

// Login
await API.login({ email, password });

// Logout
await API.logout();

// Get current user
const user = await API.getCurrentUser();
```

## Patients

```javascript
// Create patient
const patient = await API.createPatient({
    name, age, gender, dateOfBirth, 
    medicalHistory, diagnosis, notes
});

// List patients
const result = await API.listPatients({ page: 0, size: 20 });

// Get patient
const patient = await API.getPatient(patientId);

// Update patient
await API.updatePatient(patientId, patientData);

// Delete patient
await API.deletePatient(patientId);
```

## Scans

```javascript
// Upload scan
const scan = await API.uploadScan(file, patientId, metadata);

// Get patient scans
const scans = await API.getPatientScans(patientId);

// Download scan
const blob = await API.downloadScan(scanId);

// Get scan URL for <img> tag
const url = API.getScanDownloadUrl(scanId);

// Delete scan
await API.deleteScan(scanId);
```

## ML Predictions

```javascript
// Trigger prediction
const result = await API.predictFromScan(scanId, { 
    modelVersion: 'v1.0', 
    threshold: 0.5 
});

// Get prediction result
const prediction = await API.getPredictionResult(resultId);

// Get patient predictions
const predictions = await API.getPatientPredictions(patientId);
```

## Utilities

```javascript
// Check if logged in
const token = API.getAccessToken();
if (!token) {
    window.location.href = 'login.html';
}

// Clear authentication
API.clearAuth();
```

## Response Format

### Success Response
```javascript
{
  "status": "success",
  "message": "Optional message",
  "data": { /* response data */ }
}
```

### Error Response
```javascript
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description"
  }
}
```

## Common Patterns

### Load and Display Data
```javascript
async function loadData() {
    try {
        const result = await API.listPatients();
        renderData(result.content);
    } catch (error) {
        showError(error.message);
    }
}
```

### Form Submission
```javascript
async function handleSubmit(e) {
    e.preventDefault();
    
    try {
        showLoading();
        const result = await API.createPatient(formData);
        showSuccess('Created successfully!');
        closeModal();
        await loadData();
    } catch (error) {
        showError(error.message);
    } finally {
        hideLoading();
    }
}
```

### File Upload
```javascript
async function handleFileUpload() {
    const file = fileInput.files[0];
    if (!file) return;
    
    try {
        showLoading('Uploading...');
        const result = await API.uploadScan(file, patientId);
        showSuccess('Uploaded!');
    } catch (error) {
        showError(error.message);
    } finally {
        hideLoading();
    }
}
```

## Error Handling

```javascript
try {
    await API.someFunction();
} catch (error) {
    if (error.message.includes('unauthorized')) {
        window.location.href = 'login.html';
    } else if (error.message.includes('not found')) {
        showError('Resource not found');
    } else {
        showError(error.message);
    }
}
```
