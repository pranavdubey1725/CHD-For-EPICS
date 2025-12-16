# Frontend Integration Guide

## Current Frontend Structure

```
CHD-EPICS/
├── frontend/
│   ├── login.html          # Login page
│   ├── signup.html        # Registration page
│   ├── main.html          # Main dashboard
│   ├── main.js            # Main JavaScript logic
│   ├── dashboard.js       # Dashboard functionality
│   └── styles.css         # Styling
```

## Where to Add Your New Frontend Files

### Option 1: Replace Existing Files (Recommended if you have a complete frontend)

**If your new frontend is a complete replacement:**
1. **Backup existing files** (optional):
   ```powershell
   cd CHD-EPICS\frontend
   mkdir backup
   copy *.html backup\
   copy *.js backup\
   copy *.css backup\
   ```

2. **Replace files** in `CHD-EPICS/frontend/`:
   - Copy your new HTML files to `CHD-EPICS/frontend/`
   - Copy your new JavaScript files to `CHD-EPICS/frontend/`
   - Copy your new CSS files to `CHD-EPICS/frontend/`
   - Copy any assets (images, fonts, etc.) to `CHD-EPICS/frontend/assets/` (create if needed)

### Option 2: Add to Existing Structure (If you have additional pages/components)

**If you have new pages/components to add:**
1. **HTML pages**: Add to `CHD-EPICS/frontend/`
   - Example: `patients.html`, `scans.html`, `predictions.html`

2. **JavaScript modules**: Add to `CHD-EPICS/frontend/js/` (create directory)
   - Example: `api.js`, `patients.js`, `scans.js`, `predictions.js`

3. **CSS files**: Add to `CHD-EPICS/frontend/css/` (create directory) or keep in root
   - Example: `components.css`, `utilities.css`

4. **Assets**: Add to `CHD-EPICS/frontend/assets/` (create directory)
   - Images: `assets/images/`
   - Fonts: `assets/fonts/`
   - Icons: `assets/icons/`

### Recommended Structure

```
CHD-EPICS/
├── frontend/
│   ├── index.html              # Main entry point (or main.html)
│   ├── login.html              # Login page
│   ├── signup.html             # Registration page
│   ├── styles.css              # Main stylesheet
│   ├── js/
│   │   ├── api.js              # API communication functions
│   │   ├── auth.js             # Authentication logic
│   │   ├── patients.js         # Patient management
│   │   ├── scans.js            # Scan upload/management
│   │   ├── predictions.js      # ML prediction handling
│   │   └── utils.js            # Utility functions
│   ├── css/
│   │   ├── components.css      # Component styles
│   │   └── utilities.css       # Utility classes
│   └── assets/
│       ├── images/
│       ├── fonts/
│       └── icons/
```

## Backend API Configuration

### Current API Base URL

The frontend currently uses:
```javascript
const API_BASE_URL = 'http://localhost:8080';
```

### Backend API Endpoints

Your frontend needs to connect to these endpoints:

#### Authentication
- `POST /api/auth/register` - Register new doctor
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh token
- `GET /api/auth/me` - Get current user

#### Patients
- `GET /api/patients` - List patients (paginated)
- `POST /api/patients` - Create patient
- `GET /api/patients/{id}` - Get patient details
- `PUT /api/patients/{id}` - Update patient
- `DELETE /api/patients/{id}` - Delete patient

#### Scans
- `POST /api/scans/upload?patientId={id}` - Upload scan (multipart/form-data)
- `GET /api/scans/{scanId}` - Get scan details
- `GET /api/scans/{scanId}/download` - Download scan image
- `GET /api/patients/{patientId}/scans` - List patient scans

#### ML Predictions
- `POST /api/ml/predict/{scanId}` - Request prediction
- `GET /api/ml/results/{resultId}` - Get prediction result
- `GET /api/patients/{patientId}/predictions` - List patient predictions

## Connecting Frontend to Backend

### 1. API Configuration File

Create `CHD-EPICS/frontend/js/api.js`:

```javascript
// API Configuration
const API_BASE_URL = 'http://localhost:8080/api';

// Get auth token from sessionStorage
function getAuthToken() {
    return sessionStorage.getItem('authToken') || sessionStorage.getItem('accessToken');
}

// Get auth headers
function getAuthHeaders() {
    const token = getAuthToken();
    return {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : ''
    };
}

// API Request wrapper
async function apiRequest(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const headers = {
        ...getAuthHeaders(),
        ...options.headers
    };

    try {
        const response = await fetch(url, {
            ...options,
            headers
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || `HTTP ${response.status}`);
        }

        return data;
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

// Authentication APIs
export const authAPI = {
    login: (email, password) => apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password })
    }),
    
    register: (email, password, fullName, phone) => apiRequest('/auth/register', {
        method: 'POST',
        body: JSON.stringify({ email, password, fullName, phone })
    }),
    
    getMe: () => apiRequest('/auth/me', { method: 'GET' })
};

// Patient APIs
export const patientAPI = {
    list: (page = 0, size = 10) => apiRequest(`/patients?page=${page}&size=${size}`, { method: 'GET' }),
    
    get: (patientId) => apiRequest(`/patients/${patientId}`, { method: 'GET' }),
    
    create: (patientData) => apiRequest('/patients', {
        method: 'POST',
        body: JSON.stringify({ patientData })
    }),
    
    update: (patientId, patientData) => apiRequest(`/patients/${patientId}`, {
        method: 'PUT',
        body: JSON.stringify({ patientData })
    }),
    
    delete: (patientId) => apiRequest(`/patients/${patientId}`, { method: 'DELETE' })
};

// Scan APIs
export const scanAPI = {
    upload: (patientId, file) => {
        const formData = new FormData();
        formData.append('file', file);
        
        const token = getAuthToken();
        return fetch(`${API_BASE_URL}/scans/upload?patientId=${patientId}`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            },
            body: formData
        }).then(res => res.json());
    },
    
    get: (scanId) => apiRequest(`/scans/${scanId}`, { method: 'GET' }),
    
    download: (scanId) => {
        const token = getAuthToken();
        return `${API_BASE_URL}/scans/${scanId}/download?token=${token}`;
    },
    
    listByPatient: (patientId, page = 0, size = 10) => 
        apiRequest(`/patients/${patientId}/scans?page=${page}&size=${size}`, { method: 'GET' })
};

// ML Prediction APIs
export const predictionAPI = {
    predict: (scanId, modelVersion = 'v1.0', threshold = 0.5) => 
        apiRequest(`/ml/predict/${scanId}`, {
            method: 'POST',
            body: JSON.stringify({ modelVersion, threshold })
        }),
    
    getResult: (resultId) => apiRequest(`/ml/results/${resultId}`, { method: 'GET' }),
    
    listByPatient: (patientId, page = 0, size = 10) => 
        apiRequest(`/patients/${patientId}/predictions?page=${page}&size=${size}`, { method: 'GET' })
};
```

### 2. Update Your HTML Files

Make sure your HTML files:
1. **Include the API script**:
   ```html
   <script type="module" src="js/api.js"></script>
   ```

2. **Use the API functions**:
   ```javascript
   import { patientAPI, scanAPI, predictionAPI } from './js/api.js';
   
   // Example: Get patients
   const response = await patientAPI.list();
   const patients = response.data.content;
   ```

### 3. Authentication Flow

**Login:**
```javascript
import { authAPI } from './js/api.js';

const response = await authAPI.login(email, password);
if (response.success) {
    sessionStorage.setItem('accessToken', response.data.accessToken);
    sessionStorage.setItem('refreshToken', response.data.refreshToken);
    sessionStorage.setItem('user', JSON.stringify(response.data.user));
    // Redirect to dashboard
}
```

**Making Authenticated Requests:**
The `apiRequest` function automatically includes the Bearer token from sessionStorage.

### 4. Example: Upload Scan and Get Prediction

```javascript
import { scanAPI, predictionAPI } from './js/api.js';

// 1. Upload scan
const fileInput = document.getElementById('scanFile');
const file = fileInput.files[0];
const patientId = 'patient-uuid';

const uploadResponse = await scanAPI.upload(patientId, file);
const scanId = uploadResponse.data.scanId;

// 2. Request prediction
const predictResponse = await predictionAPI.predict(scanId);
const result = predictResponse.data;

console.log('Prediction:', result.predictedLabel);
console.log('Confidence:', result.confidenceScore);
console.log('Probabilities:', result.classProbabilities);
```

## CORS Configuration

The backend should already have CORS configured. If you encounter CORS errors, check `SecurityConfig.java` in the backend.

## Testing Frontend Connection

1. **Start all services:**
   - Backend: `http://localhost:8080`
   - ML Service: `http://localhost:8000`
   - MinIO: `http://localhost:9000`

2. **Open frontend:**
   - Open `CHD-EPICS/frontend/login.html` in browser
   - Or serve via a local server (recommended)

3. **Test connection:**
   - Try logging in
   - Check browser console for errors
   - Check Network tab for API calls

## Serving Frontend

### Option 1: Direct File Access
- Simply open HTML files in browser
- Works for basic testing
- May have CORS issues with some browsers

### Option 2: Local Web Server (Recommended)

**Using Python:**
```powershell
cd CHD-EPICS\frontend
python -m http.server 3000
```
Then open: `http://localhost:3000`

**Using Node.js (if you have it):**
```powershell
cd CHD-EPICS\frontend
npx http-server -p 3000
```

**Using VS Code Live Server:**
- Install "Live Server" extension
- Right-click on `index.html` or `main.html`
- Select "Open with Live Server"

## Next Steps

1. **Add your new frontend files** to `CHD-EPICS/frontend/`
2. **Update API calls** to use the backend endpoints
3. **Test authentication** flow
4. **Test patient management**
5. **Test scan upload**
6. **Test ML prediction** integration

## Common Issues

### CORS Errors
- Ensure backend CORS is configured
- Check `SecurityConfig.java` allows your frontend origin

### 401 Unauthorized
- Check token is stored in sessionStorage
- Verify token is included in Authorization header
- Token may have expired - implement refresh logic

### 404 Not Found
- Verify API endpoint URLs match backend routes
- Check backend is running on port 8080

### File Upload Issues
- Use FormData for file uploads
- Don't set Content-Type header (browser sets it with boundary)
- Check file size limits (10MB default)

## Integration Checklist

- [ ] Frontend files added to `CHD-EPICS/frontend/`
- [ ] API base URL configured (`http://localhost:8080/api`)
- [ ] Authentication flow working
- [ ] Token stored in sessionStorage
- [ ] API requests include Authorization header
- [ ] Patient CRUD operations working
- [ ] Scan upload working
- [ ] ML prediction integration working
- [ ] Error handling implemented
- [ ] Loading states implemented






