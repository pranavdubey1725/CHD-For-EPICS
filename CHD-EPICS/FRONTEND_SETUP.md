# Frontend Setup and Integration

## Quick Start

### Where to Add Your New Frontend Files

**Location:** `CHD-EPICS/frontend/`

```
CHD-EPICS/
└── frontend/
    ├── index.html          # Main entry point (or main.html)
    ├── login.html          # Login page
    ├── signup.html         # Registration page
    ├── styles.css          # Main stylesheet
    ├── js/
    │   ├── api.js          # ✅ API functions (already created)
    │   ├── auth.js         # Authentication logic
    │   ├── patients.js     # Patient management
    │   └── utils.js        # Utility functions
    └── assets/             # Images, fonts, icons
```

### Steps to Add Your New Frontend

1. **Copy your files to `CHD-EPICS/frontend/`**
   ```powershell
   # Copy all your HTML, CSS, JS files here
   # Example:
   copy "C:\path\to\your\frontend\*" "CHD-EPICS\frontend\"
   ```

2. **Update API Base URL** (if needed)
   - The API is configured at: `http://localhost:8080/api`
   - Check `js/api.js` or your main JS file

3. **Use the API functions**
   - Import or include `js/api.js` in your HTML
   - Use `authAPI`, `patientAPI`, `scanAPI`, `predictionAPI`

## Backend Connection

### API Base URL
```
http://localhost:8080/api
```

### Authentication
- Login: `POST /api/auth/login`
- Register: `POST /api/auth/register`
- Get Current User: `GET /api/auth/me`

### Key Endpoints

**Patients:**
- List: `GET /api/patients?page=0&size=10`
- Create: `POST /api/patients`
- Get: `GET /api/patients/{id}`
- Update: `PUT /api/patients/{id}`

**Scans:**
- Upload: `POST /api/scans/upload?patientId={id}` (multipart/form-data)
- Get: `GET /api/scans/{scanId}`
- Download: `GET /api/scans/{scanId}/download`

**ML Predictions:**
- Predict: `POST /api/ml/predict/{scanId}`
- Get Result: `GET /api/ml/results/{resultId}`

## Example Usage

### In Your HTML
```html
<script src="js/api.js"></script>
<script>
    // Use the APIs
    async function loadPatients() {
        try {
            const response = await patientAPI.list();
            const patients = response.data.content;
            console.log('Patients:', patients);
        } catch (error) {
            console.error('Error:', error);
        }
    }
</script>
```

### Upload Scan and Get Prediction
```javascript
// 1. Upload scan
const file = document.getElementById('fileInput').files[0];
const uploadResponse = await scanAPI.upload(patientId, file);
const scanId = uploadResponse.data.scanId;

// 2. Request prediction
const predictResponse = await predictionAPI.predict(scanId);
const result = predictResponse.data;

// 3. Display results
console.log('Prediction:', result.predictedLabel);
console.log('Confidence:', result.confidenceScore);
console.log('Probabilities:', result.classProbabilities);
```

## Testing

1. **Start services:**
   - Backend: Running on port 8080
   - ML Service: Running on port 8000
   - MinIO: Running on port 9000

2. **Serve frontend:**
   ```powershell
   cd CHD-EPICS\frontend
   python -m http.server 3000
   ```

3. **Open browser:**
   ```
   http://localhost:3000/login.html
   ```

## CORS Configuration

✅ Backend CORS is already configured to allow all origins (for development).

See `SecurityConfig.java` - it allows:
- All origins: `*`
- All methods: GET, POST, PUT, DELETE, OPTIONS
- All headers

## Next Steps

1. ✅ Add your frontend files to `CHD-EPICS/frontend/`
2. ✅ Include `js/api.js` in your HTML
3. ✅ Update your code to use the API functions
4. ✅ Test the integration

See `FRONTEND_INTEGRATION_GUIDE.md` for detailed documentation.






