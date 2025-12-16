# End-to-End Integration Test Guide

## 🚀 Quick Start - Test Everything

### Step-by-Step Process

---

## Step 1: Start Backend Services (Required First)

### 1.1 Start MinIO (Object Storage)

**Open Terminal 1:**
```powershell
cd CHD-EPICS
.\start-minio-docker.ps1
```

**Or manually:**
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

**Wait 5 seconds, then verify:**
- Open: http://localhost:9001
- Login: `minio` / `minio12345`
- Should see `ecg-bucket` exists

---

### 1.2 Start ML Service

**Open Terminal 2:**
```powershell
cd CHD-EPICS\ml-service
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Wait for startup messages:**
- Look for: "Application startup complete"
- Look for: "Model loaded successfully"
- Should see: "Uvicorn running on http://0.0.0.0:8000"

**Verify ML Service:**
- Open browser: http://localhost:8000/health
- Should return: `{"status": "healthy"}`

---

### 1.3 Start Spring Boot Backend

**Open Terminal 3:**
```powershell
cd CHD-EPICS\backend
.\mvnw.cmd spring-boot:run
```

**Wait for startup (30-60 seconds):**
- Look for: "Started BackendApplication"
- Look for: "H2 Console available at /h2-console"
- Should see: "Tomcat started on port(s): 8080"

**Verify Backend:**
- Open browser: http://localhost:8080/api/health
- Should return: `{"status": "UP"}`

---

## Step 2: Verify All Services

**Open Terminal 4 (or use existing):**
```powershell
cd CHD-EPICS
.\test-integration.ps1
```

**Expected Output:**
```
✅ Backend is running
✅ ML Service is running
✅ MinIO is running
```

**If any service fails, check the corresponding terminal for errors.**

---

## Step 3: Start Frontend

**Open Terminal 5:**
```powershell
cd CHD-EPICS\frontend
python -m http.server 3000
```

**You should see:**
```
Serving HTTP on 0.0.0.0 port 3000
```

**Keep this terminal open!**

---

## Step 4: Test End-to-End Integration

### Test 1: Registration

1. **Open browser:** http://localhost:3000/signup.html

2. **Fill the form:**
   - Full Name: `Dr. Test User`
   - Email: `test@example.com`
   - Phone: `1234567890`
   - Password: `test12345` (min 8 chars)
   - Confirm Password: `test12345`

3. **Click "Sign Up"**

4. **Expected Result:**
   - ✅ Success message: "Account created! Redirecting to login..."
   - ✅ Redirects to login page
   - ✅ Check Terminal 3 (Backend) - should see registration log

5. **Verify in Database:**
   - Open: http://localhost:8080/h2-console
   - JDBC URL: `jdbc:h2:file:./data/ecgcare`
   - Username: `sa`, Password: (empty)
   - Run: `SELECT * FROM doctor;`
   - Should see your new doctor record

---

### Test 2: Login

1. **On login page:** http://localhost:3000/login.html

2. **Enter credentials:**
   - Email: `test@example.com`
   - Password: `test12345`

3. **Click "Log In"**

4. **Expected Result:**
   - ✅ Success message: "Login successful! Redirecting..."
   - ✅ Redirects to dashboard (main.html)
   - ✅ Dashboard shows doctor name
   - ✅ Check browser DevTools > Application > Session Storage:
     - `authToken` should exist
     - `isLoggedIn` = "true"
     - `userEmail` = "test@example.com"

5. **Verify:**
   - Dashboard loads without errors
   - Total Patients count shows (may be 0)
   - Navigation tabs work

---

### Test 3: Create Patient

1. **On dashboard, click "Patient Details" tab**

2. **Click "+ Add New Patient" button**

3. **Fill the form:**
   - Name: `John Doe`
   - Age: `45`
   - Gender: `Male`
   - Phone: `9876543210`

4. **Click "Save Patient"**

5. **Expected Result:**
   - ✅ Success alert: "Patient created successfully!"
   - ✅ Modal closes
   - ✅ Patient appears in list
   - ✅ Total Patients count increases
   - ✅ Check Terminal 3 (Backend) - should see patient creation log

6. **Verify in Database:**
   - H2 Console: `SELECT * FROM patient;`
   - Should see new patient with anonymized code
   - Check: `SELECT * FROM patient_access;` - should see access record

---

### Test 4: Upload Scan & Get Prediction

1. **In Patient Details tab, click "Select for Scan" on a patient**

2. **Expected:**
   - ✅ Alert: "Patient selected. You can now upload a scan for this patient."
   - ✅ Automatically switches to "Scan" tab

3. **In Scan tab:**
   - Click "Choose File" or file input
   - Select an image file (JPG, PNG, etc.)
   - File should be selected

4. **Click "Analyze Scan" button**

5. **Expected Result:**
   - ✅ Status message: "Analyzing scan... Please wait."
   - ✅ Wait 10-30 seconds (ML processing)
   - ✅ Alert popup with prediction result showing:
     - Predicted Label: (Normal, ASD, or VSD)
     - Confidence: XX.XX%
     - Class Probabilities:
       - Normal: XX.XX%
       - ASD: XX.XX%
       - VSD: XX.XX%
   - ✅ Status message changes to: "Analysis complete!"

6. **Verify in Database:**
   - H2 Console: `SELECT * FROM ecg_scan;` - should see scan record
   - H2 Console: `SELECT * FROM ml_result;` - should see prediction result
   - Check the prediction details match what was shown

7. **Verify in MinIO:**
   - Open: http://localhost:9001
   - Login: minio/minio12345
   - Browse: `ecg-bucket`
   - Should see uploaded scan image in patient folder

8. **Check Terminal Logs:**
   - Terminal 2 (ML Service): Should show prediction request and result
   - Terminal 3 (Backend): Should show scan upload and ML call logs

---

### Test 5: Verify Data Persistence

1. **Refresh the browser page (F5)**

2. **Expected:**
   - ✅ Still logged in (session persists)
   - ✅ Patient list still shows your patient
   - ✅ Dashboard loads correctly

3. **Logout:**
   - Click user icon → "Logout"
   - Confirm logout
   - ✅ Redirects to thankyou.html

4. **Login again:**
   - Go to login page
   - Login with same credentials
   - ✅ Patient data still exists
   - ✅ All data persisted correctly

---

## Step 5: Complete Verification Checklist

### ✅ Service Status
- [ ] MinIO running on port 9000/9001
- [ ] ML Service running on port 8000
- [ ] Backend running on port 8080
- [ ] Frontend running on port 3000

### ✅ Functionality Tests
- [ ] Registration works
- [ ] Login works
- [ ] Dashboard loads
- [ ] Patient creation works
- [ ] Scan upload works
- [ ] ML prediction works
- [ ] Results displayed correctly
- [ ] Logout works

### ✅ Data Verification
- [ ] Doctor record in database
- [ ] Patient record in database
- [ ] Scan record in database
- [ ] Prediction result in database
- [ ] Scan image in MinIO
- [ ] Data persists after refresh

### ✅ Integration Points
- [ ] Frontend → Backend API (working)
- [ ] Backend → ML Service (working)
- [ ] Backend → MinIO (working)
- [ ] Backend → Database (working)

---

## Troubleshooting

### If Registration Fails:
- Check Terminal 3 (Backend) for errors
- Verify backend is fully started
- Check database connection
- Verify email format is valid

### If Login Fails:
- Check credentials match registration
- Check browser console for errors
- Verify JWT token generation
- Check backend logs

### If Patient Creation Fails:
- Check browser console
- Verify authentication token
- Check backend logs
- Verify database is accessible

### If Scan Upload Fails:
- Check file size (< 10MB)
- Check file type (image file)
- Verify MinIO is running
- Check backend logs for upload errors
- Verify patient is selected

### If Prediction Fails:
- Check ML Service is running
- Verify model is loaded (check ML Service terminal)
- Check backend can reach ML Service
- Verify scan was uploaded successfully
- Check ML Service logs
- Wait longer (prediction can take 10-30 seconds)

### If Services Won't Start:
- **MinIO**: Check Docker Desktop is running
- **ML Service**: Check Python and dependencies installed
- **Backend**: Check Java 21+ installed, port 8080 available
- **Frontend**: Check Python installed, port 3000 available

---

## Expected Test Results

### Successful Test Output:

**Terminal 1 (MinIO):**
```
MinIO server running
```

**Terminal 2 (ML Service):**
```
INFO:     Application startup complete.
INFO:     Model loaded: ConvNeXt
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**Terminal 3 (Backend):**
```
Started BackendApplication in X.XXX seconds
H2 Console available at /h2-console
Tomcat started on port(s): 8080
```

**Terminal 5 (Frontend):**
```
Serving HTTP on 0.0.0.0 port 3000
```

**Browser:**
- All pages load correctly
- No console errors
- All features work
- Data persists

---

## Quick Test Commands

### Test All Services at Once:
```powershell
cd CHD-EPICS
.\test-integration.ps1
```

### Start All Services at Once:
```powershell
cd CHD-EPICS
.\start-all-services.ps1
```

### Check Service URLs:
- Backend Health: http://localhost:8080/api/health
- ML Service Health: http://localhost:8000/health
- MinIO Console: http://localhost:9001
- Frontend: http://localhost:3000/login.html
- H2 Database: http://localhost:8080/h2-console

---

## Success Criteria

✅ **Integration is successful if:**
1. All services start without errors
2. Registration creates doctor in database
3. Login generates JWT token
4. Patient creation stores encrypted data
5. Scan upload stores file in MinIO
6. ML prediction returns valid result
7. Results are saved to database
8. All data persists after refresh

**If all above work → Integration is COMPLETE! ✅**






