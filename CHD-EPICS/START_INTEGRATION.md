# Frontend-Backend Integration Guide

## Step-by-Step Integration Process

### Prerequisites Check

Before starting, ensure you have:
- ✅ Java 21+ installed
- ✅ Python 3.8+ installed
- ✅ Docker Desktop installed and running (for MinIO)
- ✅ Maven installed (or use `mvnw` wrapper)
- ✅ All dependencies installed

---

## Step 1: Start All Backend Services

### 1.1 Start MinIO (Object Storage)

**Option A: Using Docker (Recommended)**
```powershell
cd CHD-EPICS
.\start-minio-docker.ps1
```

**Option B: Manual Docker Command**
```powershell
docker run -d `
  --name minio `
  -p 9000:9000 `
  -p 9001:9001 `
  -v "${PWD}\backend\minio-data:/data" `
  -e "MINIO_ROOT_USER=minio" `
  -e "MINIO_ROOT_PASSWORD=minio12345" `
  minio/minio server /data --console-address ":9001"
```

**Verify MinIO:**
- Web Console: http://localhost:9001
- Login: `minio` / `minio12345`
- Bucket should exist: `ecg-bucket`

### 1.2 Start ML Service

```powershell
cd CHD-EPICS\ml-service
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Verify ML Service:**
- Health Check: http://localhost:8000/health
- Should return: `{"status": "healthy"}`

### 1.3 Start Spring Boot Backend

```powershell
cd CHD-EPICS\backend
.\mvnw.cmd spring-boot:run
```

**Or if using Maven directly:**
```powershell
cd CHD-EPICS\backend
mvn spring-boot:run
```

**Verify Backend:**
- Health Check: http://localhost:8080/api/health
- Should return: `{"status": "UP"}`

**Wait for startup messages:**
- Look for: "Started BackendApplication"
- Database initialized
- No errors in console

---

## Step 2: Start Frontend

### Option A: Using Python HTTP Server (Recommended)

```powershell
cd CHD-EPICS\frontend
python -m http.server 3000
```

### Option B: Using Node.js http-server

```powershell
cd CHD-EPICS\frontend
npx http-server -p 3000
```

### Option C: Using VS Code Live Server

1. Install "Live Server" extension in VS Code
2. Right-click on `main.html`
3. Select "Open with Live Server"

**Frontend URL:** http://localhost:3000

---

## Step 3: Test the Integration

### 3.1 Test Registration

1. Open: http://localhost:3000/signup.html
2. Fill in the form:
   - Full Name: `Dr. John Doe`
   - Email: `doctor@example.com`
   - Phone: `1234567890`
   - Password: `password123` (min 8 characters)
   - Confirm Password: `password123`
3. Click "Sign Up"
4. Should redirect to login page

**Check Backend Logs:**
- Should see: "Doctor registered successfully"
- Check database for new doctor record

### 3.2 Test Login

1. Open: http://localhost:3000/login.html
2. Enter credentials:
   - Email: `doctor@example.com`
   - Password: `password123`
3. Click "Log In"
4. Should redirect to `main.html` (dashboard)

**Check:**
- Session storage should have: `authToken`, `isLoggedIn`, `userEmail`
- Dashboard should show doctor name
- No console errors

### 3.3 Test Patient Creation

1. On dashboard, click "Patient Details" tab
2. Click "+ Add New Patient"
3. Fill in form:
   - Name: `Test Patient`
   - Age: `45`
   - Gender: `Male`
   - Phone: `9876543210`
4. Click "Save Patient"
5. Should see success message
6. Patient should appear in list

**Check Backend Logs:**
- Should see: "Patient created successfully"
- Check database for new patient record

### 3.4 Test Scan Upload & Prediction

1. Click on a patient's "Select for Scan" button
2. Go to "Scan" tab
3. Click "Choose File" and select an image file
4. Click "Analyze Scan"
5. Wait for analysis (may take 10-30 seconds)
6. Should see prediction result with:
   - Predicted Label (Normal, ASD, or VSD)
   - Confidence Score
   - Class Probabilities

**Check Backend Logs:**
- Should see: "Scan uploaded successfully"
- Should see: "ML prediction completed"
- Check MinIO for uploaded scan image
- Check database for prediction result

---

## Step 4: Verify Data Storage

### 4.1 Check Database (H2 Console)

1. Open: http://localhost:8080/h2-console
2. Connection Settings:
   - JDBC URL: `jdbc:h2:file:./data/ecgcare`
   - Username: `sa`
   - Password: (leave empty)
3. Click "Connect"
4. Run queries:
   ```sql
   SELECT * FROM doctor;
   SELECT * FROM patient;
   SELECT * FROM ecg_scan;
   SELECT * FROM ml_result;
   ```

### 4.2 Check MinIO

1. Open: http://localhost:9001
2. Login: `minio` / `minio12345`
3. Browse bucket: `ecg-bucket`
4. Should see uploaded scan images

---

## Troubleshooting

### Issue: Backend not starting

**Check:**
- Java version: `java -version` (should be 21+)
- Port 8080 not in use: `netstat -ano | findstr :8080`
- Database file permissions
- Maven dependencies installed

**Solution:**
```powershell
cd CHD-EPICS\backend
.\mvnw.cmd clean install
.\mvnw.cmd spring-boot:run
```

### Issue: ML Service not responding

**Check:**
- Python version: `python --version`
- Dependencies installed: `pip install -r requirements.txt`
- Port 8000 not in use
- Model files exist in `ml-service/models/chd-classifier/`

**Solution:**
```powershell
cd CHD-EPICS\ml-service
pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Issue: CORS Errors

**Check:**
- Backend CORS configuration in `SecurityConfig.java`
- Frontend API URL is correct: `http://localhost:8080/api`
- Browser console for specific CORS error

**Solution:**
- Backend CORS is already configured to allow all origins
- Check browser console for specific error message

### Issue: 401 Unauthorized

**Check:**
- Token stored in sessionStorage
- Token not expired
- Backend JWT configuration

**Solution:**
- Logout and login again
- Check backend logs for JWT errors
- Verify token in browser DevTools > Application > Session Storage

### Issue: File Upload Fails

**Check:**
- File size < 10MB
- File is an image (JPG, PNG, etc.)
- MinIO is running
- Backend multipart configuration

**Solution:**
- Check `application.yml` for `max-file-size: 10MB`
- Verify MinIO is accessible
- Check backend logs for upload errors

### Issue: Prediction Fails

**Check:**
- ML Service is running
- Model files are loaded correctly
- Backend can reach ML service
- Scan was uploaded successfully

**Solution:**
- Check ML service logs
- Verify ML service URL in backend `application.yml`
- Test ML service directly: http://localhost:8000/health

---

## Quick Test Script

Create a PowerShell script to test all services:

```powershell
# test-integration.ps1
Write-Host "Testing Integration..." -ForegroundColor Cyan

# Test Backend
Write-Host "`n1. Testing Backend..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -UseBasicParsing
    Write-Host "   Backend: OK" -ForegroundColor Green
} catch {
    Write-Host "   Backend: FAILED" -ForegroundColor Red
}

# Test ML Service
Write-Host "`n2. Testing ML Service..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing
    Write-Host "   ML Service: OK" -ForegroundColor Green
} catch {
    Write-Host "   ML Service: FAILED" -ForegroundColor Red
}

# Test MinIO
Write-Host "`n3. Testing MinIO..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:9001" -UseBasicParsing
    Write-Host "   MinIO: OK" -ForegroundColor Green
} catch {
    Write-Host "   MinIO: FAILED" -ForegroundColor Red
}

Write-Host "`nIntegration Test Complete!" -ForegroundColor Cyan
```

---

## Next Steps After Integration

1. **Test all features:**
   - Patient CRUD operations
   - Scan uploads
   - ML predictions
   - Logout/login flow

2. **Monitor logs:**
   - Backend console for errors
   - ML service console for model loading
   - Browser console for frontend errors

3. **Optimize:**
   - Add loading indicators
   - Improve error messages
   - Add form validation
   - Enhance UI/UX

4. **Production considerations:**
   - Use environment variables for API URLs
   - Add proper error handling
   - Implement token refresh
   - Add request retry logic
   - Set up proper logging

---

## Summary

**Services to Start:**
1. ✅ MinIO (port 9000, 9001)
2. ✅ ML Service (port 8000)
3. ✅ Backend (port 8080)
4. ✅ Frontend (port 3000)

**Test Flow:**
1. Register → Login → Dashboard
2. Create Patient → Upload Scan → Get Prediction
3. Verify data in Database and MinIO

**All services should be running before testing!**






