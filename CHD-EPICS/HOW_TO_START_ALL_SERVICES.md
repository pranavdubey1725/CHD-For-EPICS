# 🚀 How to Start All Services - Complete Guide

## Prerequisites Checklist

Before starting, make sure you have:
- ✅ **Java 21+** installed
- ✅ **Python 3.x** installed
- ✅ **Docker Desktop** running (for MinIO)
- ✅ **Maven** (or use mvnw wrapper - included)

---

## 🎯 Quick Start (Recommended - Use PowerShell Scripts)

### Option 1: Start Everything at Once (Easiest!)

There's a script that can start all services. Check if `start-all-services.ps1` exists and run it:

```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS
.\start-all-services.ps1
```

**Note**: This might start services in separate windows. Check if it works first!

---

## 📋 Manual Step-by-Step (4 Separate Windows)

If the script doesn't work, follow these steps manually:

### **Step 1: Start MinIO (Object Storage) - Window 1**

Open **PowerShell** and run:

```powershell
# Check if MinIO container exists
docker ps -a | findstr minio

# If container exists, start it:
docker start minio

# If container doesn't exist, create it:
docker run -d --name minio -p 9000:9000 -p 9001:9001 -e "MINIO_ROOT_USER=minioadmin" -e "MINIO_ROOT_PASSWORD=minioadmin" minio/minio server /data --console-address ":9001"
```

**✅ Verify**: Open http://localhost:9001 in browser (login: minioadmin/minioadmin)

---

### **Step 2: Start ML Service - Window 2**

Open a **NEW PowerShell** window and run:

```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\ml-service
python main.py
```

**✅ Look for**: 
- "Model loaded successfully"
- "Uvicorn running on http://0.0.0.0:8000"
- **Keep this window open!**

**⏱️ Wait time**: 10-30 seconds for model to load

---

### **Step 3: Start Backend (Spring Boot) - Window 3**

Open a **NEW PowerShell** window and run:

```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\backend
.\mvnw.cmd spring-boot:run
```

**✅ Look for**:
- "Started BackendApplication"
- "Tomcat started on port(s): 8080"
- **Keep this window open!**

**⏱️ Wait time**: 30-60 seconds for Spring Boot to start

---

### **Step 4: Start Frontend (Web Server) - Window 4**

Open a **NEW PowerShell** window and run:

```powershell
cd C:\Users\EKTA\OneDrive\Desktop\JavaSpringbootBackend\CHD-EPICS\frontend
python -m http.server 3000
```

**✅ Look for**:
- "Serving HTTP on 0.0.0.0 port 3000"
- **Keep this window open!**

**⏱️ Wait time**: Instant start

---

## 🌐 Service URLs

Once all services are running, you can access:

| Service | URL | Purpose |
|---------|-----|---------|
| **Frontend** | http://localhost:3000/main.html | Your web application |
| **Backend API** | http://localhost:8080/api | REST API |
| **Backend Health** | http://localhost:8080/api/health | Check if backend is running |
| **ML Service** | http://localhost:8000 | ML prediction service |
| **ML Health** | http://localhost:8000/health | Check if ML service is running |
| **MinIO Console** | http://localhost:9001 | Object storage admin (login: minioadmin/minioadmin) |

---

## ✅ Verification Checklist

After starting all services, verify they're running:

### 1. Check MinIO
```
Open: http://localhost:9001
Login: minioadmin / minioadmin
Should see: MinIO dashboard
```

### 2. Check ML Service
```
Open: http://localhost:8000/health
Should see: {"status": "healthy"} or similar
```

### 3. Check Backend
```
Open: http://localhost:8080/api/health
Should see: {"status": "UP"} or similar
```

### 4. Check Frontend
```
Open: http://localhost:3000/main.html
Should see: Login page (or redirect to login)
```

---

## 🎯 Testing Flow

1. **Open Frontend**: http://localhost:3000/main.html
2. **Register/Login**: Create account or login
3. **Add Patient**: Go to "Patient Details" tab → "+ Add New Patient"
4. **Upload Scan**: View patient details → "Upload New ECG Scan"
5. **Analyze**: Click "Analyze" button on uploaded scan
6. **View Report**: Go to "Generate Report" tab → Select patient → Generate

---

## 🛑 How to Stop Services

### Stop each service:
1. **Frontend**: In Window 4, press `Ctrl+C`
2. **Backend**: In Window 3, press `Ctrl+C`
3. **ML Service**: In Window 2, press `Ctrl+C`
4. **MinIO**: 
   ```powershell
   docker stop minio
   ```

---

## 🐛 Troubleshooting

### Port Already in Use

If you get "port already in use" errors:

```powershell
# Check what's using the port
Get-NetTCPConnection -LocalPort 8080 | Select-Object OwningProcess
Get-NetTCPConnection -LocalPort 8000 | Select-Object OwningProcess
Get-NetTCPConnection -LocalPort 3000 | Select-Object OwningProcess

# Kill specific process (replace PID with actual process ID)
Stop-Process -Id <PID> -Force

# Or kill all Python/Java processes (use carefully!)
Get-Process python | Stop-Process -Force
Get-Process java | Stop-Process -Force
```

### Backend Not Starting

**Check**:
- Java 21+ installed? Run: `java -version`
- Maven wrapper exists? Check: `backend\mvnw.cmd` exists
- Port 8080 free? Check error messages

**Common errors**:
- "Port 8080 already in use" → Stop other Java application
- "Cannot find Java" → Install Java 21+
- "Maven not found" → Use `mvnw.cmd` wrapper

### ML Service Not Starting

**Check**:
- Python installed? Run: `python --version`
- Dependencies installed? Run: `pip install -r ml-service/requirements.txt`
- Model files exist? Check: `ml-service/models/chd-classifier/` folder

**Common errors**:
- "Module not found" → Install dependencies: `pip install -r requirements.txt`
- "Model not found" → Check model path in `.env` file
- "Port 8000 already in use" → Stop other Python service

### Frontend Not Loading

**Check**:
- Running from correct directory? Must be: `CHD-EPICS\frontend\`
- Port 3000 free? Check error messages
- Files exist? Check: `main.html`, `api.js`, `main.js` exist

**Common errors**:
- "404 Not Found" → Make sure you're in `frontend\` directory
- "Cannot connect to backend" → Check backend is running on port 8080
- "Port 3000 already in use" → Stop other server on that port

### MinIO Not Starting

**Check**:
- Docker Desktop running? Open Docker Desktop app
- Container exists? Run: `docker ps -a | findstr minio`

**Common errors**:
- "Cannot connect to Docker" → Start Docker Desktop
- "Container not found" → Create container (see Step 1)
- "Port 9000/9001 already in use" → Stop other MinIO instance

---

## 📝 Important Notes

1. **Keep all windows open** while testing - closing a window stops that service
2. **Start order matters**: 
   - MinIO can start anytime
   - ML Service should start before Backend (or Backend will retry connections)
   - Frontend must start last (depends on Backend)
3. **Backend takes longest** to start (30-60 seconds) - be patient!
4. **ML Service loads model** on startup (10-30 seconds) - first request will be slower

---

## 🎉 Success!

Once all services are running, you should have:
- ✅ 4 PowerShell windows open (one for each service)
- ✅ All services accessible via their URLs
- ✅ Frontend ready at http://localhost:3000/main.html

**Now you can test the new frontend with all its features!** 🚀




